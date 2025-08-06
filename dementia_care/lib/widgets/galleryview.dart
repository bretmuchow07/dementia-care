import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/gallery.dart'; // Adjust the path if needed

class GalleryView extends StatefulWidget {
  const GalleryView({Key? key}) : super(key: key);

  @override
  GalleryViewState createState() => GalleryViewState();
}

class GalleryViewState extends State<GalleryView> {
  final List<XFile> _images = [];
  List<Gallery> _galleryItems = [];
  bool _loading = true;

  // This method allows parent widgets to add images
  void addImages(List<XFile> images) {
    setState(() {
      _images.addAll(images);
    });
    // Optionally, you can refresh gallery items after upload
    fetchGalleryItems();
  }

  @override
  void initState() {
    super.initState();
    fetchGalleryItems();
  }

  Future<void> fetchGalleryItems() async {
    setState(() => _loading = true);
    final response = await Supabase.instance.client
        .from('gallery')
        .select()
        .order('created_at', ascending: false);
    setState(() {
      _galleryItems = (response as List)
          .map((item) => Gallery.fromJson(item))
          .where((g) => g.imageUrl != null)
          .toList();
      _loading = false;
    });
  }

  void _openPhoto(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(),
          body: Center(
            child: PhotoView(
              imageProvider: NetworkImage(imageUrl),
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        return GestureDetector(
          onTap: () => _openPhoto(context, item.imageUrl!),
          child: Image.network(
            item.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                Container(color: Colors.grey[300]),
          ),
        );
      },
    );
  }
}