import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LecturerAddSlotScreen extends StatefulWidget {
  const LecturerAddSlotScreen({super.key});

  @override
  State<LecturerAddSlotScreen> createState() => _LecturerAddSlotScreenState();
}

class _LecturerAddSlotScreenState extends State<LecturerAddSlotScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  String meetingType = 'online'; // or 'in_person'

  void _submitSlot() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please select both date and time'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final slotDateTime = DateTime(
      selectedDate!.year,
      selectedDate!.month,
      selectedDate!.day,
      selectedTime!.hour,
      selectedTime!.minute,
    );

    // TODO: Replace with Firebase Function call
    print('📅 Submitted slot: $slotDateTime, Type: $meetingType');

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Slot added for ${DateFormat.yMMMMd().add_jm().format(slotDateTime)}'),
      backgroundColor: Colors.green,
    ));

    // Clear selections
    setState(() {
      selectedDate = null;
      selectedTime = null;
      meetingType = 'online';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 60)),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Available Slot')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              ListTile(
                title: Text(
                  selectedDate == null
                      ? 'Select Date'
                      : DateFormat.yMMMMd().format(selectedDate!),
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
              ),
              ListTile(
                title: Text(
                  selectedTime == null
                      ? 'Select Time'
                      : selectedTime!.format(context),
                ),
                trailing: const Icon(Icons.access_time),
                onTap: _pickTime,
              ),
              DropdownButtonFormField<String>(
                value: meetingType,
                decoration: const InputDecoration(labelText: 'Meeting Type'),
                items: const [
                  DropdownMenuItem(value: 'online', child: Text('Online')),
                  DropdownMenuItem(value: 'in_person', child: Text('In-Person')),
                ],
                onChanged: (value) => setState(() => meetingType = value!),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text("Submit Slot"),
                onPressed: _submitSlot,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
