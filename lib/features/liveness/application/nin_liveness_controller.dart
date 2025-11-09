import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/exceptions/app_exception.dart';
import '../domain/models/nin_liveness_submission.dart';
import '../domain/repositories/nin_liveness_repository.dart';
import 'nin_liveness_state.dart';

class NinLivenessController extends StateNotifier<NinLivenessState> {
  NinLivenessController(this._repository) : super(const NinLivenessState());

  final NinLivenessRepository _repository;

  Future<void> verify(NinLivenessSubmission submission) async {
    state = state.copyWith(
      status: NinLivenessStatus.submitting,
      resetError: true,
      resetResult: true,
    );

    try {
      final result = await _repository.verifyLiveness(submission);
      state = state.copyWith(
        status: NinLivenessStatus.success,
        result: result,
        resetError: true,
      );
    } on AppException catch (error) {
      state = state.copyWith(
        status: NinLivenessStatus.failure,
        errorMessage: error.message,
        resetResult: true,
      );
    } catch (error) {
      state = state.copyWith(
        status: NinLivenessStatus.failure,
        errorMessage: 'An unexpected error occurred. Please try again.',
        resetResult: true,
      );
    }
  }

  void reset() {
    state = const NinLivenessState();
  }
}
