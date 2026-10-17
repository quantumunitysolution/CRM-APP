import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraViewfinder extends StatefulWidget {
  final CameraController? controller;
  final bool isCameraInitialized;
  final bool isRecording;
  final VoidCallback onToggleFlash;
  final VoidCallback onSwitchLens;
  final bool isFlashOn;

  const CameraViewfinder({
    super.key,
    this.controller,
    this.isCameraInitialized = false,
    this.isRecording = false,
    required this.onToggleFlash,
    required this.onSwitchLens,
    required this.isFlashOn,
  });

  @override
  State<CameraViewfinder> createState() => _CameraViewfinderState();
}

class _CameraViewfinderState extends State<CameraViewfinder>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return AspectRatio(
      aspectRatio: isLandscape ? (4 / 3) : (3 / 4),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: isLandscape ? 4 : 16),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: const Color(0xFF334155), width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. LIVE HARDWARE CAMERA STREAM (or fallback simulated lens)
            if (widget.controller != null && widget.isCameraInitialized)
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: isLandscape
                        ? (widget.controller!.value.previewSize?.width ?? 400)
                        : (widget.controller!.value.previewSize?.height ?? 300),
                    height: isLandscape
                        ? (widget.controller!.value.previewSize?.height ?? 300)
                        : (widget.controller!.value.previewSize?.width ?? 400),
                    child: CameraPreview(widget.controller!),
                  ),
                ),
              )
            else
              // Fallback simulated lens background when camera is initializing or running in simulator
              Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0, -0.2),
                    radius: 1.1,
                    colors: [Color(0xFF1E293B), Color(0xFF090D16)],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0xFF38BDF8),
                        strokeWidth: 2,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Connecting to camera sensor...',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),

            // Subtle dark vignette to make viewfinder elements pop
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.45),
                  ],
                  stops: const [0.0, 0.2, 0.8, 1.0],
                ),
              ),
            ),

            // Rule of thirds grid lines
            _buildGridOverlay(),

            // Four corner viewfinder brackets
            _buildCornerBrackets(),

            // Center targeting reticle
            Center(
              child: Container(
                width: 70 + (_pulseController.value * 8),
                height: 70 + (_pulseController.value * 8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(
                      alpha: 0.4 + (_pulseController.value * 0.4),
                    ),
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            ),
            // Top Right Quick Controls (Flash & Switch Lens)
            Positioned(
              top: 10,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: widget.onToggleFlash,
                    icon: Icon(
                      widget.isFlashOn ? Icons.flash_on : Icons.flash_off,
                      color: widget.isFlashOn
                          ? const Color(0xFFF59E0B)
                          : Colors.white70,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: widget.onSwitchLens,
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white70,
                      size: 20,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black38,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ),

            // Bottom camera guidance hint
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Align business card or document inside frame',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridOverlay() {
    return CustomPaint(painter: _GridPainter(), size: Size.infinite);
  }

  Widget _buildCornerBrackets() {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: _bracket(isTop: true, isLeft: true),
          ),
          Align(
            alignment: Alignment.topRight,
            child: _bracket(isTop: true, isLeft: false),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: _bracket(isTop: false, isLeft: true),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: _bracket(isTop: false, isLeft: false),
          ),
        ],
      ),
    );
  }

  Widget _bracket({required bool isTop, required bool isLeft}) {
    const size = 20.0;
    const thickness = 2.5;
    const color = Color(0xFF38BDF8);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          bottom: !isTop
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          left: isLeft
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
          right: !isLeft
              ? const BorderSide(color: color, width: thickness)
              : BorderSide.none,
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );

    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
