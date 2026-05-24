/// Date range filter options
enum DateRangeFilter {
  all,
  today,
  yesterday,
  thisWeek,
  lastWeek,
  thisMonth,
  lastMonth,
  last30Days,
  last3Months,
  thisYear,
  custom;

  String get displayName {
    switch (this) {
      case DateRangeFilter.all:
        return 'All Time';
      case DateRangeFilter.today:
        return 'Today';
      case DateRangeFilter.yesterday:
        return 'Yesterday';
      case DateRangeFilter.thisWeek:
        return 'This Week';
      case DateRangeFilter.lastWeek:
        return 'Last Week';
      case DateRangeFilter.thisMonth:
        return 'This Month';
      case DateRangeFilter.lastMonth:
        return 'Last Month';
      case DateRangeFilter.last30Days:
        return 'Last 30 Days';
      case DateRangeFilter.last3Months:
        return 'Last 3 Months';
      case DateRangeFilter.thisYear:
        return 'This Year';
      case DateRangeFilter.custom:
        return 'Custom Range';
    }
  }

  /// Get date range for the filter
  (DateTime?, DateTime?) getDateRange() {
    final now = DateTime.now();
    
    switch (this) {
      case DateRangeFilter.all:
        return (null, null);
        
      case DateRangeFilter.today:
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start, end);
        
      case DateRangeFilter.yesterday:
        final yesterday = now.subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        return (start, end);
        
      case DateRangeFilter.thisWeek:
        final weekday = now.weekday;
        final start = now.subtract(Duration(days: weekday - 1));
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (startDate, endDate);
        
      case DateRangeFilter.lastWeek:
        final weekday = now.weekday;
        final lastWeekEnd = now.subtract(Duration(days: weekday));
        final lastWeekStart = lastWeekEnd.subtract(const Duration(days: 6));
        final start = DateTime(lastWeekStart.year, lastWeekStart.month, lastWeekStart.day);
        final end = DateTime(lastWeekEnd.year, lastWeekEnd.month, lastWeekEnd.day, 23, 59, 59);
        return (start, end);
        
      case DateRangeFilter.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start, end);
        
      case DateRangeFilter.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        final start = lastMonth;
        final end = DateTime(now.year, now.month, 0, 23, 59, 59);
        return (start, end);
        
      case DateRangeFilter.last30Days:
        final start = now.subtract(const Duration(days: 30));
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (startDate, endDate);
        
      case DateRangeFilter.last3Months:
        final start = DateTime(now.year, now.month - 3, now.day);
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (startDate, endDate);
        
      case DateRangeFilter.thisYear:
        final start = DateTime(now.year, 1, 1);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return (start, end);
        
      case DateRangeFilter.custom:
        return (null, null);
    }
  }
}
