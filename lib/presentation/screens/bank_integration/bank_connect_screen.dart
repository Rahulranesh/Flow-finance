import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/models/bank_account.dart';
import '../../../core/services/bank_integration/plaid_service.dart';
import '../../../core/services/bank_integration/truelayer_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import 'package:flow_finance/core/utils/extensions.dart';
import '../../../core/widgets/cupertino_toast.dart';
import '../../blocs/wallet_bloc.dart';

/// Screen for connecting bank accounts
class BankConnectScreen extends StatefulWidget {
  const BankConnectScreen({super.key});

  @override
  State<BankConnectScreen> createState() => _BankConnectScreenState();
}

class _BankConnectScreenState extends State<BankConnectScreen> {
  final PlaidService _plaidService = PlaidService();
  final TrueLayerService _trueLayerService = TrueLayerService();

  bool _isLoading = false;
  String? _selectedCountry;
  String? _selectedProvider;
  List<BankInstitution> _institutions = [];

  final List<Map<String, dynamic>> _countries = [
    {'code': 'US', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': 'GB', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': 'CA', 'name': 'Canada', 'flag': '🇨🇦'},
    {'code': 'IE', 'name': 'Ireland', 'flag': '🇮🇪'},
    {'code': 'FR', 'name': 'France', 'flag': '🇫🇷'},
    {'code': 'DE', 'name': 'Germany', 'flag': '🇩🇪'},
    {'code': 'ES', 'name': 'Spain', 'flag': '🇪🇸'},
    {'code': 'NL', 'name': 'Netherlands', 'flag': '🇳🇱'},
    {'code': 'IN', 'name': 'India', 'flag': '🇮🇳'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  void _initializeServices() {
    // Initialize with sandbox credentials
    // In production, these would come from secure configuration
    _plaidService.initialize(
      clientId: 'YOUR_PLAID_CLIENT_ID',
      secret: 'YOUR_PLAID_SECRET',
      environment: PlaidEnvironment.sandbox,
    );

    _trueLayerService.initialize(
      clientId: 'YOUR_TRUELAYER_CLIENT_ID',
      clientSecret: 'YOUR_TRUELAYER_SECRET',
      redirectUri: 'com.cashew.budget://callback',
      environment: TrueLayerEnvironment.sandbox,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'Connect Bank Account'.tr(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            _buildInfoCard(isDark),

            const SizedBox(height: 24),

            // Country selection
            _buildSectionTitle('Select Your Country'.tr(), isDark),
            const SizedBox(height: 12),
            _buildCountrySelector(isDark),

            const SizedBox(height: 24),

            // Provider selection
            if (_selectedCountry != null) ...[
              _buildSectionTitle('Select Provider'.tr(), isDark),
              const SizedBox(height: 12),
              _buildProviderSelector(isDark),
            ],

            const SizedBox(height: 24),

            // Bank selection
            if (_selectedProvider != null) ...[
              _buildSectionTitle('Select Your Bank'.tr(), isDark),
              const SizedBox(height: 12),
              _buildBankSelector(isDark),
            ],

            const SizedBox(height: 24),

            // Connected accounts
            _buildConnectedAccountsSection(isDark),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return AppCard(
      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(CupertinoIcons.lock_shield_fill, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Secure Bank Connection'.tr(),
                    style:
                        AppTypography.bodyMedium(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Your credentials are never stored on our servers. We use bank-grade encryption and secure OAuth connections.'
                  .tr(),
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: AppTypography.titleMedium(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }

  Widget _buildCountrySelector(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _countries.map((country) {
        final isSelected = _selectedCountry == country['code'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCountry = isSelected ? null : country['code'] as String;
              _selectedProvider = null;
              _institutions = [];
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.primary : AppColors.border(context).withOpacity(0.5),
                width: isSelected ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(country['flag'] as String),
                const SizedBox(width: 8),
                Text((country['name'] as String).tr(), style: AppTypography.labelMedium(color: isSelected ? AppColors.primary : null)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildProviderSelector(bool isDark) {
    final providers = _getProvidersForCountry(_selectedCountry!);

    return Column(
      children: providers.map((provider) {
        final isSelected = _selectedProvider == provider['id'];
        return AppCard(
          onTap: () {
            setState(() {
              _selectedProvider = provider['id'] as String;
            });
            _loadInstitutions();
          },
          backgroundColor:
              isSelected ? AppColors.primary.withValues(alpha: 0.1) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: GestureDetector(
              onTap: () {},
              child: Row(
                children: [
                  Icon(
                    provider['icon'] as IconData,
                    size: 20,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text((provider['name'] as String).tr(), style: AppTypography.bodyLarge(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(
                          (provider['description'] as String).tr(),
                          style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.chevron_right,
                    size: 18,
                    color: isSelected ? AppColors.primary : AppColors.textTertiary(context),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, dynamic>> _getProvidersForCountry(String countryCode) {
    final providers = <Map<String, dynamic>>[];

    // Plaid supports US, CA, UK, EU
    if (['US', 'CA', 'GB', 'IE', 'FR', 'DE', 'ES', 'NL']
        .contains(countryCode)) {
      providers.add({
        'id': 'plaid',
        'name': 'Plaid',
        'description': 'Connect via Plaid (US, Canada, UK, EU)',
        'icon': CupertinoIcons.building_2_fill,
      });
    }

    // TrueLayer supports UK and EU
    if (['GB', 'IE', 'FR', 'DE', 'ES', 'NL'].contains(countryCode)) {
      providers.add({
        'id': 'truelayer',
        'name': 'TrueLayer',
        'description': 'Connect via TrueLayer (UK & EU)',
        'icon': CupertinoIcons.money_dollar_circle_fill,
      });
    }

    // Indian providers
    if (countryCode == 'IN') {
      providers.add({
        'id': 'aa_finvu',
        'name': 'Account Aggregator (Finvu)',
        'description': 'RBI-approved secure connection',
        'icon': CupertinoIcons.checkmark_seal_fill,
      });
      providers.add({
        'id': 'upi_sms',
        'name': 'UPI SMS Tracking',
        'description': 'Track UPI transactions via SMS',
        'icon': CupertinoIcons.chat_bubble_2_fill,
      });
    }

    return providers;
  }

  Widget _buildBankSelector(bool isDark) {
    if (_isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (_institutions.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                CupertinoIcons.search,
                size: 48,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 12),
              Text(
                'Search for your bank'.tr(),
                style: AppTypography.bodyMedium(),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Bank name...'.tr(),
                  prefixIcon: const Icon(CupertinoIcons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onChanged: _searchInstitutions,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _institutions.map((institution) {
        return AppCard(
          onTap: () => _connectBank(institution),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                institution.logo != null
                    ? Image.network(
                        institution.logo!,
                        width: 40,
                        height: 40,
                        errorBuilder: (_, __, ___) => _buildBankIcon(),
                      )
                    : _buildBankIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(institution.name, style: AppTypography.bodyLarge(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        '${'Supports'.tr()}: ${institution.supportedFeatures.take(3).join(', ')}',
                        style: AppTypography.bodySmall(color: AppColors.textTertiary(context)),
                      ),
                    ],
                  ),
                ),
                Icon(CupertinoIcons.chevron_right, size: 18, color: AppColors.textTertiary(context)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBankIcon() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(CupertinoIcons.building_2_fill, color: AppColors.primary),
    );
  }

  Widget _buildConnectedAccountsSection(bool isDark) {
    // In real implementation, fetch connected accounts from database
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Connected Accounts', isDark),
        const SizedBox(height: 12),
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    CupertinoIcons.building_2_fill,
                    size: 48,
                    color: AppColors.textSecondaryLight,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No accounts connected yet',
                    style: AppTypography.bodyMedium(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Connect your first bank account above',
                    style: AppTypography.bodySmall(
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadInstitutions() async {
    setState(() => _isLoading = true);

    try {
      if (_selectedProvider == 'plaid') {
        final institutions = await _plaidService.getInstitutions(
          countryCode: _selectedCountry,
          count: 50,
        );
        setState(() => _institutions = institutions);
      } else if (_selectedProvider == 'truelayer') {
        final providers = await _trueLayerService.getProviders(
          country: _selectedCountry,
        );
        setState(() {
          _institutions = providers
              .map((p) => BankInstitution(
                    id: p.id,
                    name: p.displayName,
                    logo: p.logoUri,
                    countryCodes: p.countries,
                    supportedFeatures: p.supportedScopes,
                  ))
              .toList();
        });
      }
    } catch (e) {
      CupertinoToast.show(
        context,
        message: '${'Error loading banks'.tr()}: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchInstitutions(String query) async {
    if (query.length < 2) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedProvider == 'plaid') {
        final institutions = await _plaidService.searchInstitutions(
          query,
          countryCodes: [_selectedCountry!],
        );
        setState(() => _institutions = institutions);
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectBank(BankInstitution institution) async {
    // Show wallet selection dialog
    final walletBloc = context.read<WalletBloc>();
    final wallets = walletBloc.wallets;

    if (wallets.isNotEmpty) {
      await showCupertinoModalPopup<String>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: Text('Link to Wallet'.tr()),
          actions: wallets.map((wallet) {
            return CupertinoActionSheetAction(
              onPressed: () => Navigator.pop(context, wallet.id),
              child: Text(wallet.name),
            );
          }).toList(),
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'.tr()),
          ),
        ),
      );
    }

    // Start bank connection flow
    if (mounted) {
      CupertinoToast.show(
        context,
        message: 'Connecting to {institution}...'.tr(namedArgs: {'institution': institution.name}),
      );
    }

    // In real implementation:
    // 1. Generate link token / auth URL
    // 2. Open WebView or browser
    // 3. Handle callback
    // 4. Exchange token
    // 5. Fetch accounts
    // 6. Save to database
  }
}
