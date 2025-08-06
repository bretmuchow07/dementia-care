import 'package:flutter/material.dart';
import 'package:dementia_care/widgets/galleryview.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Add this import

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final GlobalKey<GalleryViewState> _galleryKey = GlobalKey<GalleryViewState>();

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      for (final image in picked) {
        final bytes = await image.readAsBytes();
        final fileExt = image.path.split('.').last;
        final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = 'gallery/$fileName';

        // 1. Upload to Supabase Storage (gallery bucket)
        await Supabase.instance.client.storage
            .from('gallery')
            .uploadBinary(filePath, bytes, fileOptions: FileOptions(contentType: 'image/$fileExt'));

        // 2. Get public URL
        final publicUrl = Supabase.instance.client.storage
            .from('gallery')
            .getPublicUrl(filePath);

        // 3. Insert into gallery table
        await Supabase.instance.client.from('gallery').insert({
          'image_url': publicUrl,
          'description': '', // You can add a description field in your UI
          'user_id': Supabase.instance.client.auth.currentUser?.id,
          'created_at': DateTime.now().toIso8601String(),
          // Add other fields as needed
        });
      }
      _galleryKey.currentState?.addImages(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.mic),
                        tooltip: 'Voice Input',
                        onPressed: () {
                          // Add voice input functionality here
                        },
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: 'Upload Media',
                  onPressed: _pickImages,
                ),
              ],
            ),
          ),
          Expanded(
            child: GalleryView(key: _galleryKey),
          ),
        ],
      ),
    );
  }
}



