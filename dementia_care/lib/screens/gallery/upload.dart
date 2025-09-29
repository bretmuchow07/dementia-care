import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class UploadPreviewPage extends StatefulWidget {
  final List<XFile> initialImages;
  const UploadPreviewPage({Key? key, required this.initialImages}) : super(key: key);

  @override
  State<UploadPreviewPage> createState() => _UploadPreviewPageState();
}

class _PreviewItem {
  XFile file;
  TextEditingController caption;
  Uint8List? bytes;
  bool uploading = false;
  bool uploaded = false;
  
  _PreviewItem({required this.file, String? captionText})
      : caption = TextEditingController(text: captionText ?? '');
}

class _UploadPreviewPageState extends State<UploadPreviewPage> {
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = Uuid();
  List<_PreviewItem> _items = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _items = widget.initialImages.map((f) => _PreviewItem(file: f)).toList();
    _loadBytesForAll();
  }

  Future<void> _loadBytesForAll() async {
    for (final it in _items) {
      try {
        it.bytes = await it.file.readAsBytes();
      } catch (_) {
        it.bytes = null;
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _pickMoreImages() async {
    final picked = await _picker.pickMultiImage();
    if (picked.isEmpty) return;
    final newItems = picked.map((f) => _PreviewItem(file: f)).toList();
    setState(() {
      _items.addAll(newItems);
    });
    await _loadBytesForAll();
  }

  void _removeAt(int index) {
    _showCustomDialog(
      title: 'Remove Image',
      message: 'Are you sure you want to remove this image from the upload list?',
      isConfirmation: true,
      onConfirm: () {
        setState(() {
          _items.removeAt(index);
        });
      },
    );
  }

  void _showCustomDialog({
    required String title,
    required String message,
    bool isConfirmation = false,
    bool success = false,
    VoidCallback? onConfirm,
    VoidCallback? onOk,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isConfirmation)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: success 
                          ? Colors.green.withOpacity(0.1) 
                          : Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      success ? Icons.check_circle : Icons.error,
                      color: success ? Colors.green : Colors.red,
                      size: 50,
                    ),
                  ),
                if (isConfirmation)
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.orange,
                      size: 50,
                    ),
                  ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (isConfirmation)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            if (onConfirm != null) onConfirm();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Text('Remove'),
                        ),
                      ),
                    ],
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onOk != null) onOk();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: success ? Colors.green : const Color(0xFF1B5E7E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadAll() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _showCustomDialog(
        title: 'Authentication Error',
        message: 'Please sign in to upload images.',
        success: false,
        onOk: () => Navigator.of(context).pop(false),
      );
      return;
    }
    if (_items.isEmpty) {
      _showCustomDialog(
        title: 'No Images Selected',
        message: 'Please add at least one image to upload.',
        success: false,
      );
      return;
    }

    setState(() => _isUploading = true);
    int success = 0;
    
    try {
      for (int i = 0; i < _items.length; i++) {
        final item = _items[i];
        setState(() => item.uploading = true);

        try {
          final bytes = item.bytes ?? await item.file.readAsBytes();
          if (bytes.isEmpty) throw Exception('Empty file');

          final fileExt = (item.file.path.split('.').last).toLowerCase();
          final safeExt = fileExt.replaceAll(RegExp(r'[^a-z0-9]'), '');
          final fileName = 'gallery_${DateTime.now().millisecondsSinceEpoch}_${_uuid.v4()}.$safeExt';
          final filePath = 'gallery/$fileName';
          final contentType = 'image/$safeExt';

          await Supabase.instance.client.storage
              .from('gallery')
              .uploadBinary(filePath, bytes, fileOptions: FileOptions(contentType: contentType));

          final publicUrl = Supabase.instance.client.storage
              .from('gallery')
              .getPublicUrl(filePath);
              
          if (publicUrl.isEmpty) throw Exception('Failed to obtain public URL');

          final record = {
            'id': _uuid.v4(),
            'user_id': userId,
            'image_url': publicUrl,
            'description': item.caption.text.trim(),
            'created_at': DateTime.now().toIso8601String(),
          };

          await Supabase.instance.client.from('gallery').insert(record);
          
          setState(() {
            item.uploaded = true;
            item.uploading = false;
          });
          
          success++;
        } catch (e) {
          debugPrint('Upload item error: $e');
          setState(() => item.uploading = false);
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
      
      if (success > 0) {
        _showCustomDialog(
          title: 'Upload Complete!',
          message: success == _items.length 
              ? 'All $success images uploaded successfully!' 
              : '$success of ${_items.length} images uploaded successfully.',
          success: true,
          onOk: () => Navigator.of(context).pop(true),
        );
      } else {
        _showCustomDialog(
          title: 'Upload Failed',
          message: 'No images were uploaded. Please check your connection and try again.',
          success: false,
          onOk: () => Navigator.of(context).pop(false),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Widget _buildGridItem(int index) {
    final item = _items[index];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.hardEdge,
        elevation: 0,
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                    ),
                    child: item.bytes != null
                        ? Image.memory(
                            item.bytes!, 
                            fit: BoxFit.cover, 
                            width: double.infinity,
                          )
                        : Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: item.caption,
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1B5E7E)),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      maxLines: 2,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
            
            // Delete button
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => _removeAt(index),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            
            // Upload status overlay
            if (item.uploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Uploading...',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            
            // Success indicator
            if (item.uploaded && !item.uploading)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final it in _items) {
      it.caption.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Preview & Upload',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF1B5E7E),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(false),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickMoreImages,
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: const Text('Add More'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF1B5E7E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                textStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _items.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1B5E7E).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.photo_library,
                          color: Color(0xFF1B5E7E),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_items.length} ${_items.length == 1 ? 'Image' : 'Images'} Selected',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1B5E7E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Add captions and upload to your gallery',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: _items.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemBuilder: (_, idx) => _buildGridItem(idx),
                    ),
                  ),
                ),
              ],
            ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isUploading ? null : () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: (_isUploading || _items.isEmpty) ? null : _uploadAll,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF1B5E7E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey[300],
                  ),
                  child: _isUploading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Uploading...'),
                          ],
                        )
                      : Text(
                          'Upload ${_items.length} ${_items.length == 1 ? 'Image' : 'Images'}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
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
              Icons.photo_library_outlined,
              size: 60,
              color: Color(0xFF1B5E7E),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No images selected',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1B5E7E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some images to get started',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: _pickMoreImages,
            icon: const Icon(Icons.add_photo_alternate),
            label: const Text('Add Images'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E7E),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}