# Flow Finance — Complete App Documentation

> **Version:** 5.4.4+417 | **Platform:** Android & iOS (Flutter) | **App Name:** *Flow Finance*


---

## 1. Overview

Flow Finance is a modern, offline-first personal finance management application built with Flutter. It helps users track expenses, manage budgets, set savings goals, automate finances with smart rules, and gain AI-powered insights — all with a premium Cupertino-native UI and a playful mascot companion.

### 1.1 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.x (Dart SDK ≥3.0.0) |
| **Database** | Drift (SQLite) — offline-first, no server required |
| **State Management** | Provider + ChangeNotifier (BLoC-like pattern) |
| **Localization** | easy_localization (English & Tamil) |
| **Auth** | Firebase Auth + Google Sign-In |
| **Backend** | Firebase (Firestore, Cloud Messaging, Core) |
| **Ads** | Google Mobile Ads (AdMob) |
| **Charts** | fl_chart |
| **Animations** | Lottie, Shimmer, simple_animations |
| **Biometrics** | local_auth |
| **Notifications** | flutter_local_notifications, firebase_messaging |
| **Payments** | in_app_purchase |
| **Export** | PDF (pdf + printing), CSV, Share Plus |
| **SMS Parsing** | telepathy + notification_listener_service |
| **Bank Integration** | Plaid, Truelayer, UPI SMS parsers |
| **Auto Formatting** | auto_size_text, intl (NumberFormat/DateFormat) |
| **Home Widget** | home_widget (iOS/Android home screen widgets) |

---

## 2. Architecture

### 2.1 Directory Structure

```
lib/
├── core/                    # Shared code
│   ├── models/              # Bank account, transaction, date range models
│   ├── services/            # All services (AI, auth, SMS, export, etc.)
│   │   ├── bank_integration/# Plaid, Truelayer, UPI parsers
│   │   └── secure/          # Encryption, token management
│   ├── theme/               # Colors, typography, shadows, animations
│   ├── utils/               # Extensions, animation helpers
│   ├── validators/          # Form validators
│   └── widgets/             # Shared widgets (buttons, inputs, toast, etc.)
├── data/
│   ├── database/            # Drift schema (6 tables) + generated code
│   ├── models/              # Domain models (transaction, budget, wallet, etc.)
│   └── repositories/        # Data access layer
└── presentation/
    ├── blocs/               # State management (4 controllers)
    ├── screens/             # 15+ screen files across feature folders
    └── widgets/             # Screen-specific widgets (charts, sheets, filters)
```

### 2.2 State Management Pattern

Each feature area has a dedicated `ChangeNotifier` (called "BLoC" in code):

| Bloc | Responsibility |
|------|---------------|
| **TransactionBloc** | CRUD transactions, filtering, search, recurring processing, balance computation |
| **BudgetBloc** | Budget CRUD, spending progress tracking |
| **WalletBloc** | Wallet CRUD, conversion, total balance |
| **SettingsController** | Theme, currency, language, biometrics, notifications |

Data flows: **UI → Bloc (ChangeNotifier) → Repository → Drift (SQLite)**

### 2.3 Database Schema (Drift — 6 Tables)

| Table | Key Fields |
|-------|-----------|
| **Transactions** | id, title, amount, type (income/expense/transfer), category, date, note, paymentMethod, isRecurring, recurringId, walletId, currency, exchangeRate |
| **Budgets** | id, categoryId, limit, period (daily/weekly/monthly/yearly), startDate, endDate, isActive |
| **Categories** | id, name, iconName, colorValue, budgetLimit, isDefault (10 seeded) |
| **Settings** | key-value store (theme, currency, language, etc.) |
| **Wallets** | id, name, type (cash/bank/creditCard/savings/investment/digital/other), currency, balance, color, isDefault, isArchived |
| **WalletTransfers** | id, fromWalletId, toWalletId, amount, exchangeRate, note, date |

---

## 3. Complete Feature List

### 3.1 Core Finance Features

#### 📝 Transaction Management
- Add income/expense/transfer transactions
- Category selection with visual icons and colors
- Multi-wallet support with currency conversion
- Date picker, notes, payment method
- Search transactions by title/category
- Filter by type (All/Income/Expense)
- Edit/delete transactions

#### 💰 Budget Management
- Create budgets per category
- Support for daily, weekly, monthly, yearly periods
- Visual progress bars with spending vs. limit
- Budget alerts (push notifications when exceeding)
- Overview screen showing all budgets

#### 👛 Multi-Wallet System
- Create wallets of various types (cash, bank, credit card, savings, investment, digital wallet)
- Each wallet can have its own currency (INR/USD)
- Balance tracking per wallet
- Transfers between wallets with exchange rate conversion
- Archival of unused wallets

#### 🎯 Savings Goals
- Create savings goals with target amount and deadline
- Visual progress tracking
- Goals grouped by status (active/completed)
- Confetti celebration on goal completion

#### 🔄 Recurring Transactions
- Set up recurring income/expense (daily, weekly, monthly, yearly)
- Auto-processing on app startup
- Separate screen showing all recurring items

#### 🤖 Smart Rules Engine
Client-side rules that auto-process transactions:
- **Categorize:** Auto-assign category based on title/amount keywords
- **Split:** Split a transaction into multiple categories
- **Flag:** Tag transactions matching certain criteria
- **Skip:** Auto-ignore certain transactions
- **Round-up:** Round up amounts and save the difference
Rules are evaluated in priority order.

#### 💸 Auto-Transfer Service
- **Round-up transfers:** Round up each expense and transfer spare change to savings
- **Fixed transfers:** Transfer a fixed amount periodically
- **Percentage transfers:** Transfer a percentage of income

#### 🔐 Security
- Biometric authentication (fingerprint/face) for app lock
- Encryption service for sensitive data
- Token management for API keys

### 3.2 AI & Analytics

#### 🧠 AI Insights Service
- **Spending anomaly detection:** Uses z-score analysis (2σ threshold) to flag unusual transactions
- **Spending forecast:** Predicts future spending using moving averages and trend analysis
- **Financial health score:** Weighted score based on savings rate, budget adherence, spending consistency
- **Top spending categories:** Identifies highest-spend areas
- **Anomaly severity:** Classifies as medium (2-3σ) or high (>3σ)

#### 📊 Analytics Screen
- Total income, expense, and net balance summary cards
- Interactive charts: cash flow timeline, category breakdown pie/bar
- Month-over-month comparison
- Top spending categories ranking

#### 📈 Reports Screen
- Comprehensive financial reports with date range filtering
- Category-wise analysis with percentages
- Average daily spending
- Top category identification
- Share/export reports

### 3.3 Bank Integration

#### 🏦 Bank Connect
- Connect bank accounts manually or via Plaid/Truelayer
- View linked bank accounts and their sync status
- Multi-bank support

#### 📱 UPI Transaction Sync
- Parse UPI SMS messages from 20+ Indian banks and UPI apps (Google Pay, PhonePe, Paytm, etc.)
- Auto-create transactions from SMS
- UPI transaction listing with status tracking

#### 💬 SMS Transaction Sync
- Read bank SMS messages from inbox
- Parse transaction details (amount, merchant, type)
- Auto-create expense/income entries
- Support for 20+ Indian banks

#### 🔄 Google Pay Sync
- Sync transactions from Google Pay notifications
- Parse Google Pay-specific SMS formats
- Auto-categorization

#### 🔁 Reconciliation Engine
- Match SMS transactions with manual entries
- Detect duplicates
- Status tracking (pending, matched, unmatched)

### 3.4 Notifications

#### 🔔 Push Notifications
- Daily budget check notifications
- Weekly spending summary
- Budget exceeded alerts
- Recurring transaction reminders
- Firebase Cloud Messaging for remote push
- Local notification scheduling

### 3.5 Data Management

#### 💾 Backup & Restore
- Export full database backup
- Import from backup files
- Secure storage of backups

#### 📤 Export
- Export transactions to CSV
- Export comprehensive PDF reports
- Share via system share sheet
- Custom date range exports

#### 📥 Import
- Import transactions from CSV files
- Field mapping and validation
- Duplicate detection

### 3.6 Family Sharing
- Family budget management
- Shared financial overview
- Multi-member support

### 3.7 Customization

#### 🎨 Theme System
- **Light/Dark/System mode** with automatic switching
- **Indigo/Teal 2025 palette** — modern, premium color scheme
- **6 custom font families:** Avenir, Inter, DMSans, Metropolis, RobotoCondensed, Inconsolata
- **Cupertino-native UI** — all Material widgets replaced with iOS equivalents
- **Flat design** — no shadows, subtle 0.5px borders
- **Warm near-white backgrounds** (#F2F2F7 iOS system background)

#### 🌐 Localization
- English (en) and Tamil (ta) language support
- RTL-aware layout
- On-the-fly language switching

#### 💱 Currency
- INR (₹) and USD ($) support
- Dynamic symbol switching throughout the app
- Exchange rate tracking for wallet conversions
- NumberFormat.currency() for proper formatting

### 3.8 Onboarding
- Name input
- Currency selection (INR/USD)
- Clean first-run setup flow

### 3.9 Advertising & Monetization
- AdMob banner ads
- AdMob interstitial ads
- In-app purchases (in_app_purchase package)
- Configurable ad units per environment

### 3.10 Home Screen Widget
- iOS/Android home screen widget (home_widget package)
- Quick balance glance

### 3.11 Quick Actions
- iOS quick actions (3D Touch / Haptic Touch)
- Android shortcuts

### 3.12 Automation
- Dedicated automation screen for managing smart rules
- Visual rule builder with conditions and actions
- Execution history tracking

### 3.13 Smart Categorization
- Auto-categorize transactions based on patterns
- Machine learning-inspired heuristic matching
- Learn from user corrections

### 3.14 Password/Note Management
- Attach notes to transactions
- Payment method tracking
- Tag support for additional metadata

---

## 4. UI/UX Specialities

### 4.1 Cupertino-Native Design
Every Material widget has been systematically replaced:
| Before | After |
|--------|-------|
| Scaffold + AppBar | CupertinoPageScaffold + CupertinoNavigationBar |
| ListTile | Custom Cupertino rows |
| AlertDialog | CupertinoAlertDialog |
| BottomSheet | CupertinoActionSheet / showCupertinoModalPopup |
| SnackBar | Custom CupertinoToast overlay |
| CircularProgressIndicator | CupertinoActivityIndicator |
| SwitchListTile | CupertinoSwitch rows |
| TextButton | CupertinoButton |
| PopupMenuButton | CupertinoActionSheet |
| DatePicker | CupertinoDatePicker modal |
| DropdownButtonFormField | CupertinoActionSheet selection |
| NumberPad | CupertinoTextField system keyboard |

### 4.2 Mascot Toast System
- Lottie-animated mascot character (`mascot.json`, 69 frames, ~3s)
- 4 types: success (green), error (red), warning (amber), info (blue)
- Gradient background with shimmer sweep animation
- Accent bar with per-type color coding
- Spring slide-down animation
- Haptic feedback per type
- Undo action support
- Overlay-based (works in any context, no ScaffoldMessenger needed)

### 4.3 Flow Mascot
- Animated bubble character in Home screen
- Contextual messages (spending tips, greetings)
- Multiple animation states

### 4.4 Charts & Visualizations
- **Cash Flow Chart:** Interactive line chart with touch tooltips
- **Category Pie Chart:** Donut chart with legend, percentage labels
- **Trend Chart:** Spending trends over time
- **Budget Progress Bars:** Animated, color-coded by percentage used
- **Goal Progress Rings:** Circular progress indicators

### 4.5 Premium Color Palette
```
Primary:   Indigo (#6366F1 → #4F46E5)
Secondary: Teal   (#14B8A6 → #0D9488)
Success:   Green  (#22C55E)
Warning:   Amber  (#F59E0B)
Error:     Red    (#EF4444)
Income:    Emerald (#10B981)
Expense:   Red    (#EF4444)

Background:   #F2F2F7 (iOS system)
Surface:      #FFFFFF
SurfaceVar:   #F8F8FA
Border:       #C6C6C8 (iOS thin separator)
```

---

## 5. Services Architecture

### 5.1 Core Services

| Service | File | Purpose |
|---------|------|---------|
| `CurrencyFormatter` | `core/services/currency_formatter.dart` | Central currency formatter using intl NumberFormat |
| `CurrencyService` | `core/services/currency_service.dart` | Exchange rates, multi-currency conversion |
| `SmartRulesEngine` | `core/services/smart_rules_engine.dart` | Rule evaluation (588 lines) |
| `AutoTransferService` | `core/services/auto_transfer_service.dart` | Round-up/fixed/percentage transfers |
| `AIInsightsService` | `core/services/ai_insights_service.dart` | Anomaly detection, forecasting, health scoring (493 lines) |
| `SmsTransactionService` | `core/services/sms_transaction_service.dart` | SMS inbox reading + parsing (647 lines) |
| `NotificationService` | `core/services/notification_service.dart` | Local notification scheduling |
| `FirebaseNotificationService` | `core/services/firebase_notification_service.dart` | FCM push handling |
| `BackupService` | `core/services/backup_service.dart` | Database backup/restore |
| `DataExportService` | `core/services/data_export_service.dart` | CSV/PDF export |
| `ImportService` | `core/services/import_service.dart` | CSV import |
| `PdfExportService` | `core/services/pdf_export_service.dart` | PDF report generation |
| `BudgetAlertService` | `core/services/budget_alert_service.dart` | Budget limit monitoring + alerts |
| `AdMobService` | `core/services/admob_service.dart` | Banner + interstitial ads |
| `ErrorHandler` | `core/services/error_handler.dart` | Centralized error handling + logging |
| `LoggerService` | `core/services/logger_service.dart` | Structured logging |
| `SmartCategorizationService` | `core/services/smart_categorization_service.dart` | Auto-categorization |
| `AuthService` | `core/services/auth_service.dart` | Firebase auth wrapper |
| `GooglePayService` | `core/services/google_pay_service.dart` | GPay sync |

### 5.2 Bank Integration Services

| Service | Purpose |
|---------|---------|
| `PlaidService` | Plaid API integration for bank connectivity |
| `TrueLayerService` | TrueLayer Open Banking integration |
| `UpiSmsParser` | Parse UPI SMS from 20+ Indian banks/apps |
| `UpiTransactionService` | UPI transaction management |
| `ReconciliationEngine` | Match SMS ↔ manual entries |
| `TransactionSyncEngine` | Bi-directional transaction sync |

### 5.3 Security Services

| Service | Purpose |
|---------|---------|
| `EncryptionService` | AES encryption for sensitive data |
| `TokenManager` | API token lifecycle management |

---

## 6. Key Implementation Details

### 6.1 Anomaly Detection Algorithm
```dart
// AIInsightsService uses z-score analysis:
zScore = (transaction.amount - categoryMean) / categoryStdDev
- zScore > 2.0  → Medium severity anomaly
- zScore > 3.0  → High severity anomaly
- Sorted by severity descending
```

### 6.2 Smart Rules Engine Architecture
- Rules stored as JSON in SharedPreferences via SettingsRepository
- Rules evaluated in priority order
- Each rule has: id, name, conditions (field + operator + value), action (type + params), priority, isEnabled
- Conditions support: title, amount, category, date, type fields
- Operators: equals, contains, greaterThan, lessThan, regex
- Actions: categorize, split, flag, skip, roundUp
- Execution history tracked with timestamps

### 6.3 Currency Formatting Chain
1. User sets currency in Settings → `SettingsController.updateCurrency()`
2. Calls `CurrencyFormatter.updateCurrency(code)`
3. All formatting goes through `CurrencyFormatter.format()` → `NumberFormat.currency(symbol:)`
4. `num.toCurrency()` and `String.toCurrency()` extensions delegate to `CurrencyFormatter`
5. No hardcoded `$` or `₹` in any display code — all dynamic

### 6.4 App Startup Flow
1. `main()` → EasyLocalization + Firebase init
2. `FlowFinanceApp` → MultiProvider with all repositories + BLoCs
3. `AppInitializer` → `_initializeApp()`:
   - Initialize notifications (local + FCM)
   - Initialize AdMob
   - Load transactions, budgets, settings in parallel
   - Process due recurring transactions
   - Schedule daily budget check + weekly summary notifications
4. Route to HomeScreen (or Onboarding on first launch)

### 6.5 Toast/Notification Architecture
```
context.showMascotSnackBar() → extensions.dart
    ↓
CupertinoToast.show() → Overlay-based widget (no ScaffoldMessenger)
    ↓
Type-specific gradient, shimmer, accent bar, haptic feedback
    ↓
Lottie mascot animation, spring slide-down, auto-dismiss
```

---

## 7. Assets

```
assets/
├── mascot.json              # Lottie mascot animation (69 frames)
├── fonts/                   # 6 font families (Avenir, Inter, DMSans, Metropolis, RobotoCondensed, Inconsolata)
├── categories/              # Category icon assets
├── banner/                  # Banner images
├── icon/                    # App icon
├── landing/                 # Landing page images
├── images/                  # General images
├── static/                  # Currency data, language names, generated files
├── translations/            # en.json, ta.json (easy_localization)
└── icons/                   # Custom icons (fun category, Icons.ttf font)
```

---

## 8. Build & Deployment

### 8.1 Build Commands
```bash
# Release APK
flutter build apk --release --no-tree-shake-icons --target-platform android-arm64

# Release bundle (Play Store)
flutter build appbundle --release

# iOS
flutter build ios --release
```

### 8.2 Key Config
```
Version: 5.4.3+416
Package: flow_finance
Min SDK: 21 (Android)
Keystore: /Users/ranesh/upload-keystore.jks
AdMob Banner: ca-app-pub-1969259760721536/2606891773
AdMob Interstitial: ca-app-pub-1969259760721536/7476075073
```

### 8.3 APK Size
- Current: 74.6MB (includes Lottie mascot JSON asset)

---

## 9. Dependencies (Key Packages)

| Package | Version | Purpose |
|---------|---------|---------|
| drift | ^2.32.1 | SQLite ORM |
| fl_chart | ^0.68.0 | Charts & graphs |
| provider | ^6.1.2 | State management |
| easy_localization | ^3.0.7 | i18n (EN/TA) |
| lottie | ^3.3.0 | Mascot toast animations |
| shimmer | ^3.0.0 | Loading skeletons |
| fl_chart | ^0.68.0 | Interactive charts |
| google_mobile_ads | ^5.3.1 | AdMob |
| firebase_* | latest | Auth, Firestore, Messaging |
| local_auth | ^2.2.0 | Biometric lock |
| telephony | ^0.2.0 | SMS reading |
| pdf + printing | latest | PDF export |
| csv | ^6.0.0 | CSV import/export |
| intl | ^0.20.2 | Number/date formatting |
| in_app_review | ^2.0.9 | App store review prompt |
| confetti | ^0.7.0 | Goal completion celebration |
| flutter_local_notifications | ^17.2.1 | Local push notifications |
| home_widget | ^0.9.1 | Home screen widget |
| app_links | ^6.1.4 | Deep linking |
| share_plus | ^10.0.0 | System share sheet |

---

## 10. What Makes Flow Finance Special

1. **Offline-first:** Full Drift SQLite database — works without internet, no server dependency
2. **100% Cupertino UI:** Every pixel is iOS-native — no Material jank
3. **Mascot-driven UX:** Lottie-animated mascot makes finance fun and approachable
4. **Smart Rules Engine:** Client-side automation that never phones home — your data stays on device
5. **AI Insights:** On-device anomaly detection and forecasting — no cloud AI needed
6. **SMS Integration:** Parses bank messages from 20+ Indian banks — auto-log expenses
7. **Multi-currency:** INR/USD with exchange rate support and wallet conversion
8. **Biometric Security:** Fingerprint/face lock for privacy
9. **Tamil Localization:** Full Tamil language support — rare for finance apps
10. **Comprehensive Export:** CSV + PDF with share support
11. **Family Sharing:** Shared budgets and financial overview
12. **No Account Required:** Everything works offline — Firebase is optional for FCM
13. **Premium Design:** Indigo/Teal palette, custom fonts, flat Cupertino aesthetic
14. **AI Financial Health Score:** Algorithmic assessment of financial wellness
15. **Goal Celebration:** Confetti animation on goal completion
