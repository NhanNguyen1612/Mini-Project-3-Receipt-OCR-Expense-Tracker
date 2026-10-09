import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../services/receipt_cropper.dart';
import '../services/receipt_service.dart';
import '../state/expenses_controller.dart';

class CameraScanScreen extends ConsumerStatefulWidget {
  const CameraScanScreen({super.key});

  @override
  ConsumerState<CameraScanScreen> createState() => _CameraScanScreenState();
}

class _CameraScanScreenState extends ConsumerState<CameraScanScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _camera;
  String? _error;
  Offset? _focusPoint;
  bool _flashOn = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw StateError('Thiết bị không có camera');
      _camera ??= cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        _camera!,
        ResolutionPreset.high,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _error = null;
        _flashOn = false;
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Không mở được camera: $error');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final controller = _controller;
      _controller = null;
      controller?.dispose();
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _initialize();
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    try {
      final next = !_flashOn;
      await controller.setFlashMode(next ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashOn = next);
    } catch (error) {
      _showError('Không đổi được đèn flash: $error');
    }
  }

  Future<void> _focus(TapDownDetails details, Size size) async {
    final controller = _controller;
    if (controller == null || !controller.value.focusPointSupported) return;
    final point = Offset(
      (details.localPosition.dx / size.width).clamp(0.0, 1.0),
      (details.localPosition.dy / size.height).clamp(0.0, 1.0),
    );
    try {
      await controller.setFocusPoint(point);
      if (mounted) setState(() => _focusPoint = point);
    } catch (error) {
      _showError('Không lấy nét được: $error');
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || _busy) return;
    setState(() => _busy = true);
    try {
      final photo = await controller.takePicture();
      // Pass the full photo to ML Kit so that header (merchant) and footer (total amount)
      // are never accidentally cropped out due to aspect ratio or framing differences.
      final scan = await ref.read(receiptServiceProvider).recognize(photo);
      if (mounted) Navigator.of(context).pop<ReceiptScan>(scan);
    } catch (error) {
      _showError('Không quét được hóa đơn: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Quét hóa đơn',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            tooltip: _flashOn ? 'Tắt flash' : 'Bật flash',
            onPressed: controller == null ? null : _toggleFlash,
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off_outlined,
                color: _flashOn ? AppPalette.lime : Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white)),
                      )
                    : controller == null || !controller.value.isInitialized
                        ? const CircularProgressIndicator()
                        : AspectRatio(
                            aspectRatio: MediaQuery.orientationOf(context) ==
                                    Orientation.portrait
                                ? 1 / controller.value.aspectRatio
                                : controller.value.aspectRatio,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final size = Size(
                                  constraints.maxWidth,
                                  constraints.maxHeight,
                                );
                                return Stack(fit: StackFit.expand, children: [
                                  CameraPreview(controller),
                                  CustomPaint(painter: _ReceiptFramePainter()),
                                  GestureDetector(
                                    behavior: HitTestBehavior.translucent,
                                    onTapDown: (details) =>
                                        _focus(details, size),
                                  ),
                                  if (_focusPoint != null)
                                    Positioned(
                                      left: _focusPoint!.dx * size.width - 18,
                                      top: _focusPoint!.dy * size.height - 18,
                                      child: const Icon(
                                          Icons.center_focus_strong,
                                          size: 36,
                                          color: Colors.yellow),
                                    ),
                                ]);
                              },
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 15),
            const Text('Đưa toàn bộ hóa đơn vào khung',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Chạm để lấy nét  ·  Bật flash khi cần',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.coral,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 58),
                ),
                onPressed: controller == null || _busy ? null : _capture,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.camera_alt),
                label: Text(_busy ? 'Đang nhận dạng...' : 'Chụp và nhận dạng'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final frame = Rect.fromLTWH(
      size.width * ReceiptFrame.left,
      size.height * ReceiptFrame.top,
      size.width * ReceiptFrame.width,
      size.height * ReceiptFrame.height,
    );
    final outside = Path()
      ..addRect(Offset.zero & size)
      ..addRect(frame)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(outside, Paint()..color = Colors.black54);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, const Radius.circular(12)),
      Paint()
        ..color = Colors.white70
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final corners = Path();
    const length = 26.0;
    corners
      ..moveTo(frame.left, frame.top + length)
      ..lineTo(frame.left, frame.top)
      ..lineTo(frame.left + length, frame.top)
      ..moveTo(frame.right - length, frame.top)
      ..lineTo(frame.right, frame.top)
      ..lineTo(frame.right, frame.top + length)
      ..moveTo(frame.right, frame.bottom - length)
      ..lineTo(frame.right, frame.bottom)
      ..lineTo(frame.right - length, frame.bottom)
      ..moveTo(frame.left + length, frame.bottom)
      ..lineTo(frame.left, frame.bottom)
      ..lineTo(frame.left, frame.bottom - length);
    canvas.drawPath(
        corners,
        Paint()
          ..color = AppPalette.coral
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
