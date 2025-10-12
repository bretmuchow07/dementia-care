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

  const GalleryView({
    Key? key,
    this.items = const [],
    this.loading = false,
    this.fullscreen = false,
    this.initialIndex,
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

  // This method allows parent widgets to add images (kept for compatibility)
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
          // Stop any ongoing speech when page changes
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
    // update page controller if initialIndex changed while fullscreen
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
            // TTS Play Button
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
                  // Description overlay at bottom
                  if (_currentPage < _galleryItems.length &&
                      (_galleryItems[_currentPage]['description'] ?? '').isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.transparent,
                            ],
                          ),
                        ),
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _galleryItems[_currentPage]['description'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
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
              // Open a fullscreen GalleryView starting at this index
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => GalleryView(
                  items: _galleryItems,
                  fullscreen: true,
                  initialIndex: index,
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
              // Show indicator if image has description
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