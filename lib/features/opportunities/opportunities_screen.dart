import 'package:flutter/material.dart';

/// Today's Opportunities placeholder — no suggestion logic this sprint.
class OpportunitiesScreen extends StatelessWidget {
  const OpportunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: const Center(
        child: Text('Coming soon'),
      ),
    );
  }
}
