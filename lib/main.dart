import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/auto_transfer_service.dart';
import 'core/services/premium_service.dart';
import 'core/services/smart_rules_engine.dart';
import 'core/theme/app_theme.dart';
import 'data/database/database.dart';
import 'data/repositories/budget_repository.dart';
import 'data/repositories/family_repository.dart';
import 'data/repositories/goal_repository.dart';
import 'data/repositories/recurring_transaction_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'data/repositories/transaction_repository.dart';
import 'data/repositories/wallet_repository.dart';
import 'firebase_options.dart';
import 'presentation/blocs/budget_bloc.dart';
import 'presentation/blocs/premium_controller.dart';
import 'presentation/blocs/settings_controller.dart';
import 'presentation/blocs/transaction_bloc.dart';
import 'presentation/blocs/wallet_bloc.dart';
import 'presentation/screens/navigation/main_navigation_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Localization
  await EasyLocalization.ensureInitialized();

  // System UI
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Core dependencies
  final prefs = await SharedPreferences.getInstance();
  final database = AppDatabase();
  final settingsRepo = SettingsRepository(database);
  final transactionRepo = TransactionRepository(database);
  final walletRepo = WalletRepository(database);
  final budgetRepo = BudgetRepository(database);
  final recurringRepo = RecurringTransactionRepository(prefs);
  final goalRepo = GoalRepository(settingsRepo);
  final familyRepo = FamilyRepository(prefs);
  final smartRules = SmartRulesEngine(settingsRepo);
  final autoTransfer = AutoTransferService(settingsRepo);
  final premiumService = PremiumService();

  // Check if onboarding has been seen
  final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ta')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          // Repositories
          Provider<SettingsRepository>.value(value: settingsRepo),
          Provider<TransactionRepository>.value(value: transactionRepo),
          Provider<WalletRepository>.value(value: walletRepo),
          Provider<BudgetRepository>.value(value: budgetRepo),
          Provider<RecurringTransactionRepository>.value(value: recurringRepo),
          Provider<GoalRepository>.value(value: goalRepo),
          Provider<FamilyRepository>.value(value: familyRepo),

          // BLoCs / Controllers
          ChangeNotifierProvider<SettingsController>(
            create: (_) => SettingsController(settingsRepo)..load(),
          ),
          ChangeNotifierProvider<WalletBloc>(
            create: (_) => WalletBloc(walletRepo)..loadWallets(),
          ),
          ChangeNotifierProvider<TransactionBloc>(
            create: (_) => TransactionBloc(
              transactionRepo,
              walletRepo,
              smartRules,
              autoTransfer,
              recurringRepo,
            )..loadTransactions(),
          ),
          ChangeNotifierProvider<BudgetBloc>(
            create: (_) => BudgetBloc(budgetRepo, transactionRepo)
              ..loadBudgets(),
          ),
          ChangeNotifierProvider<PremiumController>(
            create: (_) => PremiumController(premiumService),
          ),
        ],
        child: FlowFinanceApp(seenOnboarding: seenOnboarding),
      ),
    ),
  );
}

class FlowFinanceApp extends StatelessWidget {
  final bool seenOnboarding;

  const FlowFinanceApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    final settingsController = context.watch<SettingsController>();

    return MaterialApp(
      title: 'Flow Finance',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: settingsController.themeMode,
      home: seenOnboarding
          ? const MainNavigationScreen()
          : const OnboardingScreen(),
    );
  }
}
