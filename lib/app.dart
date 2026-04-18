/// Flow Finance - A Modern Personal Finance App
/// 
/// This is the main entry point for the redesigned application.
/// The app features a clean architecture with:
/// 
/// - Core: Theme system, widgets, and utilities
/// - Presentation: Screens and UI components
/// - Data: Database and repositories (preserved from original)
/// 
/// Design System:
/// - Colors: Indigo primary, Teal secondary
/// - Typography: Inter font family
/// - Shadows: Soft, modern elevation system
/// - Animations: Smooth, consistent motion

library flow_finance;

// Core
export 'core/theme/theme.dart';
export 'core/widgets/widgets.dart';

// Presentation
export 'presentation/screens/home/home_screen.dart';
export 'presentation/screens/transactions/transactions_screen.dart';
export 'presentation/screens/add_transaction/add_transaction_screen.dart';
export 'presentation/screens/budgets/budgets_screen.dart';
export 'presentation/screens/settings/settings_screen.dart';
