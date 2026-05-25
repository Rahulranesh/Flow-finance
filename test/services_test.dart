import 'package:flutter_test/flutter_test.dart';
import 'package:flow_finance/core/services/smart_rules_engine.dart';
import 'package:flow_finance/core/services/auto_transfer_service.dart';
import 'package:flow_finance/data/repositories/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  final Map<String, String> _storage = {};

  @override
  Future<String?> getString(String key) async {
    return _storage[key];
  }

  @override
  Future<void> setString(String key, String value) async {
    _storage[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SmartRulesEngine Tests', () {
    late FakeSettingsRepository settingsRepository;
    late SmartRulesEngine rulesEngine;

    setUp(() {
      settingsRepository = FakeSettingsRepository();
      rulesEngine = SmartRulesEngine(settingsRepository);
    });

    test('addRule persists rules in SettingsRepository', () async {
      final rule = SmartRule(
        id: 'rule_1',
        name: 'Test Rule',
        type: RuleType.categorization,
        conditions: [
          RuleCondition(
            field: TransactionField.title,
            operator: ConditionOperator.contains,
            value: 'salary',
          )
        ],
        actions: [
          RuleAction(
            type: ActionType.setCategory,
            value: 'Income',
          )
        ],
        createdAt: DateTime.now(),
      );

      rulesEngine.addRule(rule);

      // Verify rule was added to in-memory list
      expect(rulesEngine.getRules().length, 1);
      expect(rulesEngine.getRules().first.name, 'Test Rule');

      // Allow async saving to complete
      await Future.delayed(Duration.zero);

      // Re-instantiate the engine with the same settings repository
      final newEngine = SmartRulesEngine(settingsRepository);
      
      // Allow async loading to complete
      await Future.delayed(Duration.zero);

      expect(newEngine.getRules().length, 1);
      expect(newEngine.getRules().first.name, 'Test Rule');
      expect(newEngine.getRules().first.id, 'rule_1');
    });
  });

  group('AutoTransferService Tests', () {
    late FakeSettingsRepository settingsRepository;
    late AutoTransferService transferService;

    setUp(() {
      settingsRepository = FakeSettingsRepository();
      transferService = AutoTransferService(settingsRepository);
    });

    test('addAutoTransferRule persists rules in SettingsRepository', () async {
      final rule = AutoTransferRule(
        id: 'transfer_rule_1',
        name: 'Weekly savings',
        trigger: TransferTrigger(type: TriggerType.incomeReceived),
        sourceWalletId: 'w1',
        destinationWalletId: 'w2',
        calculationType: CalculationType.fixedAmount,
        amount: 50.0,
        createdAt: DateTime.now(),
      );

      transferService.addAutoTransferRule(rule);

      expect(transferService.rules.length, 1);
      expect(transferService.rules.first.name, 'Weekly savings');

      await Future.delayed(Duration.zero);

      // Re-instantiate the service with the same settings repository
      final newService = AutoTransferService(settingsRepository);
      await Future.delayed(Duration.zero);

      expect(newService.rules.length, 1);
      expect(newService.rules.first.name, 'Weekly savings');
      expect(newService.rules.first.id, 'transfer_rule_1');
    });

    test('addRoundUpRule persists rules in SettingsRepository', () async {
      final rule = RoundUpRule(
        id: 'roundup_rule_1',
        name: 'Spare change round up',
        roundUpTo: RoundUpTo.nearestDollar,
        sourceWalletId: 'w1',
        savingsWalletId: 'w2',
        createdAt: DateTime.now(),
      );

      transferService.addRoundUpRule(rule);

      expect(transferService.roundUpRules.length, 1);
      expect(transferService.roundUpRules.first.name, 'Spare change round up');

      await Future.delayed(Duration.zero);

      // Re-instantiate the service with the same settings repository
      final newService = AutoTransferService(settingsRepository);
      await Future.delayed(Duration.zero);

      expect(newService.roundUpRules.length, 1);
      expect(newService.roundUpRules.first.name, 'Spare change round up');
      expect(newService.roundUpRules.first.id, 'roundup_rule_1');
    });
  });
}
