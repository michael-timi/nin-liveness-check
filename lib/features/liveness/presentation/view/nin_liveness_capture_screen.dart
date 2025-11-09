import 'dart:async';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../application/nin_liveness_providers.dart';
import '../../domain/entities/liveness_action.dart';
import '../../domain/models/nin_liveness_submission.dart';

class NinLivenessCaptureScreen extends ConsumerStatefulWidget {
  const NinLivenessCaptureScreen({
    super.key,
    required this.nin,
    required this.requiredActions,
  });

  final String nin;
  final List<LivenessAction> requiredActions;

  @override
  ConsumerState<NinLivenessCaptureScreen> createState() =>
      _NinLivenessCaptureScreenState();
}

class _NinLivenessCaptureScreenState
    extends ConsumerState<NinLivenessCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  PermissionStatus? _permissionStatus;

  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isInitializing = true;
  String? _errorMessage;

  int _currentActionIndex = 0;
  Duration _recordingDuration = Duration.zero;
  Timer? _durationTimer;
  final Set<LivenessAction> _completedActions = <LivenessAction>{};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestPermissionAndInitialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _durationTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      controller.dispose();
      _cameraController = null;
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _requestPermissionAndInitialize() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    final status = await Permission.camera.request();

    if (!mounted) return;

    setState(() {
      _permissionStatus = status;
    });

    if (!status.isGranted) {
      setState(() {
        _isInitializing = false;
        _errorMessage =
            'Camera permission is required to complete liveness verification.';
      });
      return;
    }

    await _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device.';
          _isInitializing = false;
        });
        return;
      }

      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _cameraController = controller;
      _initializeControllerFuture = controller.initialize();
      await _initializeControllerFuture;

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _errorMessage = null;
      });
    } on CameraException catch (error) {
      setState(() {
        _errorMessage =
            'Failed to initialize camera (${error.description ?? error.code}).';
        _isInitializing = false;
      });
    } catch (error) {
      setState(() {
        _errorMessage = 'Unexpected error: $error';
        _isInitializing = false;
      });
    }
  }

  void _startDurationTicker() {
    _durationTimer?.cancel();
    _durationTimer =
        Timer.periodic(const Duration(seconds: 1), (_) => _tickRecording());
  }

  void _tickRecording() {
    setState(() {
      _recordingDuration += const Duration(seconds: 1);
    });
  }

  void _stopDurationTicker() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  Future<void> _startRecording() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized || _isRecording) {
      return;
    }

    setState(() {
      _isRecording = true;
      _errorMessage = null;
      _recordingDuration = Duration.zero;
      _completedActions.clear();
    });

    try {
      await controller.startVideoRecording();
    } on CameraException catch (error) {
      setState(() {
        _isRecording = false;
        _errorMessage = 'Unable to start recording: ${error.description ?? error.code}';
      });
      return;
    }

    _startDurationTicker();
    await _runActionPrompts();

    XFile? recording;
    try {
      recording = await controller.stopVideoRecording();
    } on CameraException catch (error) {
      setState(() {
        _errorMessage =
            'Recording stopped unexpectedly: ${error.description ?? error.code}';
      });
    } finally {
      _stopDurationTicker();
      setState(() {
        _isRecording = false;
      });
    }

    if (!mounted || recording == null) {
      return;
    }

    await _submitRecording(recording);
  }

  Future<void> _runActionPrompts() async {
    for (var i = 0; i < widget.requiredActions.length; i++) {
      if (!mounted) return;

      setState(() {
        _currentActionIndex = i;
      });

      await Future<void>.delayed(const Duration(seconds: 3));
      _completedActions.add(widget.requiredActions[i]);
    }

    if (!mounted) return;

    setState(() {
      _currentActionIndex = widget.requiredActions.length;
    });
  }

  Future<void> _submitRecording(XFile recording) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      final bytes = await recording.readAsBytes();
      final submission = NinLivenessSubmission(
        nin: widget.nin,
        videoBytes: bytes,
        fileName: recording.name,
        duration: _recordingDuration,
        actions: widget.requiredActions,
      );

      await ref
          .read(ninLivenessControllerProvider.notifier)
          .verify(submission);

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit recording: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildCameraPreview() {
    if (_permissionStatus != null && !_permissionStatus!.isGranted) {
      return _PermissionRequestView(
        onOpenSettings: openAppSettings,
      );
    }

    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _ErrorView(
        message: _errorMessage!,
        onRetry: _requestPermissionAndInitialize,
      );
    }

    final controller = _cameraController;
    if (controller == null ||
        _initializeControllerFuture == null ||
        !controller.value.isInitialized) {
      return const Center(child: Text('Preparing camera...'));
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        FutureBuilder<void>(
          future: _initializeControllerFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            return AspectRatio(
              aspectRatio: controller.value.aspectRatio,
              child: CameraPreview(controller),
            );
          },
        ),
        if (_isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
      ],
    );
  }

  Widget _buildActionStepper() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widget.requiredActions.asMap().entries.map((entry) {
        final index = entry.key;
        final action = entry.value;
        final isCurrent = _isRecording && _currentActionIndex == index;
        final isCompleted = _completedActions.contains(action);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isCurrent
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.surfaceVariant,
          ),
          child: Row(
            children: [
              Icon(
                isCompleted
                    ? Icons.check_circle
                    : isCurrent
                        ? Icons.play_circle
                        : Icons.radio_button_unchecked,
                color: isCompleted
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  action.instruction,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canStartRecording =
        !_isRecording && !_isProcessing && _permissionStatus?.isGranted == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capture Liveness'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: _buildCameraPreview(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Follow the prompts below while keeping your face inside the frame.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _buildActionStepper(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: Icon(_isRecording ? Icons.stop : Icons.videocam),
                      onPressed: canStartRecording ? _startRecording : null,
                      label: Text(_isRecording ? 'Recording…' : 'Start Recording'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isRecording || _isProcessing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isProcessing ? 'Uploading for verification…' : 'Recording in progress…',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(_recordingDuration),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _PermissionRequestView extends StatelessWidget {
  const _PermissionRequestView({required this.onOpenSettings});

  final Future<bool> Function() onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Camera permission is required to continue.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onOpenSettings,
              child: const Text('Open Settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
