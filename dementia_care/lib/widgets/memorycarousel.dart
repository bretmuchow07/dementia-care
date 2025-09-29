import 'package:dementia_care/models/memory.dart';
//import 'package:dementia_care/widgets/galleryview.dart';
import 'package:dementia_care/widgets/memorycard.dart';
import 'package:flutter/material.dart';

class MemoriesCarousel extends StatelessWidget {
  final List<MemoryGroup> groups;

  const MemoriesCarousel({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.7),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: GestureDetector(
              // onTap: () {
              //   // Navigate to gallery view for this group
              //   Navigator.push(
              //     context,
              //     MaterialPageRoute(
              //       builder: (_) => GalleryView(group: group),
              //     ),
              //   );
              // },
              child: MemoryCard(
                imageUrl: group.imageUrls.first, // show first image as thumbnail
                title: group.title,
              ),
            ),
          );
        },
      ),
    );
  }
}
