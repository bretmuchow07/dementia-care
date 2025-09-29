import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as cam;
import 'package:image_picker/image_picker.dart' as ip;

class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({Key? key}) : super(key: key);

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> with WidgetsBindingObserver {
  cam.CameraController? _controller;
  List<cam.CameraDescription> _cameras = [];
  int _selectedCameraIdx = 0;
  bool _isInitializing = true;
  String? _error;
  double _baseScale = 1.0;
  double _currentScale = 1.0;
  double _minAvailableZoom = 1.0;
  double _maxAvailableZoom = 1.0;
  cam.FlashMode _flashMode = cam.FlashMode.off;

  // Captured images returned as image_picker.XFile (compatible with UploadPreviewPage)
  final List<ip.XFile> _captured = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCameras();
  }

  Future<void> _initCameras() async {
    try {
      _cameras = await cam.availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _error = 'No cameras found';
          _isInitializing = false;
        });
        return;
      }
      await _initController(_cameras[_selectedCameraIdx]);
    } catch (e) {
      setState(() {
        _error = 'Camera initialization failed: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _initController(cam.CameraDescription description) async {
    _controller?.dispose();
    _controller = cam.CameraController(
      description,
      cam.ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: cam.ImageFormatGroup.jpeg,
    );

    _isInitializing = true;
    setState(() {});

    try {
      await _controller!.initialize();
      _flashMode = cam.FlashMode.off;
      await _controller!.setFlashMode(_flashMode);
      _minAvailableZoom = await _controller!.getMinZoomLevel();
      _maxAvailableZoom = await _controller!.getMaxZoomLevel();
    } catch (e) {
      _error = 'Failed to start camera: $e';
    } finally {
      _isInitializing = false;
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initController(_cameras[_selectedCameraIdx]);
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras.length;
    _initController(_cameras[_selectedCameraIdx]);
  }

  Future<void> _cycleFlash() async {
    final modes = [cam.FlashMode.off, cam.FlashMode.auto, cam.FlashMode.always, cam.FlashMode.torch];
    final nextIndex = (modes.indexOf(_flashMode) + 1) % modes.length;
    _flashMode = modes[nextIndex];
    try {
      await _controller?.setFlashMode(_flashMode);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _baseScale = _currentScale;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    if (_controller == null) return;
    _currentScale = (_baseScale * details.scale).clamp(_minAvailableZoom, _maxAvailableZoom);
    await _controller!.setZoomLevel(_currentScale);
  }

  void _onViewFinderTap(TapDownDetails details, BoxConstraints constraints) {
    if (_controller == null) return;

    final offset = Offset(
      details.localPosition.dx / constraints.maxWidth,
      details.localPosition.dy / constraints.maxHeight,
    );

    try {
      _controller!.setExposurePoint(offset);
      _controller!.setFocusPoint(offset);
    } catch (_) {}
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      final cam.XFile camFile = await _controller!.takePicture();
      // Convert camera.XFile -> image_picker.XFile (path-based) so UploadPreviewPage accepts it
      final ip.XFile pickFile = ip.XFile(camFile.path);
      _captured.add(pickFile);
      if (mounted) setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Capture failed: $e')));
    }
  }

  void _removeCapturedAt(int idx) {
    setState(() {
      _captured.removeAt(idx);
    });
  }

  void _doneAndReturn() {
    Navigator.of(context).pop<List<ip.XFile>>(_captured.isEmpty ? [] : List.from(_captured));
  }

  Widget _buildTopBar() {
    String flashLabel() {
      switch (_flashMode) {
        case cam.FlashMode.auto:
          return 'Auto';
        case cam.FlashMode.always:
          return 'On';
        case cam.FlashMode.torch:
          return 'Torch';
        case cam.FlashMode.off:
        return 'Off';
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).pop<List<ip.XFile>>(_captured.isEmpty ? [] : List.from(_captured)),
            ),
            const Spacer(),
            if (_cameras.length > 1)
              IconButton(
                icon: const Icon(Icons.cameraswitch, color: Colors.white),
                onPressed: _switchCamera,
              ),
            TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              onPressed: _cycleFlash,
              icon: const Icon(Icons.flash_on),
              label: Text(flashLabel()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaptureControl() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_captured.isNotEmpty)
            GestureDetector(
              onTap: () {
                // show gallery preview of captured images? keep simple: open upload directly
                _doneAndReturn();
              },
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 28),
                    const SizedBox(height: 4),
                    Text('${_captured.length}', style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300, width: 4),
              ),
              child: const Center(child: Icon(Icons.camera_alt, size: 30, color: Color(0xFF1B5E7E))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapturedStrip() {
    return SizedBox(
      height: 84,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _captured.length,
        itemBuilder: (context, i) {
          final f = _captured[i];
          return Stack(
            children: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.black26,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    // image_picker.XFile.path -> File
                    File(f.path),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _removeCapturedAt(i),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: const Color(0xFF1B5E7E)),
        body: Center(child: Text(_error!)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            child: _controller != null && _controller!.value.isInitialized
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (d) => _onViewFinderTap(d, constraints),
                        child: cam.CameraPreview(_controller!),
                      );
                    },
                  )
                : const Center(child: Text('Camera not available', style: TextStyle(color: Colors.white))),
          ),
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          Positioned(left: 0, right: 0, bottom: 120, child: Center(child: _buildCaptureControl())),
          Positioned(left: 0, right: 0, bottom: 0, child: Column(children: [_buildCapturedStrip(), const SizedBox(height: 4), _bottomActionRow()]))
        ],
      ),
    );
  }

  Widget _bottomActionRow() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop<List<ip.XFile>>([]),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white24),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _captured.isEmpty ? null : _doneAndReturn,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E7E)),
                child: Text(_captured.isEmpty ? 'Take photo' : 'Done (${_captured.length})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}