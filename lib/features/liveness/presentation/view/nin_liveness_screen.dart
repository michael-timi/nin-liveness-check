import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/nin_liveness_providers.dart';
import '../../application/nin_liveness_state.dart';
import '../../domain/entities/liveness_action.dart';
import '../../domain/models/nin_liveness_result.dart';
import 'nin_liveness_capture_screen.dart';

class NinLivenessScreen extends ConsumerStatefulWidget {
  const NinLivenessScreen({super.key});

  @override
  ConsumerState<NinLivenessScreen> createState() => _NinLivenessScreenState();
}

class _NinLivenessScreenState extends ConsumerState<NinLivenessScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ninController = TextEditingController();
  final List<LivenessAction> _requiredActions = List.unmodifiable(LivenessAction.values);

  @override
  void initState() {
    super.initState();
    ref.listen<NinLivenessState>(
      ninLivenessControllerProvider,
      (previous, next) {
        if (previous?.status == next.status) return;
        final messenger = ScaffoldMessenger.of(context);

        if (next.status == NinLivenessStatus.success) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Liveness verification completed successfully.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else if (next.status == NinLivenessStatus.failure) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(next.errorMessage ?? 'Liveness verification failed.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _ninController.dispose();
    super.dispose();
  }

  void _startCaptureFlow() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NinLivenessCaptureScreen(
          nin: _ninController.text.trim(),
          requiredActions: _requiredActions,
        ),
      ),
    );
  }

  void _resetVerification() {
    ref.read(ninLivenessControllerProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ninLivenessControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('NIN Liveness Verification'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  'Verify your identity in three quick steps. Your recording never leaves your device without your consent.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _ninController,
                  decoration: const InputDecoration(
                    labelText: 'National Identification Number (NIN)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 11,
                  validator: (value) {
                    final nin = value?.trim() ?? '';
                    if (nin.isEmpty) {
                      return 'Please enter your NIN.';
                    }
                    if (nin.length != 11) {
                      return 'NIN must be 11 digits.';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(nin)) {
                      return 'NIN should contain digits only.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Liveness Checklist',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ..._requiredActions
                    .map(
                      (action) => Card(
                        child: ListTile(
                          leading: const Icon(Icons.check_circle_outline),
                          title: Text(action.instruction),
                          subtitle: const Text('You will be prompted during capture.'),
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: state.isSubmitting ? null : _startCaptureFlow,
                  icon: const Icon(Icons.videocam),
                  label: const Text('Start Liveness Capture'),
                ),
                if (state.status == NinLivenessStatus.submitting) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                ],
                if (state.status == NinLivenessStatus.success && state.result != null) ...[
                  const SizedBox(height: 24),
                  _SuccessResultCard(result: state.result!),
                ],
                if (state.status == NinLivenessStatus.failure) ...[
                  const SizedBox(height: 24),
                  _ErrorResultCard(message: state.errorMessage),
                ],
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: state.hasResult || state.status == NinLivenessStatus.failure
          ? FloatingActionButton.extended(
              onPressed: _resetVerification,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset'),
            )
          : null,
    );
  }
}

class _SuccessResultCard extends StatelessWidget {
  const _SuccessResultCard({required this.result});

  final NinLivenessResult result;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Liveness Confirmed',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 12),
            _ResultTile(
              label: 'Confidence',
              value: '${(result.confidenceScore * 100).toStringAsFixed(1)}%',
            ),
            _ResultTile(
              label: 'Reference ID',
              value: result.referenceId,
            ),
            _ResultTile(
              label: 'Verified At',
              value: result.verifiedAt.toLocal().toString(),
            ),
            const SizedBox(height: 12),
            Text(
              result.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorResultCard extends StatelessWidget {
  const _ErrorResultCard({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verification Failed',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'We could not verify liveness. Please retry the capture.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.labelMedium,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
