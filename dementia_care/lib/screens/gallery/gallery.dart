import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dementia_care/widgets/galleryview.dart';
import 'package:dementia_care/widgets/cameracapture.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care/models/gallery.dart';
import 'package:uuid/uuid.dart';
import 'package:dementia_care/screens/gallery/upload.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dementia_care/models/memory.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _searchController = TextEditingController();
  final Uuid uuid = Uuid();
  List<Gallery> _galleryImages = [];
  Map<String, List<Gallery>> _groupedImages = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGalleryImages();
  }

  Future<void> _loadGalleryImages() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await Supabase.instance.client
          .from('gallery')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      setState(() {
        _galleryImages = (response as List)
            .map((json) => Gallery.fromJson(json))
            .toList();
        _groupImagesByDate();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading gallery: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _groupImagesByDate() {
    _groupedImages.clear();
    for (final image in _galleryImages) {
      final dateKey = _formatDateKey(image.createdAt);

      if (!_groupedImages.containsKey(dateKey)) {
        _groupedImages[dateKey] = [];
      }
      _groupedImages[dateKey]!.add(image);
    }
  }

  String _formatDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final imageDate = DateTime(date.year, date.month, date.day);

    if (imageDate == today) {
      return 'Today';
    } else if (imageDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(imageDate).inDays < 7) {
      return _formatWeekday(date);
    } else {
      // Group by month for older images
      return _formatMonthYear(date);
    }
  }

  String _formatWeekday(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }

  String _formatMonthYear(DateTime date) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'];
    return '${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickImages() async {
    final List<XFile>? picked = await _picker.pickMultiImage();
    if (picked == null || picked.isEmpty) return;

    final result = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        builder: (_) => UploadPreviewPage(initialImages: picked),
      ),
    );

    if (result == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _loadGalleryImages();
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Future<void> _openCamera() async {
    final List<dynamic>? result = await Navigator.of(context).push<List<dynamic>?>(
      MaterialPageRoute(
        builder: (_) => const CameraCapturePage(),
      ),
    );

    if (result == null || result.isEmpty) return;

    final images = result.cast<XFile>();

    final uploaded = await Navigator.of(context).push<bool?>(
      MaterialPageRoute(
        builder: (_) => UploadPreviewPage(initialImages: images),
      ),
    );

    if (uploaded == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _loadGalleryImages();
        _showResultDialog(
          success: true,
          title: 'Upload Successful',
          message: 'Your photo(s) were uploaded.',
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _showResultDialog({
    required bool success,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success ? Colors.green : Colors.red,
                  size: 50,
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1B5E7E),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchSection(),
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1B5E7E),
                ),
              )
                  : _buildGalleryContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search, color: Colors.grey[600]),
                    onPressed: () async {
                      final query = _searchController.text.trim().toLowerCase();
                      if (query.isEmpty) {
                        setState(() {
                          _isLoading = true;
                        });
                        await _loadGalleryImages();
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                        return;
                      }

                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        final userId = Supabase.instance.client.auth.currentUser?.id;
                        if (userId == null) {
                          if (mounted) {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                          return;
                        }

                        final response = await Supabase.instance.client
                          .from('gallery')
                          .select()
                          .eq('user_id', userId);

                        final List<Gallery> allImages = (response as List)
                          .map((json) => Gallery.fromJson(json))
                          .toList();

                        final filtered = allImages.where((img) {
                          final desc = img.description.toLowerCase();
                          final dateStr = _formatMonthYear(img.createdAt).toLowerCase();
                          final weekdayStr = _formatWeekday(img.createdAt).toLowerCase();
                          return desc.contains(query) ||
                            dateStr.contains(query) ||
                            weekdayStr.contains(query);
                        }).toList();

                        if (mounted) {
                          setState(() {
                            _galleryImages = filtered;
                            _groupImagesByDate();
                          });
                        }
                      } catch (e) {
                        print('Search error: $e');
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E7E),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1B5E7E).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.add, color: Colors.white),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              onSelected: (value) {
                if (value == 'gallery') {
                  _pickImages();
                } else if (value == 'camera') {
                  _openCamera();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'gallery',
                  child: Row(
                    children: [
                      Icon(Icons.photo_library, color: Colors.grey[700]),
                      const SizedBox(width: 12),
                      const Text('Choose from Gallery'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'camera',
                  child: Row(
                    children: [
                      Icon(Icons.camera_alt, color: Colors.grey[700]),
                      const SizedBox(width: 12),
                      const Text('Take Photo'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryContent() {
    if (_galleryImages.isEmpty) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_galleryImages.isNotEmpty) _buildMemoriesSection(),
          const SizedBox(height: 12),
          ..._groupedImages.entries.map((entry) => _buildDateGroup(entry.key, entry.value)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Updated memories section: uses MemoryGroup and carousel_slider
  Widget _buildMemoriesSection() {
    final memoryGroups = _groupedImages.entries.map((entry) {
      final imageUrls = entry.value.map((g) => g.imageUrl ?? '').where((s) => s.isNotEmpty).toList();
      return MemoryGroup(title: entry.key, imageUrls: imageUrls);
    }).where((mg) => mg.imageUrls.isNotEmpty).toList();

    // Fallback to recentImages if we don't have grouped memories
    final fallbackGroups = memoryGroups.isEmpty
        ? [
            MemoryGroup(
              title: 'Recent',
              imageUrls: _galleryImages.take(5).map((g) => g.imageUrl ?? '').where((s) => s.isNotEmpty).toList(),
            )
          ]
        : memoryGroups;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Memories',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E7E),
            ),
          ),
          const SizedBox(height: 16),
          CarouselSlider(
            options: CarouselOptions(
              height: 180,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              viewportFraction: 0.8,
            ),
            items: fallbackGroups.map((group) {
              final firstUrl = group.imageUrls.isNotEmpty ? group.imageUrls[0] : '';
              return GestureDetector(
                onTap: () {
                  // Open gallery with all images from this group
                  final items = group.imageUrls.map((u) => {'imageUrl': u}).toList();
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GalleryView(
                      items: items,
                      fullscreen: true,
                      initialIndex: 0,
                    ),
                  ));
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (firstUrl.isNotEmpty)
                          Image.network(firstUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey[300]))
                        else
                          Container(color: Colors.grey[300]),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.45),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          bottom: 16,
                          right: 16,
                          child: Text(
                            group.title,
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDateGroup(String dateKey, List<Gallery> images) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              dateKey,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E7E),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final image = images[index];
                // Find the index of this image in the full _galleryImages list
                final globalIndex = _galleryImages.indexOf(image);
                
                return GestureDetector(
                  onTap: () {
                    // Pass ALL images to the gallery view, not just the group
                    final items = _galleryImages.map((g) => {'imageUrl': g.imageUrl ?? ''}).toList();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GalleryView(
                        items: items,
                        fullscreen: true,
                        initialIndex: globalIndex >= 0 ? globalIndex : 0,
                      ),
                    ));
                  },
                  child: Container(
                    width: 120,
                    margin: EdgeInsets.only(right: index == images.length - 1 ? 0 : 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        image.imageUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1B5E7E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library,
              size: 60,
              color: Color(0xFF1B5E7E),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No memories yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E7E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start capturing your moments!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _pickImages(),
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Photos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E7E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}