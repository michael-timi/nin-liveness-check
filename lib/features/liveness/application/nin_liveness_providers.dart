import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources/nin_liveness_api_client.dart';
import '../data/repositories/fake_nin_liveness_repository.dart';
import '../data/repositories/remote_nin_liveness_repository.dart';
import '../domain/repositories/nin_liveness_repository.dart';
import 'nin_liveness_controller.dart';
import 'nin_liveness_state.dart';

class NinLivenessConfig {
  const NinLivenessConfig({
    required this.baseUrl,
    this.useMock = true,
    this.requestTimeout,
  });

  final String baseUrl;
  final bool useMock;
  final Duration? requestTimeout;

  NinLivenessConfig copyWith({
    String? baseUrl,
    bool? useMock,
    Duration? requestTimeout,
  }) {
    return NinLivenessConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      useMock: useMock ?? this.useMock,
      requestTimeout: requestTimeout ?? this.requestTimeout,
    );
  }
}

final ninLivenessConfigProvider = Provider<NinLivenessConfig>((ref) {
  return const NinLivenessConfig(
    baseUrl: 'https://api.your-backend.dev',
    useMock: true,
    requestTimeout: Duration(seconds: 30),
  );
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(ninLivenessConfigProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: config.requestTimeout ?? const Duration(seconds: 25),
      receiveTimeout: config.requestTimeout ?? const Duration(seconds: 25),
      headers: const {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(InterceptorsWrapper(
    onError: (error, handler) {
      handler.next(
        DioException(
          error: error.error,
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          message: error.message ?? 'Network error occurred.',
        ),
      );
    },
  ));

  return dio;
});

final ninLivenessRepositoryProvider = Provider<NinLivenessRepository>((ref) {
  final config = ref.watch(ninLivenessConfigProvider);

  if (config.useMock) {
    return FakeNinLivenessRepository();
  }

  final dio = ref.watch(dioProvider);
  final apiClient = NinLivenessApiClient(dio, baseUrl: config.baseUrl);

  return RemoteNinLivenessRepository(apiClient);
});

final ninLivenessControllerProvider =
    StateNotifierProvider<NinLivenessController, NinLivenessState>(
  (ref) {
    final repository = ref.watch(ninLivenessRepositoryProvider);
    return NinLivenessController(repository);
  },
);
