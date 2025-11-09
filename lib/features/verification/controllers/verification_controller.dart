import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/api/mock_verification_api.dart';
import '../models/verification_models.dart';

class VerificationController extends ChangeNotifier {
  VerificationController()
      : _api = MockVerificationApi(),
        _secureStorage = const FlutterSecureStorage();

  final MockVerificationApi _api;
  final FlutterSecureStorage _secureStorage;

  VerificationStep _step = VerificationStep.ninEntry;
  VerificationSession? _session;
  VerificationResult? _result;
  String? _nin;
  String? _errorMessage;
  bool _hasCameraPermission = false;
  bool _isProcessing = false;
  int _currentPromptIndex = 0;

  VerificationStep get step => _step;
  VerificationSession? get session => _session;
  VerificationResult? get result => _result;
  String? get nin => _nin;
  String? get errorMessage => _errorMessage;
  bool get hasCameraPermission => _hasCameraPermission;
  bool get isProcessing => _isProcessing;
  int get currentPromptIndex => _currentPromptIndex;
  LivenessPrompt? get currentPrompt =>
      (_session == null || _session!.prompts.isEmpty)
          ? null
          : _session!.prompts[_currentPromptIndex];

  Future<void> submitNin(String nin) async {
    if (nin.length != 11 || int.tryParse(nin) == null) {
      _setInlineError('Enter a valid 11-digit NIN.');
      return;
    }

    _setLoading(true);
    try {
      _errorMessage = null;
      _nin = nin;
      final session = await _api.createSession(nin: nin);
      _session = session;

      await _secureStorage.write(key: 'nin_session_id', value: session.sessionId);

      _step = VerificationStep.consent;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _setError('Unable to start verification: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> requestPermissions() async {
    _setLoading(true);
    try {
      final cameraStatus = await Permission.camera.request();
      final microphoneStatus = await Permission.microphone.request();

      if (cameraStatus.isGranted && microphoneStatus.isGranted) {
        _hasCameraPermission = true;
        _step = VerificationStep.capture;
        _errorMessage = null;
        notifyListeners();
      } else {
        _hasCameraPermission = false;
        _setInlineError('Camera and microphone permissions are required.');
      }
    } finally {
      _setLoading(false);
    }
  }

  void markPromptCompleted() {
    if (_session == null) {
      return;
    }
    if (_currentPromptIndex < _session!.prompts.length - 1) {
      _currentPromptIndex += 1;
      notifyListeners();
    }
  }

  Future<void> submitEvidence({
    required Uint8List selfieBytes,
    required Map<String, dynamic> metadata,
  }) async {
    if (_session == null) {
      _setError('No active session. Restart the flow.');
      return;
    }

    _step = VerificationStep.uploading;
    _setLoading(true);

    try {
      await _api.uploadEvidence(
        sessionId: _session!.sessionId,
        selfieBytes: selfieBytes,
        metadata: metadata,
      );

      final result = await _api.fetchResult(sessionId: _session!.sessionId);
      _result = result;
      _step = VerificationStep.result;
    } catch (e) {
      _setError('Upload failed: $e');
      _step = VerificationStep.failure;
    } finally {
      _setLoading(false);
    }
  }

  void retry() {
    _result = null;
    _session = null;
    _nin = null;
    _currentPromptIndex = 0;
    _hasCameraPermission = false;
    _errorMessage = null;
    _step = VerificationStep.ninEntry;
    notifyListeners();
  }

  void acknowledgeFailure() {
    _step = VerificationStep.ninEntry;
    _result = null;
    _session = null;
    _nin = null;
    _currentPromptIndex = 0;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isProcessing = loading;
    notifyListeners();
  }

  void _setInlineError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    _step = VerificationStep.failure;
    notifyListeners();
  }
}
