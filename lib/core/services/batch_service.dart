import 'package:cloud_firestore/cloud_firestore.dart';

class BatchService {
  static Future<List<String>> getAllBatchNumbers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('userType', isEqualTo: 'student')
        .get();
    final batches = <String>{};
    for (final doc in snapshot.docs) {
      final data = doc.data();
      final batch = data['batchNo'] ?? data['batch_no'] ?? data['batchNumber'] ?? data['Batch No'] ?? data['batch'];
      if (batch != null && batch.toString().trim().isNotEmpty) {
        batches.add(batch.toString().trim());
      }
    }
    return batches.toList()..sort();
  }
}
