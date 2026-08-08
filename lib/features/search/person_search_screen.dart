import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_first_app/features/person_profile/person_profile_providers.dart';
import 'package:my_first_app/features/search/search_controller.dart';
import 'package:my_first_app/features/search/search_screen.dart';

/// Person-scoped keyword Search — entered from Person Profile.
class PersonSearchScreen extends ConsumerWidget {
  const PersonSearchScreen({
    super.key,
    required this.personUuid,
  });

  final String personUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(profilePersonProvider(personUuid));
    final personName = personAsync.asData?.value?.name;
    final title = personName == null || personName.isEmpty
        ? 'Search'
        : 'Search · $personName';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SearchView(
        args: SearchControllerArgs.person(personUuid),
        personName: personName,
      ),
    );
  }
}
