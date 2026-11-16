import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:genga/core/providers/database_provider.dart';
import 'package:genga/core/services/analytics_service.dart';
import 'package:genga/core/services/notification_service.dart';
import 'package:genga/core/utils/recurrence.dart';

const _kNotifications = 'pref_notifications_v2';
const _kDailyReminder = 'pref_daily_reminder';
const _kReminderMinutes = 'pref_reminder_minutes';
const _kWeeklyReport = 'pref_weekly_report';
const _kDueAlerts = 'pref_due_alerts';
const _kCurrency = 'pref_currency';
const _kCurrencyRate = 'pref_currency_rate';
const _kAnalyticsEnabled = 'pref_analytics_enabled';

class PreferencesState {
  final bool notifications;
  final bool dailyReminder;
  final int reminderMinutes;
  final bool weeklyReport;
  final bool dueAlerts;
  final String currency;
  final double currencyRate;
  final bool analyticsEnabled;

  const PreferencesState({
    this.notifications = false,
    this.dailyReminder = true,
    this.reminderMinutes = 20 * 60,
    this.weeklyReport = true,
    this.dueAlerts = true,
    this.currency = 'RWF',
    this.currencyRate = 1.0,
    this.analyticsEnabled = false,
  });

  int get reminderHour => reminderMinutes ~/ 60;
  int get reminderMinute => reminderMinutes % 60;

  PreferencesState copyWith({
    bool? notifications,
    bool? dailyReminder,
    int? reminderMinutes,
    bool? weeklyReport,
    bool? dueAlerts,
    String? currency,
    double? currencyRate,
    bool? analyticsEnabled,
  }) {
    return PreferencesState(
      notifications: notifications ?? this.notifications,
      dailyReminder: dailyReminder ?? this.dailyReminder,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      weeklyReport: weeklyReport ?? this.weeklyReport,
      dueAlerts: dueAlerts ?? this.dueAlerts,
      currency: currency ?? this.currency,
      currencyRate: currencyRate ?? this.currencyRate,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
    );
  }
}

class PreferencesNotifier extends StateNotifier<PreferencesState> {
  final Ref _ref;
  final NotificationService _notifications;
  final AnalyticsService _analytics;

  PreferencesNotifier(this._ref, this._notifications, this._analytics)
    : super(const PreferencesState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final notifications =
        prefs.getBool(_kNotifications) ??
        (prefs.getBool('pref_notifications') == true &&
            await _notifications.isPermitted());
    state = PreferencesState(
      notifications: notifications,
      dailyReminder: prefs.getBool(_kDailyReminder) ?? true,
      reminderMinutes: prefs.getInt(_kReminderMinutes) ?? 20 * 60,
      weeklyReport: prefs.getBool(_kWeeklyReport) ?? true,
      dueAlerts: prefs.getBool(_kDueAlerts) ?? true,
      currency: prefs.getString(_kCurrency) ?? 'RWF',
      currencyRate: prefs.getDouble(_kCurrencyRate) ?? 1.0,
      analyticsEnabled: prefs.getBool(_kAnalyticsEnabled) ?? false,
    );
    await reschedule();
  }

  /// Returns false when the OS refused permission, so the caller can
  /// point the user at system Settings.
  Future<bool> setNotifications(bool value) async {
    if (value && !await _notifications.requestPermission()) {
      return false;
    }
    state = state.copyWith(notifications: value);
    await _saveBool(_kNotifications, value, 'notifications');
    await reschedule();
    return true;
  }

  Future<void> setDailyReminder(bool value) async {
    state = state.copyWith(dailyReminder: value);
    await _saveBool(_kDailyReminder, value, 'daily_reminder');
    await reschedule();
  }

  Future<void> setReminderTime(int hour, int minute) async {
    state = state.copyWith(reminderMinutes: hour * 60 + minute);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kReminderMinutes, state.reminderMinutes);
    await reschedule();
  }

  Future<void> setWeeklyReport(bool value) async {
    state = state.copyWith(weeklyReport: value);
    await _saveBool(_kWeeklyReport, value, 'weekly_report');
    await reschedule();
  }

  Future<void> setDueAlerts(bool value) async {
    state = state.copyWith(dueAlerts: value);
    await _saveBool(_kDueAlerts, value, 'due_alerts');
    await reschedule();
  }

  Future<void> reschedule() async {
    try {
      if (!state.notifications || !await _notifications.isPermitted()) {
        await _notifications.cancelAll();
        return;
      }
      if (state.dailyReminder) {
        await _notifications.scheduleDailyReminder(
          hour: state.reminderHour,
          minute: state.reminderMinute,
        );
      } else {
        await _notifications.cancelDailyReminder();
      }
      if (state.weeklyReport) {
        await _notifications.scheduleWeeklySummary();
      } else {
        await _notifications.cancelWeeklySummary();
      }
      if (state.dueAlerts) {
        await _notifications.scheduleDueReminders(await _dueReminders());
      } else {
        await _notifications.cancelDueReminders();
      }
    } catch (e) {
      _analytics.trackEvent('notification_schedule_failed', {
        'error': e.runtimeType.toString(),
      });
    }
  }

  Future<List<DueReminder>> _dueReminders() async {
    final recurring = await _ref.read(databaseProvider).getAllRecurringOnce();
    final money = NumberFormat.decimalPattern();
    return [
      for (final r in recurring)
        DueReminder(
          id: r.transaction.id,
          title: '${r.category?.name ?? 'Recurring payment'} is due today',
          body:
              'RWF ${money.format(r.transaction.amount)}'
              '${r.transaction.note.isEmpty ? '' : ' · ${r.transaction.note}'}',
          when: _atNine(
            nextOccurrence(r.transaction.date, r.transaction.recurrence),
          ),
        ),
    ];
  }

  DateTime _atNine(DateTime d) => DateTime(d.year, d.month, d.day, 9);

  Future<void> setCurrency(String code, double rate) async {
    final oldCurrency = state.currency;
    state = state.copyWith(currency: code, currencyRate: rate);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrency, code);
    await prefs.setDouble(_kCurrencyRate, rate);
    _analytics.trackEvent('currency_changed', {
      'from': oldCurrency,
      'to': code,
    });
  }

  Future<void> setAnalyticsEnabled(bool value) async {
    state = state.copyWith(analyticsEnabled: value);
    await _analytics.setEnabled(value);
  }

  Future<void> resetAll() async {
    await _notifications.cancelAll();
    await _analytics.setEnabled(false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    state = const PreferencesState();
  }

  Future<void> _saveBool(String key, bool value, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    _analytics.trackEvent('preference_changed', {
      'preference': name,
      'new_value': value,
    });
  }
}

final preferencesProvider =
    StateNotifierProvider<PreferencesNotifier, PreferencesState>(
      (ref) => PreferencesNotifier(
        ref,
        ref.read(notificationServiceProvider),
        ref.read(analyticsServiceProvider),
      ),
    );
