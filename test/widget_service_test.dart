import 'package:flutter_test/flutter_test.dart';
import 'package:ting/services/widget_service.dart';
import 'package:ting/core/models/event_model.dart';

void main() {
  group('WidgetService Tests', () {
    test('getCurrentEvent should return null when no event is set', () async {
      final currentEvent = await WidgetService.getCurrentEvent();
      expect(currentEvent, isNull);
    });

    testWidgets('setCurrentEvent should save event data', (
      WidgetTester tester,
    ) async {
      // Create a test event
      final testEvent = EventModel(
        id: 'test-id',
        title: 'Test Event',
        description: 'Test Description',
        date: DateTime.now().add(const Duration(days: 1)),
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(days: 1)),
        batchNo: 'BATCH001',
        status: 'active',
        createdBy: 'test-user',
      );

      // Test setting the event
      await WidgetService.setCurrentEvent(testEvent);

      // Verify event was saved
      final savedEvent = await WidgetService.getCurrentEvent();
      expect(savedEvent, isNotNull);
      expect(savedEvent!['title'], testEvent.title);
      expect(savedEvent['id'], testEvent.id);
    });

    testWidgets('removeCurrentEvent should clear event data', (
      WidgetTester tester,
    ) async {
      // First set an event
      final testEvent = EventModel(
        id: 'test-id',
        title: 'Test Event',
        description: 'Test Description',
        date: DateTime.now().add(const Duration(days: 1)),
        startTime: DateTime.now(),
        endTime: DateTime.now().add(const Duration(days: 1)),
        batchNo: 'BATCH001',
        status: 'active',
        createdBy: 'test-user',
      );

      await WidgetService.setCurrentEvent(testEvent);

      // Then remove it
      await WidgetService.removeCurrentEvent();

      // Verify it was removed
      final currentEvent = await WidgetService.getCurrentEvent();
      expect(currentEvent, isNull);
    });
  });
}
