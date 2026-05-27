import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../../core/services/currency_formatter.dart';
import '../../../core/services/ai_insights_service.dart';
import '../../../core/services/ai_assistant_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/widgets/app_loading.dart';
import '../../blocs/transaction_bloc.dart';

/// AI Insights and Assistant screen
class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  final AIInsightsService _insightsService = AIInsightsService();
  final AIAssistantService _assistantService = AIAssistantService();
  final TextEditingController _queryController = TextEditingController();

  FinancialHealthScore? _healthScore;
  List<SpendingAnomaly>? _anomalies;
  SpendingForecast? _forecast;
  List<SmartAlert>? _alerts;
  AIQueryResponse? _lastResponse;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInsights();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);

    final bloc = context.read<TransactionBloc>();
    await bloc.loadTransactions();
    final transactions = bloc.transactions;

    if (transactions.isNotEmpty) {
      setState(() {
        _healthScore = _insightsService.calculateHealthScore(transactions, []);
        _anomalies = _insightsService.detectAnomalies(transactions);
        _forecast = _insightsService.predictSpending(transactions);
        _alerts = _assistantService.generateSmartAlerts(transactions);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _sendQuery() {
    final query = _queryController.text.trim();
    if (query.isEmpty) return;

    final bloc = context.read<TransactionBloc>();
    final response = _assistantService.processQuery(query, bloc.transactions);

    setState(() {
      _lastResponse = response;
      _queryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: 'AI Insights'.tr(),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadInsights,
        ),
      ],
      body: _isLoading
          ? AppLoading.fullScreen()
          : Column(
              children: [
                // AI Assistant Chat Section
                _buildChatSection(isDark),

                // Insights List
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Health Score Card
                        if (_healthScore != null) _buildHealthScoreCard(isDark),

                        const SizedBox(height: 20),

                        // Smart Alerts
                        if (_alerts != null && _alerts!.isNotEmpty)
                          _buildAlertsSection(isDark),

                        const SizedBox(height: 20),

                        // Spending Forecast
                        if (_forecast != null) _buildForecastCard(isDark),

                        const SizedBox(height: 20),

                        // Anomalies
                        if (_anomalies != null && _anomalies!.isNotEmpty)
                          _buildAnomaliesSection(isDark),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildChatSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Chat Display
          if (_lastResponse != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'AI Assistant'.tr(),
                        style: AppTypography.labelMedium(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastResponse!.message,
                    style: AppTypography.bodyMedium(),
                  ),
                  if (_lastResponse!.suggestions != null) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      children: _lastResponse!.suggestions!.map((suggestion) {
                        return ActionChip(
                          label: Text(suggestion),
                          onPressed: () {
                            _queryController.text = suggestion;
                            _sendQuery();
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),

          // Query Input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: InputDecoration(
                      hintText: 'Ask about your finances...'.tr(),
                      prefixIcon: const Icon(Icons.chat_bubble_outline),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _sendQuery,
                      ),
                    ),
                    onSubmitted: (_) => _sendQuery(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthScoreCard(bool isDark) {
    final score = _healthScore!;
    final color = _getScoreColor(score.overallScore);

    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Financial Health Score'.tr(),
                  style: AppTypography.titleMedium(),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    score.rating,
                    style: AppTypography.labelMedium(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: score.overallScore / 100,
                        strokeWidth: 8,
                        backgroundColor: AppColors.border(context),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                      ),
                      Center(
                        child: Text(
                          '${score.overallScore}',
                          style: AppTypography.titleLarge().copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: score.categoryScores.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Text(
                                _getCategoryLabel(entry.key),
                                style: AppTypography.labelSmall(),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: entry.value / 100,
                                  backgroundColor: AppColors.border(context),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _getScoreColor(entry.value.round()),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${entry.value.round()}',
                              style: AppTypography.labelSmall(),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            if (score.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Divider(color: AppColors.border(context)),
              const SizedBox(height: 8),
              ...score.recommendations.map((rec) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rec,
                          style: AppTypography.bodySmall(),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertsSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Alerts'.tr(),
          style: AppTypography.titleMedium(),
        ),
        const SizedBox(height: 12),
        ..._alerts!.take(3).map((alert) {
          return _buildAlertCard(alert, isDark);
        }),
      ],
    );
  }

  Widget _buildAlertCard(SmartAlert alert, bool isDark) {
    final color = _getAlertColor(alert.severity);
    IconData icon;

    switch (alert.type) {
      case AlertType.unusualSpending:
        icon = Icons.trending_up;
        break;
      case AlertType.duplicateTransaction:
        icon = Icons.content_copy;
        break;
      case AlertType.budgetWarning:
        icon = Icons.account_balance_wallet;
        break;
      case AlertType.subscriptionRenewal:
        icon = Icons.event_repeat;
        break;
    }

    return AppCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(alert.title.tr(),
            style: AppTypography.bodyMedium(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        subtitle: Text(alert.message, style: AppTypography.bodySmall(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis),
        trailing: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildForecastCard(bool isDark) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '30-Day Spending Forecast'.tr(),
                    style: AppTypography.titleMedium(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '{}% confidence'.tr(args: [
                      (_forecast!.confidence * 100).toStringAsFixed(0)
                    ]),
                    style: AppTypography.labelSmall(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '${'Predicted'.tr()}: ${CurrencyFormatter.format(_forecast!.predictedAmount)}',
              style: AppTypography.titleLarge(
                color: AppColors.primary,
              ).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Breakdown'.tr() + ':', style: AppTypography.labelMedium()),
            const SizedBox(height: 8),
            ..._forecast!.breakdown.entries.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(entry.key, style: AppTypography.bodySmall()),
                    ),
                    Text(
                      CurrencyFormatter.format(entry.value),
                      style: AppTypography.bodySmall(
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAnomaliesSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Spending Anomalies'.tr(),
          style: AppTypography.titleMedium(),
        ),
        const SizedBox(height: 12),
        ..._anomalies!.take(3).map((anomaly) {
          return AppCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(
                Icons.warning_amber,
                color: anomaly.severity == AnomalySeverity.high
                    ? AppColors.error
                    : AppColors.warning,
              ),
              title: Text(anomaly.transaction.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              subtitle: Text(anomaly.reason, style: AppTypography.bodySmall(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              trailing: Text(
                CurrencyFormatter.format(anomaly.transaction.amount),
                style: AppTypography.bodyMedium(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  Color _getAlertColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return AppColors.error;
      case AlertSeverity.warning:
        return AppColors.warning;
      case AlertSeverity.info:
        return AppColors.primary;
    }
  }

  String _getCategoryLabel(HealthCategory category) {
    switch (category) {
      case HealthCategory.savings:
        return 'Savings';
      case HealthCategory.consistency:
        return 'Consistency';
      case HealthCategory.goals:
        return 'Goals';
      case HealthCategory.emergencyFund:
        return 'Emergency Fund';
    }
  }
}
