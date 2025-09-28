import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dementia_care/widgets/galleryview.dart';
import 'package:camera/camera.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dementia_care/models/gallery.dart';
import 'package:uuid/uuid.dart';

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
      // Keep logging simple
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
      return _formatDate(date);
    }
  }

  String _formatWeekday(DateTime date) {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return weekdays[date.weekday - 1];
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<bool> _uploadAndInsert(XFile image) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        _showResultDialog(
          success: false,
          title: 'Not Authenticated',
          message: 'Please sign in to upload images.',
        );
        return false;
      }

      final bytes = await image.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Empty file');
      }

      final fileExt = (image.path.split('.').last).toLowerCase();
      final safeExt = fileExt.replaceAll(RegExp(r'[^a-z0-9]'), '');
      final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}.$safeExt';
      final filePath = 'gallery/$fileName';
      final contentType = 'image/$safeExt';

      await Supabase.instance.client.storage
          .from('gallery')
          .uploadBinary(filePath, bytes, fileOptions: FileOptions(contentType: contentType));

      final publicUrl = Supabase.instance.client.storage.from('gallery').getPublicUrl(filePath);
      final imageUrl = publicUrl.toString();

      if (imageUrl.isEmpty) {
        throw Exception('Failed to obtain public URL');
      }

      final newGallery = Gallery(
        id: uuid.v4(),
        createdAt: DateTime.now(),
        imageUrl: imageUrl,
        description: '',
        userId: userId,
      );

      await Supabase.instance.client.from('gallery').insert(newGallery.toJson());

      return true;
    } catch (e) {
      print('Upload error: $e');
      return false;
    }
  }

  Future<void> _pickImages() async {
    final List<XFile>? picked = await _picker.pickMultiImage();
    if (picked == null || picked.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    int successCount = 0;
    try {
      for (final image in picked) {
        final ok = await _uploadAndInsert(image);
        if (ok) successCount++;
      }
      await _loadGalleryImages();
      _showResultDialog(
        success: successCount > 0,
        title: successCount > 0 ? 'Upload Complete' : 'Upload Failed',
        message: successCount > 0
            ? '$successCount image(s) uploaded successfully.'
            : 'No images were uploaded. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openCamera() async {
    final result = await Navigator.of(context).push<XFile?>(
      MaterialPageRoute(
        builder: (_) => const CameraCapturePage(),
      ),
    );
    if (result == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ok = await _uploadAndInsert(result);
      await _loadGalleryImages();
      _showResultDialog(
        success: ok,
        title: ok ? 'Upload Successful' : 'Upload Failed',
        message: ok ? 'Your photo was uploaded.' : 'Failed to upload image. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
                  prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.mic, color: Colors.grey[600]),
                    onPressed: () {
                      // Voice input functionality
                    },
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
          ..._groupedImages.entries.map((entry) => _buildDateGroup(entry.key, entry.value)),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMemoriesSection() {
    final recentImages = _galleryImages.take(5).toList();

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
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: recentImages.length,
              itemBuilder: (context, index) {
                final image = recentImages[index];
                return GestureDetector(
                  onTap: () {
                    final items = recentImages
                        .map((g) => {'imageUrl': g.imageUrl ?? ''})
                        .toList();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GalleryView(
                        items: items,
                        fullscreen: true,
                        initialIndex: index,
                      ),
                    ));
                  },
                  child: Container(
                    width: 140,
                    margin: EdgeInsets.only(right: index == recentImages.length - 1 ? 0 : 12),
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
                          Image.network(
                            image.imageUrl ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error),
                              );
                            },
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.4),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
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
                return GestureDetector(
                  onTap: () {
                    final items = images.map((g) => {'imageUrl': g.imageUrl ?? ''}).toList();
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => GalleryView(
                        items: items,
                        fullscreen: true,
                        initialIndex: index,
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

// Camera Capture Page (unchanged)
class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({Key? key}) : super(key: key);

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  bool _isTakingPicture = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'No cameras available';
          _isLoading = false;
        });
        return;
      }
      _controller = CameraController(_cameras!.first, ResolutionPreset.high, enableAudio: false);
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to initialize camera: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      final XFile file = await _controller!.takePicture();
      if (!mounted) return;
      Navigator.of(context).pop<XFile?>(file);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking photo: $e')),
      );
    } finally {
      setState(() {
        _isTakingPicture = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Camera'),
          backgroundColor: const Color(0xFF1B5E7E),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 80, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Take Photo'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: _controller != null && _controller!.value.isInitialized
                ? CameraPreview(_controller!)
                : const Center(
              child: Text(
                'Camera not available',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 60),
                GestureDetector(
                  onTap: _takePicture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.grey[300]!, width: 4),
                    ),
                    child: _isTakingPicture
                        ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF1B5E7E),
                        strokeWidth: 3,
                      ),
                    )
                        : const Center(
                      child: Icon(
                        Icons.camera_alt,
                        size: 30,
                        color: Color(0xFF1B5E7E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}