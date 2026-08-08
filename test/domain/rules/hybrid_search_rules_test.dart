import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/ai/providers/search/search_provider.dart';
import 'package:my_first_app/core/constants/enums.dart';
import 'package:my_first_app/domain/rules/hybrid_search_rules.dart';

SearchHit _hit(String uuid) {
  return SearchHit(
    memoryUuid: uuid,
    personUuid: 'p1',
    personName: 'Ada',
    eventText: 'hello',
    snippet: 'hello',
    category: MemoryCategory.hobbies,
    dateValue: null,
    dateValueRaw: null,
    datePrecision: DatePrecision.none,
    matchKind: MatchKind.partial,
    matchedInEventText: true,
  );
}

void main() {
  test('composeHybridTiers keeps tier1 order and dedupes tier2', () {
    final tier1 = [_hit('a'), _hit('b')];
    final tier2 = [_hit('b'), _hit('c')];
    final result = composeHybridTiers(tier1: tier1, tier2Candidates: tier2);
    expect(result.tier1.map((h) => h.memoryUuid), ['a', 'b']);
    expect(result.tier2.map((h) => h.memoryUuid), ['c']);
  });
}
