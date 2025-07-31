import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/event_model.dart';

class EventService {
  static final _eventCollection = FirebaseFirestore.instance.collection('events');

  static Future<void> createEvent(EventModel event) async {
    await _eventCollection.add(event.toMap());
  }

  static Future<void> updateEvent(String id, Map<String, dynamic> data) async {
    await _eventCollection.doc(id).update(data);
  }

  static Future<void> deleteEvent(String id) async {
    await _eventCollection.doc(id).delete();
  }

  static Stream<List<EventModel>> getAdminEvents(String adminId) {
    return _eventCollection
      .where('createdBy', isEqualTo: adminId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
  }

  static Stream<List<EventModel>> getBatchEvents(String batchNo) {
    return _eventCollection
      .where('batchNo', isEqualTo: batchNo)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) => EventModel.fromMap(doc.data(), doc.id)).toList());
  }

  static Future<EventModel?> getEventById(String id) async {
    final doc = await _eventCollection.doc(id).get();
    if (doc.exists) {
      return EventModel.fromMap(doc.data()!, doc.id);
    }
    return null;
  }
}
