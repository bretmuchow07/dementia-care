import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dementia_care/models/memory.dart';
import 'package:dementia_care/widgets/galleryview.dart';
import 'package:dementia_care/widgets/memorycarousel.dart';

class MemoryCard extends StatefulWidget {
  final String imageUrl;
  final String title;
  final VoidCallback? onTap;

  const MemoryCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.onTap,
  });

  @override
  State<MemoryCard> createState() => _MemoryCardState();
}

class _MemoryCardState extends State<MemoryCard> {
  bool _isLoaded = false;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  @override
  void initState() {
    super.initState();
    _precache();
  }

  @override
  void didUpdateWidget(covariant MemoryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _isLoaded = false;
      _precache();
    }
  }

  void _precache() {
    if (widget.imageUrl.isEmpty) return;
    final provider = NetworkImage(widget.imageUrl);
    _imageStream = provider.resolve(const ImageConfiguration());
    final listener = ImageStreamListener((_, __) {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
    }, onError: (_, __) {
      if (mounted) {
        setState(() {
          _isLoaded = false;
        });
      }
    });
    _imageStream!.addListener(listener);
  }

 void _cleanup() {
    if (_imageStream != null && _imageStreamListener != null) {
      _imageStream!.removeListener(_imageStreamListener!);
      _imageStream = null;
      _imageStreamListener = null;
    }
  }

  @override
  void dispose() {
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
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
              if (widget.imageUrl.isNotEmpty)
                // show a loading placeholder until image is precached
                _isLoaded
                    ? Image.network(
                        widget.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.photo, size: 40, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Color(0xFF1B5E7E),
                          ),
                        ),
                      )
              else
                Container(
                  color: Colors.grey[300],
                  child: const Icon(Icons.photo, size: 40, color: Colors.grey),
                ),
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
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MemoryCardList extends StatelessWidget {
  final List<MemoryGroup> memoryGroups;

  const MemoryCardList({
    super.key,
    required this.memoryGroups,
  });

  @override
  Widget build(BuildContext context) {
    if (memoryGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CarouselSlider(
            options: CarouselOptions(
              height: 180,
              enlargeCenterPage: true,
              enableInfiniteScroll: false,
              viewportFraction: 0.8,
            ),
            items: memoryGroups.map((group) {
              final firstUrl = group.imageUrls.isNotEmpty ? group.imageUrls[0] : '';
              return MemoryCard(
                imageUrl: firstUrl,
                title: group.title,
                onTap: () {
                  // Open memory story viewer with all images from this group
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MemoryStoryViewer(
                        groups: [group],
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Alternative: Simple horizontal scroll version (without carousel_slider)
class MemoryCardListSimple extends StatelessWidget {
  final List<MemoryGroup> memoryGroups;

  const MemoryCardListSimple({
    super.key,
    required this.memoryGroups,
  });

  @override
  Widget build(BuildContext context) {
    if (memoryGroups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Memories',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1B5E7E),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: memoryGroups.length,
              itemBuilder: (context, index) {
                final group = memoryGroups[index];
                final firstUrl = group.imageUrls.isNotEmpty ? group.imageUrls[0] : '';
                
                return Container(
                  width: 250,
                  margin: EdgeInsets.only(
                    right: index == memoryGroups.length - 1 ? 0 : 12,
                  ),
                  child: MemoryCard(
                    imageUrl: firstUrl,
                    title: group.title,
                    onTap: () {
                      // Open gallery with all images from this group
                      final items = group.imageUrls.map((u) => {'imageUrl': u}).toList();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => GalleryView(
                            items: items,
                            fullscreen: true,
                            initialIndex: 0,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}