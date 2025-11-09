import 'package:meta/meta.dart';

import '../entities/liveness_action.dart';

@immutable
class NinLivenessSubmission {
  const NinLivenessSubmission({
    required this.nin,
    required this.videoBytes,
    required this.fileName,
    required this.duration,
    required this.actions,
  });

  final String nin;
  final List<int> videoBytes;
  final String fileName;
  final Duration duration;
  final List<LivenessAction> actions;

  Map<String, dynamic> toJson() => {
        'nin': nin,
        'duration_seconds': duration.inSeconds,
        'actions': actions.map((action) => action.name).toList(),
      };

  NinLivenessSubmission copyWith({
    String? nin,
    List<int>? videoBytes,
    String? fileName,
    Duration? duration,
    List<LivenessAction>? actions,
  }) {
    return NinLivenessSubmission(
      nin: nin ?? this.nin,
      videoBytes: videoBytes ?? this.videoBytes,
      fileName: fileName ?? this.fileName,
      duration: duration ?? this.duration,
      actions: actions ?? this.actions,
    );
  }
}
