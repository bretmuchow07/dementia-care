import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

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
    if (widget.fullscreen) {
      _pageController = PageController(initialPage: widget.initialIndex ?? 0);
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
    _pageController?.dispose();
    super.dispose();
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
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: urls.isEmpty
            ? const Center(child: Text('No photos.', style: TextStyle(color: Colors.white)))
            : PhotoViewGallery.builder(
                pageController: _pageController,
                itemCount: urls.length,
                builder: (context, index) => PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(urls[index]),
                  initialScale: PhotoViewComputedScale.contained,
                  heroAttributes: PhotoViewHeroAttributes(tag: urls[index]),
                ),
                loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
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
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey[300]),
          ),
        );
      },
    );
  }
}