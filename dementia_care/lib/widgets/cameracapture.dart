import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as cam;
import 'package:image_picker/image_picker.dart' as ip;
import 'package:dementia_care/widgets/camera_controls.dart';
import 'package:dementia_care/widgets/camera_capture_button.dart';

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
  bool _showGrid = false;
  int _timerSeconds = 0;
  bool _isTakingPicture = false;

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

  // ignore: unused_element
  Future<void> _cycleFlash() async {
    final modes = [
      cam.FlashMode.off,
      cam.FlashMode.auto,
      cam.FlashMode.always,
      cam.FlashMode.torch
    ];
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
    _currentScale = (_baseScale * details.scale).clamp(
        _minAvailableZoom, _maxAvailableZoom);
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
    if (_isTakingPicture) return;

    setState(() {
      _isTakingPicture = true;
    });

    try {
      // Handle timer countdown
      if (_timerSeconds > 0) {
        for (int i = _timerSeconds; i > 0; i--) {
          // Show countdown (you could add a countdown overlay here)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$i'),
                duration: const Duration(seconds: 1),
                backgroundColor: Colors.black.withOpacity(0.7),
              ),
            );
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }

      final cam.XFile camFile = await _controller!.takePicture();

      // Add haptic feedback (if available)
      // HapticFeedback.mediumImpact();

      // Convert camera.XFile -> image_picker.XFile (path-based) so UploadPreviewPage accepts it
      final ip.XFile pickFile = ip.XFile(camFile.path);
      _captured.add(pickFile);

      // Show captured image briefly
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo captured!'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTakingPicture = false;
        });
      }
    }
  }

  void _removeCapturedAt(int idx) {
    setState(() {
      _captured.removeAt(idx);
    });
  }

  void _doneAndReturn() {
    Navigator.of(context).pop<List<ip.XFile>>(
        _captured.isEmpty ? [] : List.from(_captured));
  }

  Widget _buildTopBar() {
    return CameraControls(
      flashMode: _flashMode,
      onFlashChanged: (mode) {
        setState(() {
          _flashMode = mode;
        });
        _controller?.setFlashMode(mode);
      },
      hasMultipleCameras: _cameras.length > 1,
      onSwitchCamera: _switchCamera,
      currentZoom: _currentScale,
      minZoom: _minAvailableZoom,
      maxZoom: _maxAvailableZoom,
      onZoomChanged: (zoom) {
        setState(() {
          _currentScale = zoom;
        });
        _controller?.setZoomLevel(zoom);
      },
      showGrid: _showGrid,
      onToggleGrid: () {
        setState(() {
          _showGrid = !_showGrid;
        });
      },
      timerSeconds: _timerSeconds,
      onTimerChanged: (seconds) {
        setState(() {
          _timerSeconds = seconds;
        });
      },
    );
  }

  Widget _buildCaptureControl() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_captured.isNotEmpty)
            GestureDetector(
              onTap: _doneAndReturn,
              child: Container(
                margin: const EdgeInsets.only(right: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                        Icons.check_circle, color: Colors.white, size: 32),
                    const SizedBox(height: 4),
                    Text('${_captured.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
            ),
          CameraCaptureButton(
            onPressed: _takePicture,
            isEnabled: !_isTakingPicture && _controller?.value.isInitialized == true,
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
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.black54),
                    child: const Icon(
                        Icons.close, size: 14, color: Colors.white),
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
          // Camera preview with grid overlay
          GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            child: _controller != null && _controller!.value.isInitialized
                ? LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (d) => _onViewFinderTap(d, constraints),
                      child: cam.CameraPreview(_controller!),
                    ),
                    // Grid overlay
                    if (_showGrid) _buildGridOverlay(),
                    // Focus indicator (could be added here)
                  ],
                );
              },
            )
                : const Center(child: Text(
                'Camera not available', style: TextStyle(color: Colors.white))),
          ),

          // Top controls
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),

          // Capture button (centered at bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: Center(child: _buildCaptureControl()),
          ),

          // Captured images strip
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [_buildCapturedStrip(), const SizedBox(height: 4)],
            ),
          ),

          // Loading indicator during capture
          if (_isTakingPicture)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: GridPainter(),
        );
      },
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;

    // Rule of thirds grid
    final thirdWidth = size.width / 3;
    final thirdHeight = size.height / 3;

    // Vertical lines
    for (int i = 1; i < 3; i++) {
      final x = thirdWidth * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = thirdHeight * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
