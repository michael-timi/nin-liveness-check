import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../controllers/verification_controller.dart';
import '../../models/verification_models.dart';

class CaptureStep extends StatefulWidget {
  const CaptureStep({super.key});

  @override
  State<CaptureStep> createState() => _CaptureStepState();
}

class _CaptureStepState extends State<CaptureStep> with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _initialiseFuture;
  Uint8List? _selfieBytes;
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  AccelerometerEvent? _latestAccel;
  bool _isCapturing = false;
  String? _cameraError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialiseCamera();
    _listenToSensors();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _accelerometerSub?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final cameraController = _cameraController;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initialiseCamera();
    }
  }

  Future<void> _initialiseCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      _cameraController = controller;
      _initialiseFuture = controller.initialize();
      setState(() {
        _cameraError = null;
      });
    } catch (e) {
      setState(() {
        _cameraError = 'Unable to start camera: $e';
      });
    }
  }

  void _listenToSensors() {
    _accelerometerSub = accelerometerEvents.listen((event) {
      setState(() {
        _latestAccel = event;
      });
    });
  }

  Future<void> _captureImage() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    setState(() {
      _isCapturing = true;
    });

    try {
      final picture = await controller.takePicture();
      final bytes = await picture.readAsBytes();
      setState(() {
        _selfieBytes = bytes;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to capture image: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<VerificationController>();
    final prompts = controller.session?.prompts ?? const <LivenessPrompt>[];

    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FutureBuilder<void>(
                      future: _initialiseFuture,
                      builder: (context, snapshot) {
                        if (_cameraError != null) {
                          return _ErrorBanner(message: _cameraError!);
                        }
                        if (snapshot.connectionState == ConnectionState.done &&
                            _cameraController != null &&
                            _cameraController!.value.isInitialized) {
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              CameraPreview(_cameraController!),
                              Positioned(
                                bottom: 16,
                                left: 16,
                                right: 16,
                                child: _PromptCard(prompt: controller.currentPrompt),
                              ),
                            ],
                          );
                        }
                        return const Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_latestAccel != null)
                  Text(
                    'Movement (x, y, z): '
                    '${_latestAccel!.x.toStringAsFixed(2)}, '
                    '${_latestAccel!.y.toStringAsFixed(2)}, '
                    '${_latestAccel!.z.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: _isCapturing ? null : _captureImage,
                      child: _isCapturing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Capture frame'),
                    ),
                    if (prompts.length > 1 &&
                        controller.currentPromptIndex < prompts.length - 1)
                      OutlinedButton(
                        onPressed: () {
                          controller.markPromptCompleted();
                        },
                        child: const Text('Next prompt'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_selfieBytes != null)
                  Text(
                    'Frame captured: ${(_selfieBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(color: Colors.green),
                  ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.isProcessing
                  ? null
                  : () {
                      if (_selfieBytes == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Capture at least one frame before continuing.'),
                          ),
                        );
                        return;
                      }

                      controller.submitEvidence(
                        selfieBytes: _selfieBytes!,
                        metadata: {
                          'nin': controller.nin,
                          'promptsCompleted': controller.currentPromptIndex + 1,
                          'accelerometer': _latestAccel == null
                              ? null
                              : {
                                  'x': _latestAccel!.x,
                                  'y': _latestAccel!.y,
                                  'z': _latestAccel!.z,
                                },
                          'capturedAt': DateTime.now().toIso8601String(),
                        },
                      );
                    },
              child: controller.isProcessing
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit for verification'),
            ),
          ),
        ),
      ],
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt});

  final LivenessPrompt? prompt;

  @override
  Widget build(BuildContext context) {
    if (prompt == null) {
      return const SizedBox.shrink();
    }

    final icon = switch (prompt!.type) {
      LivenessPromptType.blink => Icons.visibility,
      LivenessPromptType.smile => Icons.sentiment_satisfied,
      LivenessPromptType.headTurnLeft => Icons.turn_left,
      LivenessPromptType.headTurnRight => Icons.turn_right,
      LivenessPromptType.speakPhrase => Icons.mic,
    };

    return Card(
      color: Colors.black.withOpacity(0.6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                prompt!.description,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.red.shade100,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
