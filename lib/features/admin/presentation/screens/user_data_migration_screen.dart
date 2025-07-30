import 'package:flutter/material.dart';
import 'package:ting/core/services/user_data_migration_service.dart';
import 'package:ting/shared/theme.dart';

class UserDataMigrationScreen extends StatefulWidget {
  const UserDataMigrationScreen({super.key});

  @override
  State<UserDataMigrationScreen> createState() => _UserDataMigrationScreenState();
}

class _UserDataMigrationScreenState extends State<UserDataMigrationScreen> {
  bool _isMigrating = false;
  String _migrationStatus = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Data Migration',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'User Data Migration',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'This will add the required fields to existing users:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    const Text('• Students: studentId, batchNo, course, academicYear'),
                    const Text('• Lecturers: lecturerId, modules, department, qualification'),
                    const Text('• Staff: staffId, department, position, supervisor'),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isMigrating ? null : _runMigration,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isMigrating
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Migrating...'),
                                ],
                              )
                            : const Text('Run Migration'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Manual Update Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manual Updates',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'For specific users, you can update them manually:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _showStudentUpdateDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Update Student'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _showLecturerUpdateDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Update Lecturer'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _showStaffUpdateDialog,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Update Staff'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Status Section
            if (_migrationStatus.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Migration Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _migrationStatus,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _runMigration() async {
    setState(() {
      _isMigrating = true;
      _migrationStatus = 'Starting migration...';
    });

    try {
      await UserDataMigrationService.migrateExistingUsers();
      setState(() {
        _migrationStatus = 'Migration completed successfully!';
      });
    } catch (e) {
      setState(() {
        _migrationStatus = 'Migration failed: $e';
      });
    } finally {
      setState(() {
        _isMigrating = false;
      });
    }
  }

  void _showStudentUpdateDialog() {
    final userIdController = TextEditingController();
    final studentIdController = TextEditingController();
    final batchNoController = TextEditingController();
    final courseController = TextEditingController();
    final academicYearController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Student'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userIdController,
                decoration: const InputDecoration(labelText: 'User ID (Required)'),
              ),
              TextField(
                controller: studentIdController,
                decoration: const InputDecoration(labelText: 'Student ID (Required)'),
              ),
              TextField(
                controller: batchNoController,
                decoration: const InputDecoration(labelText: 'Batch No (Required)'),
              ),
              TextField(
                controller: courseController,
                decoration: const InputDecoration(labelText: 'Course (Optional)'),
              ),
              TextField(
                controller: academicYearController,
                decoration: const InputDecoration(labelText: 'Academic Year (Optional)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (userIdController.text.isNotEmpty &&
                  studentIdController.text.isNotEmpty &&
                  batchNoController.text.isNotEmpty) {
                try {
                  await UserDataMigrationService.updateStudentManually(
                    userId: userIdController.text,
                    studentId: studentIdController.text,
                    batchNo: batchNoController.text,
                    course: courseController.text.isNotEmpty ? courseController.text : null,
                    academicYear: academicYearController.text.isNotEmpty 
                        ? int.tryParse(academicYearController.text) 
                        : null,
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student updated successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLecturerUpdateDialog() {
    // Similar dialog for lecturer - simplified for brevity
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lecturer update dialog - implement similar to student')),
    );
  }

  void _showStaffUpdateDialog() {
    // Similar dialog for staff - simplified for brevity
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Staff update dialog - implement similar to student')),
    );
  }
}
