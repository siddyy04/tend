import 'package:my_first_app/ai/providers/extraction_provider.dart';
import 'package:my_first_app/data/local/isar/collections/person.dart';

/// Null-object [ExtractionProvider] for devices / phases without a local model.
///
/// Returns zero candidates so callers can fall back to manual entry.
/// Does not import or depend on any vendor AI SDK.
class ManualFallbackProvider implements ExtractionProvider {
  const ManualFallbackProvider();

  @override
  Future<ExtractionResult> extract({
    required String text,
    required List<Person> knownPeople,
  }) async {
    return const ExtractionResult(candidates: []);
  }
}
