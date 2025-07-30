import 'package:flutter/material.dart';
import 'package:ting/core/services/event_service.dart';
import 'package:ting/core/models/event_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ting/features/events/presentation/widgets/event_card.dart';
import 'package:ting/shared/theme.dart';
import 'package:ting/core/services/batch_service.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  late String adminId;

  @override
  void initState() {
    super.initState();
    adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Events', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<EventModel>>(
        stream: EventService.getAdminEvents(adminId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final events = snapshot.data ?? [];
          final now = DateTime.now();
          final active = events.where((e) => now.isBefore(e.endTime)).toList();
          final expired = events.where((e) => now.isAfter(e.endTime)).toList();
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                const TabBar(
                  tabs: [
                    Tab(text: 'Active'),
                    Tab(text: 'Expired'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildEventList(context, active, false),
                      _buildEventList(context, expired, true),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CreateOrEditEventScreen()),
          );
          if (created == true) setState(() {});
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEventList(BuildContext context, List<EventModel> events, bool expired) {
    if (events.isEmpty) {
      return Center(child: Text(expired ? 'No expired events.' : 'No active events.'));
    }
    return ListView.builder(
      itemCount: events.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final event = events[index];
        final timeLeft = expired ? 'Expired' : _formatDuration(event.endTime.difference(DateTime.now()));
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: EventCard(
            event: event,
            expired: expired,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminEventInfoScreen(event: event),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return 'Expired';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return '\\${days}d \\${hours}h';
    if (hours > 0) return '\\${hours}h \\${minutes}m';
    return '\\${minutes}m';
  }
}

class CreateOrEditEventScreen extends StatefulWidget {
  final EventModel? event;
  const CreateOrEditEventScreen({super.key, this.event});

  @override
  State<CreateOrEditEventScreen> createState() => _CreateOrEditEventScreenState();
}

class _CreateOrEditEventScreenState extends State<CreateOrEditEventScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _batchController;
  DateTime? _date;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSaving = false;
  late List<String> _batchNumbers;
  bool _isBatchLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event?.title ?? '');
    _descController = TextEditingController(text: widget.event?.description ?? '');
    _batchController = TextEditingController(text: widget.event?.batchNo ?? '');
    _date = widget.event?.date;
    _startTime = widget.event != null ? TimeOfDay.fromDateTime(widget.event!.startTime) : null;
    _endTime = widget.event != null ? TimeOfDay.fromDateTime(widget.event!.endTime) : null;
    _batchNumbers = [];
    _fetchBatches();
  }

  Future<void> _fetchBatches() async {
    final batches = await BatchService.getAllBatchNumbers();
    setState(() {
      _batchNumbers = batches;
      _isBatchLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _batchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event', style: const TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Event Title',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.title),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Enter title' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 2,
                    validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
                  ),
                  const SizedBox(height: 16),
                  // Batch number dropdown
                  _isBatchLoading
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _batchNumbers.isNotEmpty
                          ? DropdownButtonFormField<String>(
                              value: _batchController.text.isNotEmpty && _batchNumbers.contains(_batchController.text)
                                  ? _batchController.text
                                  : null,
                              items: _batchNumbers
                                  .map((batch) => DropdownMenuItem<String>(
                                        value: batch,
                                        child: Text(batch),
                                      ))
                                  .toList(),
                                                            onChanged: (val) {
                                _batchController.text = val ?? '';
                              },
                              decoration: const InputDecoration(
                                labelText: 'Student Batch No',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.group),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Select batch no' : null,
                            )
                          : TextFormField(
                              controller: _batchController,
                              decoration: const InputDecoration(
                                labelText: 'Student Batch No',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.group),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Enter batch no' : null,
                            ),
                  const SizedBox(height: 16),
                  // Efficient date and time pickers
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today, color: Colors.grey),
                          label: Text(_date == null ? 'Pick Date' : _date!.toLocal().toString().split(' ')[0], style: const TextStyle(color: Colors.black)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _date ?? DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) setState(() => _date = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, color: Colors.grey),
                          label: Text(_startTime == null ? 'Start Time' : _startTime!.format(context), style: const TextStyle(color: Colors.black)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _startTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) setState(() => _startTime = picked);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.access_time, color: Colors.grey),
                          label: Text(_endTime == null ? 'End Time' : _endTime!.format(context), style: const TextStyle(color: Colors.black)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _endTime ?? TimeOfDay.now(),
                            );
                            if (picked != null) setState(() => _endTime = picked);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    onPressed: _isSaving ? null : _saveEvent,
                    child: Text(widget.event == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate() || _date == null || _startTime == null || _endTime == null) return;
    setState(() => _isSaving = true);
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final startDateTime = DateTime(_date!.year, _date!.month, _date!.day, _startTime!.hour, _startTime!.minute);
    final endDateTime = DateTime(_date!.year, _date!.month, _date!.day, _endTime!.hour, _endTime!.minute);
    final event = EventModel(
      id: widget.event?.id ?? '',
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      date: _date!,
      startTime: startDateTime,
      endTime: endDateTime,
      batchNo: _batchController.text.trim(),
      status: DateTime.now().isAfter(endDateTime) ? 'expired' : 'active',
      createdBy: adminId,
    );
    if (widget.event == null) {
      await EventService.createEvent(event);
    } else {
      await EventService.updateEvent(event.id, event.toMap());
    }
    setState(() => _isSaving = false);
    Navigator.pop(context, true);
  }
}

class AdminEventInfoScreen extends StatelessWidget {
  final EventModel event;
  const AdminEventInfoScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isExpired = now.isAfter(event.endTime);
    final timeLeft = isExpired ? 'Expired' : _formatDuration(event.endTime.difference(now));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Info', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateOrEditEventScreen(event: event),
                ),
              );
              if (updated == true) Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Event'),
                  content: const Text('Are you sure you want to delete this event?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                  ],
                ),
              );
              if (confirm == true) {
                await EventService.deleteEvent(event.id);
                Navigator.pop(context);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card-like info section with title and status
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          event.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: isExpired ? Colors.red.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isExpired ? 'EXPIRED' : 'ACTIVE',
                          style: TextStyle(
                            color: isExpired ? Colors.red : Colors.blue,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(event.description, style: const TextStyle(fontSize: 15)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Date: ${event.date.toLocal().toString().split(' ')[0]}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Start: ${_formatTime(event.startTime)}'),
                      const SizedBox(width: 12),
                      Text('End: ${_formatTime(event.endTime)}'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.group, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Batch: ${event.batchNo}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.timer, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Text('Time left: ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(timeLeft, style: TextStyle(color: isExpired ? Colors.red : Colors.blue)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return 'Expired';
    final days = d.inDays;
    final hours = d.inHours % 24;
    final minutes = d.inMinutes % 60;
    if (days > 0) return '${days}d ${hours}h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
