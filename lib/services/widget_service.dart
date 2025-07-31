import 'dart:async';
import 'dart:convert';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../core/models/event_model.dart';

class WidgetService {
  static const String _selectedEventKey = 'selected_event';
  static const String _widgetUpdateTaskName = 'widgetUpdateTask';

  static Timer? _countdownTimer;

  static Future<void> initialize() async {
    await HomeWidget.registerInteractivityCallback(_backgroundCallback);
  }

  static Future<void> setCurrentEvent(EventModel event) async {
    try {
      print('Setting current event: ${event.title}');
      print('Event end time: ${event.endTime}');

      final prefs = await SharedPreferences.getInstance();

      await prefs.setString(
        _selectedEventKey,
        jsonEncode({
          'id': event.id,
          'title': event.title,
          'endTime': event.endTime.millisecondsSinceEpoch,
        }),
      );

      print('Event data saved to SharedPreferences');

      await _updateWidget(event);

      await _startBackgroundUpdates();

      _startForegroundTimer(event);

      print('Event set successfully');
    } catch (e) {
      print('Error setting current event: $e');
    }
  }

  static void _startForegroundTimer(EventModel event) {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      final now = DateTime.now();

      if (now.isAfter(event.endTime)) {
        timer.cancel();
        await _clearWidget();
        return;
      }

      await _updateWidget(event);
    });
  }

  static void stopForegroundTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  static Future<void> _startBackgroundUpdates() async {
    await Workmanager().cancelByUniqueName(_widgetUpdateTaskName);

    await Workmanager().registerPeriodicTask(
      _widgetUpdateTaskName,
      _widgetUpdateTaskName,
      frequency: const Duration(seconds: 15),
      constraints: Constraints(
        networkType: NetworkType.unmetered,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
        requiresStorageNotLow: false,
      ),
    );
  }

  static Future<void> _updateWidget(EventModel event) async {
    try {
      final now = DateTime.now();
      final difference = event.endTime.difference(now);

      if (difference.isNegative) {
        await _clearWidget();
        return;
      }

      final days = difference.inDays;
      final hours = difference.inHours % 24;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      print('Updating widget with: ${event.title}');
      print('Days: $days, Hours: $hours, Minutes: $minutes, Seconds: $seconds');

      // Update widget data
      await HomeWidget.saveWidgetData('event_title', event.title);
      await HomeWidget.saveWidgetData('event_date', _formatDate(event.endTime));
      await HomeWidget.saveWidgetData('days_count', days.toString());
      await HomeWidget.saveWidgetData(
        'hours_count',
        hours.toString().padLeft(2, '0'),
      );
      await HomeWidget.saveWidgetData(
        'minutes_count',
        minutes.toString().padLeft(2, '0'),
      );
      await HomeWidget.saveWidgetData(
        'seconds_count',
        seconds.toString().padLeft(2, '0'),
      );

      print('Widget data saved, updating widget...');

      await HomeWidget.updateWidget(
        name: 'EventReminder',
        androidName: 'EventReminder',
      );

      print('Widget update completed');
    } catch (e) {
      print('Error updating widget: $e');
    }
  }

  /// Clear widget data when event expires
  static Future<void> _clearWidget() async {
    try {
      await HomeWidget.saveWidgetData('event_title', 'No Active Event');
      await HomeWidget.saveWidgetData('event_date', 'Select an event');
      await HomeWidget.saveWidgetData('days_count', '0');
      await HomeWidget.saveWidgetData('hours_count', '00');
      await HomeWidget.saveWidgetData('minutes_count', '00');
      await HomeWidget.saveWidgetData('seconds_count', '00');

      await HomeWidget.updateWidget(
        name: 'EventReminder',
        androidName: 'EventReminder',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_selectedEventKey);

      await Workmanager().cancelByUniqueName(_widgetUpdateTaskName);
    } catch (e) {
      print('Error clearing widget: $e');
    }
  }

  @pragma('vm:entry-point')
  static void _backgroundCallback(Uri? uri) {
    Workmanager().executeTask((task, inputData) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final eventJson = prefs.getString(_selectedEventKey);

        if (eventJson == null) return Future.value(true);

        final eventData = jsonDecode(eventJson);
        final endTime = DateTime.fromMillisecondsSinceEpoch(
          eventData['endTime'],
        );
        final now = DateTime.now();

        if (now.isAfter(endTime)) {
          await _clearWidget();
          return Future.value(true);
        }

        final event = EventModel(
          id: eventData['id'],
          title: eventData['title'],
          description: '',
          date: endTime,
          startTime: endTime,
          endTime: endTime,
          batchNo: '',
          status: 'active',
          createdBy: '',
        );

        await _updateWidget(event);
        return Future.value(true);
      } catch (e) {
        print('Background task error: $e');
        return Future.value(false);
      }
    });
  }

  static Future<Map<String, dynamic>?> getCurrentEvent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventJson = prefs.getString(_selectedEventKey);

      if (eventJson == null) return null;

      return jsonDecode(eventJson);
    } catch (e) {
      print('Error getting current event: $e');
      return null;
    }
  }

  static Future<void> removeCurrentEvent() async {
    await _clearWidget();
    stopForegroundTimer();
  }

  static String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static void dispose() {
    stopForegroundTimer();
  }
}
