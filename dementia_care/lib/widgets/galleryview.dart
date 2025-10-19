import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:dementia_care/services/tts_service.dart';

class GalleryView extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool loading;
  final bool fullscreen;
  final int? initialIndex;
  final Function(int, String)? onCaptionUpdate;
  final Function(int)? onDelete;

  const GalleryView({
    Key? key,
    this.items = const [],
    this.loading = false,
    this.fullscreen = false,
    this.initialIndex,
    this.onCaptionUpdate,
    this.onDelete,
  }) : super(key: key);

  @override
  GalleryViewState createState() => GalleryViewState();
}

class GalleryViewState extends State<GalleryView> {
  final List<XFile> _images = [];
  late List<Map<String, dynamic>> _galleryItems;
  late bool _loading;
  PageController? _pageController;
  final TextToSpeechService _ttsService = TextToSpeechService();
  int _currentPage = 0;

  void addImages(List<XFile> images) {
    setState(() {
      _images.addAll(images);
    });
  }

  @override
  void initState() {
    super.initState();
    _galleryItems = List<Map<String, dynamic>>.from(widget.items);
    _loading = widget.loading;
    _currentPage = widget.initialIndex ?? 0;
    
    if (widget.fullscreen) {
      _pageController = PageController(initialPage: _currentPage);
      _pageController?.addListener(() {
        final page = _pageController?.page?.round() ?? 0;
        if (page != _currentPage) {
          setState(() {
            _currentPage = page;
          });
          _ttsService.stop();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant GalleryView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      setState(() {
        _galleryItems = List<Map<String, dynamic>>.from(widget.items);
      });
    }
    if (widget.loading != oldWidget.loading) {
      setState(() {
        _loading = widget.loading;
      });
    }
    if (widget.fullscreen && widget.initialIndex != oldWidget.initialIndex) {
      _pageController?.jumpToPage(widget.initialIndex ?? 0);
    }
  }

  @override
  void dispose() {
    _ttsService.stop();
    _pageController?.dispose();
    super.dispose();
  }

  void _playDescription() {
    if (_currentPage < _galleryItems.length) {
      final item = _galleryItems[_currentPage];
      final description = item['description'] ?? '';
      
      if (description.isNotEmpty) {
        _ttsService.speak(description);
      }
    }
  }

  void _showDescriptionDialog() {
    if (_currentPage < _galleryItems.length) {
      final item = _galleryItems[_currentPage];
      final description = item['description'] ?? 'No description';
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Image Description'),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _editCaption() {
    if (_currentPage < _galleryItems.length) {
      final currentCaption = _galleryItems[_currentPage]['description'] ?? '';
      final controller = TextEditingController(text: currentCaption);
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Edit Caption',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter caption',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _galleryItems[_currentPage]['description'] = controller.text;
                      });
                      widget.onCaptionUpdate?.call(_currentPage, controller.text);
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }
  }

  void _downloadImage() {
    if (_currentPage < _galleryItems.length) {
      final imageUrl = _galleryItems[_currentPage]['image_url'] ?? 
                      _galleryItems[_currentPage]['imageUrl'] ?? '';
      // Implement download logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Downloading image...')),
      );
    }
  }

  void _shareImage() {
    if (_currentPage < _galleryItems.length) {
      final imageUrl = _galleryItems[_currentPage]['image_url'] ?? 
                      _galleryItems[_currentPage]['imageUrl'] ?? '';
      // Implement share logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sharing image...')),
      );
    }
  }

  void _deleteImage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onDelete?.call(_currentPage);
              setState(() {
                _galleryItems.removeAt(_currentPage);
              });
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Fullscreen photo gallery mode
    if (widget.fullscreen) {
      final urls = _galleryItems
          .map((i) => (i['image_url'] ?? i['imageUrl'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();

      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () {
              _ttsService.stop();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.volume_up, color: Colors.white),
              onPressed: _currentPage < _galleryItems.length &&
                      (_galleryItems[_currentPage]['description'] ?? '').isNotEmpty
                  ? _playDescription
                  : null,
              tooltip: "Read Description",
            ),
          ],
        ),
        body: urls.isEmpty
            ? const Center(child: Text('No photos.', style: TextStyle(color: Colors.white)))
            : Stack(
                children: [
                  PhotoViewGallery.builder(
                    pageController: _pageController,
                    itemCount: urls.length,
                    builder: (context, index) => PhotoViewGalleryPageOptions(
                      imageProvider: NetworkImage(urls[index]),
                      initialScale: PhotoViewComputedScale.contained,
                      heroAttributes: PhotoViewHeroAttributes(tag: urls[index]),
                    ),
                    loadingBuilder: (context, event) => 
                        const Center(child: CircularProgressIndicator()),
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                      _ttsService.stop();
                    },
                  ),
                  // Bottom action bar
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        border: Border(
                          top: BorderSide(
                            color: Colors.grey[800]!,
                            width: 1,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Download button
                          IconButton(
                            icon: const Icon(Icons.download, color: Colors.white),
                            onPressed: _downloadImage,
                            tooltip: 'Download',
                          ),
                          // Info button
                          IconButton(
                            icon: const Icon(Icons.info_outline, color: Colors.white),
                            onPressed: _showDescriptionDialog,
                            tooltip: 'Info',
                          ),
                          // Share button
                          IconButton(
                            icon: const Icon(Icons.share, color: Colors.white),
                            onPressed: _shareImage,
                            tooltip: 'Share',
                          ),
                          // Delete button
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white),
                            onPressed: _deleteImage,
                            tooltip: 'Delete',
                          ),
                          // More options button
                          PopupMenuButton(
                            color: Colors.grey[900],
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text(
                                  'Edit Caption',
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: _editCaption,
                              ),
                            ],
                            icon: const Icon(Icons.more_vert, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_galleryItems.isEmpty) {
      return const Center(child: Text('No photos uploaded.'));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: _galleryItems.length,
      itemBuilder: (context, index) {
        final item = _galleryItems[index];
        final imageUrl = item['image_url'] ?? item['imageUrl'] ?? '';
        final hasDescription = (item['description'] ?? '').isNotEmpty;
        
        return GestureDetector(
          onTap: () {
            if (imageUrl.isNotEmpty) {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => GalleryView(
                  items: _galleryItems,
                  fullscreen: true,
                  initialIndex: index,
                  onCaptionUpdate: widget.onCaptionUpdate,
                  onDelete: widget.onDelete,
                ),
              ));
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    Container(color: Colors.grey[300]),
              ),
              if (hasDescription)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.description,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}