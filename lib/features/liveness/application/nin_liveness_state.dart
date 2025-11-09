import '../domain/models/nin_liveness_result.dart';

enum NinLivenessStatus { idle, submitting, success, failure }

class NinLivenessState {
  const NinLivenessState({
    this.status = NinLivenessStatus.idle,
    this.result,
    this.errorMessage,
  });

  final NinLivenessStatus status;
  final NinLivenessResult? result;
  final String? errorMessage;

  bool get isSubmitting => status == NinLivenessStatus.submitting;
  bool get hasResult => result != null;

  NinLivenessState copyWith({
    NinLivenessStatus? status,
    NinLivenessResult? result,
    String? errorMessage,
    bool resetResult = false,
    bool resetError = false,
  }) {
    return NinLivenessState(
      status: status ?? this.status,
      result: resetResult ? null : result ?? this.result,
      errorMessage: resetError ? null : errorMessage ?? this.errorMessage,
    );
  }
}
