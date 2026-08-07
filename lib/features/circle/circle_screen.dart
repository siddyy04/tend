import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_controller.dart';

/// My Circle screen — UI shell only for this step.
///
/// Person list / empty-state query wiring comes in a later Sprint 0 step.
/// No Person CRUD here.
///
/// Temporary Sprint 0 developer logout lives in the AppBar and can move later.
class CircleScreen extends ConsumerWidget {
  const CircleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Circle'),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
      body: const Center(
        child: Text('My Circle'),
      ),
    );
  }
}
