import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core
import 'core/services/notification_service.dart';
import 'core/services/firebase_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/services/smart_rules_engine.dart';
import 'core/services/auto_transfer_service.dart';

// Data
import 'data/database/database_exports.dart';
import 'data/repositories/repositories.dart';
import 'data/repositories/family_repository.dart';

// BLoCs
import 'presentation/blocs/blocs.dart';

// Screens
import 'presentation/screens/navigation/main_navigation_screen.dart';
import 'presentation/screens/onboarding/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  await Firebase.initializeApp();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ta')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      child: FlowFinanceApp(sharedPreferences: sharedPreferences),
    ),
  );
}

/// Main app widget with integrated state management
class FlowFinanceApp extends StatelessWidget {
  const FlowFinanceApp({
    super.key,
    required this.sharedPreferences,
  });

  final SharedPreferences sharedPreferences;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Database
        Provider(create: (_) => AppDatabase()),
        Provider.value(value: sharedPreferences),

        // Repositories
        ProxyProvider<AppDatabase, TransactionRepository>(
          update: (_, db, __) => TransactionRepository(db),
        ),
        ProxyProvider<AppDatabase, BudgetRepository>(
          update: (_, db, __) => BudgetRepository(db),
        ),
        ProxyProvider<AppDatabase, SettingsRepository>(
          update: (_, db, __) => SettingsRepository(db),
        ),
        ProxyProvider<AppDatabase, WalletRepository>(
          update: (_, db, __) => WalletRepository(db),
        ),
        ProxyProvider<AppDatabase, GoalRepository>(
          update: (_, db, __) => GoalRepository(SettingsRepository(db)),
        ),
        ProxyProvider<SharedPreferences, FamilyRepository>(
          update: (_, prefs, __) => FamilyRepository(prefs),
        ),
        ProxyProvider<SharedPreferences, RecurringTransactionRepository>(
          update: (_, prefs, __) => RecurringTransactionRepository(prefs),
        ),

        // Repositories and Services
        ProxyProvider<SettingsRepository, SmartRulesEngine>(
          update: (_, settingsRepo, __) => SmartRulesEngine(settingsRepo),
        ),
        ProxyProvider<SettingsRepository, AutoTransferService>(
          update: (_, settingsRepo, __) => AutoTransferService(settingsRepo),
        ),

        // BLoCs
        ChangeNotifierProvider(
          create: (context) => TransactionBloc(
            context.read<TransactionRepository>(),
            context.read<WalletRepository>(),
            context.read<SmartRulesEngine>(),
            context.read<AutoTransferService>(),
            context.read<RecurringTransactionRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => BudgetBloc(
            context.read<BudgetRepository>(),
            context.read<TransactionRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => WalletBloc(
            context.read<WalletRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => SettingsController(
            context.read<SettingsRepository>(),
          )..load(),
        ),
      ],
      child: Consumer<SettingsController>(
        builder: (context, settings, child) => MaterialApp(
          title: 'Flow Finance'.tr(),
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: settings.themeMode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: settings.languageCode == 'ta'
              ? const Locale('ta')
              : const Locale('en'),
          home: AppInitializer(sharedPreferences: sharedPreferences),
        ),
      ),
    );
  }
}

/// App initializer to load data on startup
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key, required this.sharedPreferences});

  final SharedPreferences sharedPreferences;

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  bool _isLoading = true;
  String? _error;
  String? _errorDetails;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final notifications = NotificationService();
      final firebaseNotifications = FirebaseNotificationService();
      try {
        await notifications.initialize();
        await firebaseNotifications.initialize();
      } catch (e) {
        debugPrint('Notification initialization failed: $e');
      }

      // Load initial data
      final transactionBloc = context.read<TransactionBloc>();
      final budgetBloc = context.read<BudgetBloc>();
      final settings = context.read<SettingsController>();

      await Future.wait([
        transactionBloc.loadTransactions(),
        budgetBloc.loadBudgets(),
        settings.isLoading ? settings.load() : Future<void>.value(),
      ]);

      // Process due recurring transactions
      final recurringCount = await transactionBloc.processDueRecurringTransactions();
      if (recurringCount > 0) {
        debugPrint('Processed $recurringCount due recurring transactions');
      }

      if (settings.settings.notificationsEnabled) {
        try {
          await notifications.requestPermissions();
          await notifications.scheduleDailyBudgetCheck();
          await notifications.scheduleWeeklySummary();
        } catch (e) {
          debugPrint('Notification scheduling failed: $e');
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('App initialization failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _error = 'Failed to initialize app'.tr();
          _errorDetails = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<SettingsController>();
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withOpacity(0.1),
                AppColors.backgroundLight,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.8, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeInOut,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Text(
                  'Flow Finance'.tr(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              if (_errorDetails != null) ...[
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _errorDetails!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondaryLight,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                    _errorDetails = null;
                  });
                  _initializeApp();
                },
                child: Text('Retry'.tr()),
              ),
            ],
          ),
        ),
      );
    }

    final seenOnboarding = widget.sharedPreferences.getBool('seen_onboarding') ?? false;
    return seenOnboarding ? MainNavigationScreen() : OnboardingScreen();
  }
}
