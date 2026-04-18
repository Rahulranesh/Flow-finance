# Flow Finance - Modern Personal Finance App

A completely redesigned Flutter budget and expense tracking application with a modern 2025-level UI/UX design system.

## Project Transformation Summary

This project has been transformed from a cloned repository into a unique, production-ready application with:

- **New Identity**: Complete rebrand from "Cashew" to "Flow Finance"
- **Modern Design System**: Indigo/Teal color palette with soft shadows
- **Clean Architecture**: Organized folder structure with separation of concerns
- **Redesigned UI**: All screens rewritten with modern components
- **Smooth Animations**: Consistent motion design throughout

## New Architecture

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # Barrel exports
├── core/
│   ├── theme/
│   │   ├── app_colors.dart      # Color palette
│   │   ├── app_typography.dart  # Text styles
│   │   ├── app_shadows.dart     # Shadow system
│   │   ├── app_animations.dart  # Animation constants
│   │   └── app_theme.dart       # Theme configuration
│   ├── widgets/
│   │   ├── app_button.dart      # Button components
│   │   ├── app_card.dart        # Card components
│   │   ├── app_input.dart       # Input fields
│   │   ├── app_scaffold.dart    # Scaffold layouts
│   │   └── app_loading.dart     # Loading states
│   └── utils/                   # Utilities
├── presentation/
│   └── screens/
│       ├── home/
│       │   └── home_screen.dart
│       ├── transactions/
│       │   └── transactions_screen.dart
│       ├── add_transaction/
│       │   └── add_transaction_screen.dart
│       ├── budgets/
│       │   └── budgets_screen.dart
│       └── settings/
│           └── settings_screen.dart
├── data/                        # Data layer (preserved)
├── domain/                      # Domain layer (preserved)
└── pages/                       # Original pages (backup)
```

## Design System

### Colors
- **Primary**: Indigo (#6366F1)
- **Secondary**: Teal (#14B8A6)
- **Success**: Green (#22C55E)
- **Warning**: Amber (#F59E0B)
- **Error**: Red (#EF4444)
- **Income**: Emerald (#10B981)
- **Expense**: Red (#EF4444)

### Typography
- **Font Family**: Inter (with Avenir fallback)
- **Display**: 32-48px, bold
- **Headlines**: 20-32px, bold/semi-bold
- **Body**: 14-16px, regular
- **Labels**: 10-14px, medium/semi-bold

### Shadows
- **XS**: Subtle elevation
- **SM**: Cards at rest
- **MD**: Elevated elements
- **LG**: Modals and dialogs
- **XL**: Full-screen overlays

### Animations
- **Fast**: 150ms
- **Normal**: 250ms
- **Slow**: 400ms
- **Curves**: EaseOutCubic, Spring

## Screens

### Home Screen
- Hero balance card with gradient
- Quick action buttons
- Stats overview cards
- Recent transactions list
- Floating action button

### Transactions Screen
- Search bar with filters
- Chip-based filtering
- Grouped by date
- Swipe-to-delete actions
- Transaction details view

### Add Transaction Screen
- Large amount display
- Income/Expense toggle
- Category grid selector
- Date picker
- Number pad input
- Note field

### Budgets Screen
- Monthly overview card
- Budget progress bars
- Category breakdown
- Spending insights
- Budget alerts

### Settings Screen
- Profile section
- Appearance settings
- Preferences toggles
- Data management
- About section

## Core Widgets

### AppButton
- Primary (gradient filled)
- Secondary (outlined)
- Ghost (text only)
- Danger (red)
- Icon button variants

### AppCard
- Flat (border only)
- Elevated (small shadow)
- Highlighted (accent border)
- Glass (glassmorphism)

### AppInput
- Standard input
- Search input
- Amount input (with +/- toggle)

### AppScaffold
- Consistent app bars
- Bottom navigation
- Scroll views
- Section headers

### AppLoading
- Spinner (multiple sizes)
- Linear progress
- Shimmer effects
- Skeleton screens
- Empty states
- Error states

## Features

- Modern 2025 UI design
- Light and dark themes
- Smooth animations
- Responsive layout
- Accessible design
- Consistent spacing (8px grid)
- Soft shadows and elevation
- Glassmorphism effects
- Loading states
- Error handling

## Getting Started

1. Ensure Flutter is installed (>= 3.0.0)
2. Run `flutter pub get`
3. Run `flutter run`

## Dependencies

Key dependencies used:
- flutter (SDK)
- shimmer (loading effects)
- fl_chart (charts - preserved)
- drift (database - preserved)
- provider (state management - preserved)

## Business Logic

The original business logic has been preserved:
- Database schema (Drift)
- Currency formatting
- Settings management
- Authentication (if applicable)

The UI layer has been completely rewritten while maintaining compatibility with existing data models.

## Customization

### Changing Colors
Edit `lib/core/theme/app_colors.dart`:
```dart
static const Color primary = Color(0xFF6366F1);
```

### Changing Typography
Edit `lib/core/theme/app_typography.dart`:
```dart
static const String fontFamily = 'Inter';
```

### Adding New Screens
1. Create screen in `lib/presentation/screens/`
2. Export in `lib/app.dart`
3. Add to navigation in `main.dart`

## License

This project is now a unique application with all original repository references removed.
