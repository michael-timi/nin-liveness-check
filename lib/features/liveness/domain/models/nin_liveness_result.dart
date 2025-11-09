import 'package:meta/meta.dart';

@immutable
class NinLivenessResult {
  const NinLivenessResult({
    required this.isLive,
    required this.confidenceScore,
    required this.referenceId,
    required this.message,
    required this.verifiedAt,
  });

  final bool isLive;
  final double confidenceScore;
  final String referenceId;
  final String message;
  final DateTime verifiedAt;
}
