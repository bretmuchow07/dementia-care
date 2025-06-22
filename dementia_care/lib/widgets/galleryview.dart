import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

class GalleryView extends StatefulWidget {
  const GalleryView({Key? key}) : super(key: key);

  @override
  GalleryViewState createState() => GalleryViewState();
}

class GalleryViewState extends State<GalleryView> {
  final List<XFile> _images = [];

  // This method allows parent widgets to add images
  void addImages(List<XFile> images) {
    setState(() {
      _images.addAll(images);
    });
  }

  void _openPhoto(BuildContext context, XFile image) async {
    final bytes = await image.readAsBytes();
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: PhotoView(
              imageProvider: MemoryImage(bytes),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _images.isEmpty
        ? const Center(child: Text('No photos selected.'))
        : GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: _images.length,
            itemBuilder: (context, index) {
              return FutureBuilder<Uint8List>(
                future: _images[index].readAsBytes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(color: Colors.grey[300]);
                  }
                  return GestureDetector(
                    onTap: () => _openPhoto(context, _images[index]),
                    child: Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[300]),
                    ),
                  );
                },
              );
            },
          );
  }
}