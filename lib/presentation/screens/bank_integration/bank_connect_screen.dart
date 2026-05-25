import 'package:flutter/material.dart';
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
                Icon(Icons.security, color: AppColors.primary),
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
        return ChoiceChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(country['flag'] as String),
              const SizedBox(width: 8),
              Text(country['name'] as String),
            ],
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedCountry = selected ? country['code'] as String : null;
              _selectedProvider = null;
              _institutions = [];
            });
          },
          selectedColor: AppColors.primary.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primary,
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
          child: ListTile(
            leading: Icon(
              provider['icon'] as IconData,
              color: isSelected ? AppColors.primary : null,
            ),
            title: Text(provider['name'] as String),
            subtitle: Text(
              provider['description'] as String,
              style: AppTypography.bodySmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check_circle, color: AppColors.primary)
                : const Icon(Icons.chevron_right),
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
        'icon': Icons.account_balance,
      });
    }

    // TrueLayer supports UK and EU
    if (['GB', 'IE', 'FR', 'DE', 'ES', 'NL'].contains(countryCode)) {
      providers.add({
        'id': 'truelayer',
        'name': 'TrueLayer',
        'description': 'Connect via TrueLayer (UK & EU)',
        'icon': Icons.account_balance_wallet,
      });
    }

    // Indian providers
    if (countryCode == 'IN') {
      providers.add({
        'id': 'aa_finvu',
        'name': 'Account Aggregator (Finvu)',
        'description': 'RBI-approved secure connection',
        'icon': Icons.verified_user,
      });
      providers.add({
        'id': 'upi_sms',
        'name': 'UPI SMS Tracking',
        'description': 'Track UPI transactions via SMS',
        'icon': Icons.message,
      });
    }

    return providers;
  }

  Widget _buildBankSelector(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_institutions.isEmpty) {
      return AppCard(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.search,
                size: 48,
                color: AppColors.textSecondaryLight,
              ),
              const SizedBox(height: 12),
              Text(
                'Search for your bank',
                style: AppTypography.bodyMedium(),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Bank name...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
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
          child: ListTile(
            leading: institution.logo != null
                ? Image.network(
                    institution.logo!,
                    width: 40,
                    height: 40,
                    errorBuilder: (_, __, ___) => _buildBankIcon(),
                  )
                : _buildBankIcon(),
            title: Text(institution.name),
            subtitle: Text(
              'Supports: ${institution.supportedFeatures.take(3).join(', ')}',
              style: AppTypography.labelSmall(
                color: AppColors.textSecondaryLight,
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
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
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.account_balance, color: AppColors.primary),
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
                    Icons.account_balance_outlined,
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
      context.showSnackBar(
        SnackBar(content: Text('Error loading banks: $e')),
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

    String? selectedWalletId;

    if (wallets.isNotEmpty) {
      selectedWalletId = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Link to Wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: wallets.map((wallet) {
              return ListTile(
                title: Text(wallet.name),
                subtitle: Text(wallet.currency),
                onTap: () => Navigator.pop(context, wallet.id),
              );
            }).toList(),
          ),
        ),
      );
    }

    // Start bank connection flow
    if (mounted) {
      context.showSnackBar(
        SnackBar(
          content: Text('Connecting to ${institution.name}...'),
          duration: const Duration(seconds: 2),
        ),
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
