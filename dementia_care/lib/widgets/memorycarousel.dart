import 'package:dementia_care/models/memory.dart';
import 'package:story_view/story_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MemoriesCarousel extends StatelessWidget {
  final List<MemoryGroup> groups;

  const MemoriesCarousel({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _openStory(context, index),
              child: Container(
                width: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image
                      Image.network(
                        group.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.photo,
                              size: 48,
                              color: Colors.grey,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Color(0xFF1B5E7E),
                              ),
                            ),
                          );
                        },
                      ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),
                      // Content
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 12,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (group.title.isNotEmpty)
                              Text(
                                group.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    group.date != null
                                        ? DateFormat('MMM d, yyyy').format(group.date!)
                                        : 'Memory',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (group.imageUrls.length > 1)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.photo_library,
                                          color: Colors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${group.imageUrls.length}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openStory(BuildContext context, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MemoryStoryViewer(
          groups: groups,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class MemoryStoryViewer extends StatefulWidget {
  final List<MemoryGroup> groups;
  final int initialIndex;

  const MemoryStoryViewer({
    super.key,
    required this.groups,
    required this.initialIndex,
  });

  @override
  State<MemoryStoryViewer> createState() => _MemoryStoryViewerState();
}

class _MemoryStoryViewerState extends State<MemoryStoryViewer> {
  late PageController _pageController;
  late int _currentGroupIndex;
  final Map<int, StoryController> _storyControllers = {};

  @override
  void initState() {
    super.initState();
    _currentGroupIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    
    // Initialize story controller for initial page
    _storyControllers[widget.initialIndex] = StoryController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (var controller in _storyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  StoryController _getController(int index) {
    if (!_storyControllers.containsKey(index)) {
      _storyControllers[index] = StoryController();
    }
    return _storyControllers[index]!;
  }

  void _goToNextGroup() {
    if (_currentGroupIndex < widget.groups.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _goToPreviousGroup() {
    if (_currentGroupIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.groups.length,
        onPageChanged: (index) {
          setState(() {
            _currentGroupIndex = index;
          });
        },
        itemBuilder: (context, groupIndex) {
          final group = widget.groups[groupIndex];
          final controller = _getController(groupIndex);
          
          final storyItems = group.imageUrls.map((url) {
            return StoryItem.pageImage(
              url: url,
              controller: controller,
              imageFit: BoxFit.contain,
              duration: const Duration(seconds: 5),
            );
          }).toList();

          return GestureDetector(
            onTapDown: (details) {
              final screenWidth = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < screenWidth / 3) {
                // Tapped on left third - previous story/group
                controller.previous();
              } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
                // Tapped on right third - next story/group
                controller.next();
              } else {
                // Tapped in middle - pause/play
                if (controller.playbackNotifier.value == PlaybackState.pause) {
                  controller.play();
                } else {
                  controller.pause();
                }
              }
            },
            child: Stack(
              children: [
                StoryView(
                  storyItems: storyItems,
                  controller: controller,
                  onComplete: _goToNextGroup,
                  onVerticalSwipeComplete: (direction) {
                    if (direction == Direction.down) {
                      Navigator.pop(context);
                    }
                  },
                  onStoryShow: (storyItem, index) {
                    // Optional: Add analytics or additional functionality
                  },
                  progressPosition: ProgressPosition.top,
                  repeat: false,
                ),
                // Header with date and close button
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        // Profile picture thumbnail
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: ClipOval(
                            child: Image.network(
                              group.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey,
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Date and time info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                group.date != null 
                                    ? DateFormat('MMMM d, yyyy').format(group.date!)
                                    : 'Memory',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (group.title.isNotEmpty)
                                Text(
                                  group.title,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        // Close button
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 28,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom gradient for better visibility if needed
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}