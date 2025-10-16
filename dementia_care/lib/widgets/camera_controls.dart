import 'package:flutter/material.dart';
import 'package:camera/camera.dart' as cam;

class CameraControls extends StatelessWidget {
  final cam.FlashMode flashMode;
  final Function(cam.FlashMode) onFlashChanged;
  final bool hasMultipleCameras;
  final VoidCallback onSwitchCamera;
  final double currentZoom;
  final double minZoom;
  final double maxZoom;
  final Function(double) onZoomChanged;
  final bool showGrid;
  final VoidCallback onToggleGrid;
  // Note: TimerMode is not available in current camera package version
  // Using a simple int for timer seconds instead
  final int timerSeconds;
  final Function(int) onTimerChanged;

  const CameraControls({
    super.key,
    required this.flashMode,
    required this.onFlashChanged,
    required this.hasMultipleCameras,
    required this.onSwitchCamera,
    required this.currentZoom,
    required this.minZoom,
    required this.maxZoom,
    required this.onZoomChanged,
    required this.showGrid,
    required this.onToggleGrid,
    required this.timerSeconds,
    required this.onTimerChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Top controls row
            Row(
              children: [
                // Flash control
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _getFlashIcon(),
                      color: Colors.white,
                    ),
                    onPressed: _cycleFlash,
                    tooltip: 'Flash: ${_getFlashLabel()}',
                  ),
                ),

                const Spacer(),

                // Grid toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      showGrid ? Icons.grid_on : Icons.grid_off,
                      color: showGrid ? Colors.blue : Colors.white,
                    ),
                    onPressed: onToggleGrid,
                    tooltip: showGrid ? 'Hide grid' : 'Show grid',
                  ),
                ),

                // Camera switch
                if (hasMultipleCameras) ...[
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.cameraswitch,
                        color: Colors.white,
                      ),
                      onPressed: onSwitchCamera,
                      tooltip: 'Switch camera',
                    ),
                  ),
                ],
              ],
            ),

            const Spacer(),

            // Bottom controls row
            Row(
              children: [
                // Gallery preview (placeholder for now)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Colors.white,
                    size: 24,
                  ),
                ),

                const Spacer(),

                // Timer control
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    icon: Icon(
                      _getTimerIcon(),
                      color: timerSeconds > 0 ? Colors.orange : Colors.white,
                    ),
                    onPressed: _cycleTimer,
                    tooltip: 'Timer: ${_getTimerLabel()}',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Zoom slider
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.zoom_out,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 2,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.white,
                        overlayColor: Colors.white.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: currentZoom,
                        min: minZoom,
                        max: maxZoom,
                        onChanged: onZoomChanged,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.zoom_in,
                    color: Colors.white.withOpacity(0.7),
                    size: 20,
                  ),
                ],
              ),
            ),

            // Zoom level indicator
            Text(
              'Zoom: ${currentZoom.toStringAsFixed(1)}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  IconData _getFlashIcon() {
    switch (flashMode) {
      case cam.FlashMode.off:
        return Icons.flash_off;
      case cam.FlashMode.auto:
        return Icons.flash_auto;
      case cam.FlashMode.always:
        return Icons.flash_on;
      case cam.FlashMode.torch:
        return Icons.highlight;
    }
  }

  String _getFlashLabel() {
    switch (flashMode) {
      case cam.FlashMode.off:
        return 'Off';
      case cam.FlashMode.auto:
        return 'Auto';
      case cam.FlashMode.always:
        return 'On';
      case cam.FlashMode.torch:
        return 'Torch';
    }
  }

  void _cycleFlash() {
    final modes = [
      cam.FlashMode.off,
      cam.FlashMode.auto,
      cam.FlashMode.always,
      cam.FlashMode.torch,
    ];
    final currentIndex = modes.indexOf(flashMode);
    final nextIndex = (currentIndex + 1) % modes.length;
    onFlashChanged(modes[nextIndex]);
  }

  IconData _getTimerIcon() {
    if (timerSeconds == 0) return Icons.timer_off;
    if (timerSeconds == 3) return Icons.timer_3;
    if (timerSeconds == 10) return Icons.timer_10;
    return Icons.timer_off;
  }

  String _getTimerLabel() {
    if (timerSeconds == 0) return 'Off';
    if (timerSeconds == 3) return '3s';
    if (timerSeconds == 10) return '10s';
    return 'Off';
  }

  void _cycleTimer() {
    final seconds = [0, 3, 10];
    final currentIndex = seconds.indexOf(timerSeconds);
    final nextIndex = (currentIndex + 1) % seconds.length;
    onTimerChanged(seconds[nextIndex]);
  }
}