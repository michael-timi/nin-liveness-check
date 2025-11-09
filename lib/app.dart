import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'features/verification/controllers/verification_controller.dart';
import 'features/verification/views/verification_flow_screen.dart';

class NinLivenessApp extends StatelessWidget {
  const NinLivenessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => VerificationController(),
        ),
      ],
      child: MaterialApp(
        title: 'NIN Liveness Verification',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          useMaterial3: true,
        ),
        home: const VerificationFlowScreen(),
      ),
    );
  }
}
