import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/slot_card.dart'; // Make sure this exists

class StudentBookSlotScreen extends StatefulWidget {
  const StudentBookSlotScreen({super.key});

  @override
  State<StudentBookSlotScreen> createState() => _StudentBookSlotScreenState();
}

class _StudentBookSlotScreenState extends State<StudentBookSlotScreen> {
  String? selectedLecturerId;
  List<String> lecturers = ['lecturer_1', 'lecturer_2']; // TODO: Fetch dynamically
  List<Map<String, dynamic>> availableSlots = [];

  @override
  void initState() {
    super.initState();
    // Optionally pre-fetch lecturers
  }

  void _fetchSlotsForLecturer(String lecturerId) async {
    // TODO: Replace with Firebase Function call
    setState(() {
      availableSlots = [
        {
          'slotId': '1',
          'dateTime': DateTime.now().add(const Duration(days: 1, hours: 3)),
          'type': 'online',
        },
        {
          'slotId': '2',
          'dateTime': DateTime.now().add(const Duration(days: 2, hours: 1)),
          'type': 'in_person',
        },
      ];
    });
  }

  void _bookSlot(String slotId) async {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Booking Reason'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter reason for appointment...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // cancel
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = reasonController.text.trim();

              if (reason.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text("Reason cannot be empty."),
                  backgroundColor: Colors.red,
                ));
                return;
              }

              Navigator.of(context).pop(); // close dialog

              // TODO: Send reason + slotId to Firebase
              print('Booking Slot: $slotId, Reason: $reason');

              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Booked Slot ID: $slotId"),
                backgroundColor: Colors.green,
              ));
            },
            child: const Text('Book Now'),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Book Appointment")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: "Select Lecturer"),
              value: selectedLecturerId,
              items: lecturers
                  .map((id) => DropdownMenuItem(value: id, child: Text(id)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedLecturerId = value;
                  availableSlots = [];
                });
                if (value != null) {
                  _fetchSlotsForLecturer(value);
                }
              },
            ),
            const SizedBox(height: 20),
            if (availableSlots.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: availableSlots.length,
                  itemBuilder: (context, index) {
                    final slot = availableSlots[index];
                    return SlotCard(
                      dateTime: slot['dateTime'],
                      meetingType: slot['type'],
                      onBook: () => _bookSlot(slot['slotId']),
                    );
                  },
                ),
              )
            else if (selectedLecturerId != null)
              const Expanded(
                  child: Center(child: Text("No available slots."))),
          ],
        ),
      ),
    );
  }
}
