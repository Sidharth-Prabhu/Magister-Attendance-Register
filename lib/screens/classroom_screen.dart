import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home_screen.dart';
import 'report_export_screen.dart';

class ClassroomScreen extends StatefulWidget {
  final Classroom classroom;
  final VoidCallback onUpdate;

  ClassroomScreen({required this.classroom, required this.onUpdate});

  @override
  _ClassroomScreenState createState() => _ClassroomScreenState();
}

class _ClassroomScreenState extends State<ClassroomScreen> {
  DateTime _selectedDate = DateTime.now();
  Map<int, Map<String, bool>> _tempAttendance = {};

  @override
  void initState() {
    super.initState();
    _initializeTempAttendance();
  }

  void _initializeTempAttendance() {
    _tempAttendance = {};
    String dateKey = _selectedDate.toIso8601String().split('T')[0];
    for (var student in widget.classroom.students) {
      _tempAttendance[student.rollNumber] = {
        dateKey: student.attendance[dateKey] ?? false,
      };
    }
  }

  void _showAddStudentDialog() {
    final nameController = TextEditingController();
    final rollController = TextEditingController(text: '1');
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Student'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: rollController,
                  decoration: InputDecoration(labelText: 'Roll Number'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () {
                  final name = nameController.text;
                  final roll = int.tryParse(rollController.text) ?? -1;
                  if (name.isNotEmpty && roll > 0) {
                    if (widget.classroom.students.any(
                      (s) => s.rollNumber == roll,
                    )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Roll number already exists')),
                      );
                      return;
                    }
                    setState(() {
                      widget.classroom.students.add(
                        Student(name: name, rollNumber: roll, attendance: {}),
                      );
                      _tempAttendance[roll] = {
                        _selectedDate.toIso8601String().split('T')[0]: false,
                      };
                      widget.onUpdate();
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('Add'),
              ),
            ],
          ),
    );
  }

  void _showEditDeleteStudentDialog(int index) {
    final student = widget.classroom.students[index];
    final nameController = TextEditingController(text: student.name);
    final rollController = TextEditingController(
      text: student.rollNumber.toString(),
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Manage Student'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: rollController,
                  decoration: InputDecoration(labelText: 'Roll Number'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    widget.classroom.students.removeAt(index);
                    _tempAttendance.remove(student.rollNumber);
                    widget.onUpdate();
                  });
                  Navigator.pop(context);
                },
                child: Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                onPressed: () {
                  final newName = nameController.text;
                  final newRoll = int.tryParse(rollController.text) ?? -1;

                  if (newName.isNotEmpty && newRoll > 0) {
                    if (newRoll != student.rollNumber &&
                        widget.classroom.students.any(
                          (s) => s.rollNumber == newRoll,
                        )) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Roll number already exists')),
                      );
                      return;
                    }

                    setState(() {
                      final oldRoll = student.rollNumber;
                      student.name = newName;
                      student.rollNumber = newRoll;
                      if (oldRoll != newRoll) {
                        _tempAttendance[newRoll] = _tempAttendance[oldRoll]!;
                        _tempAttendance.remove(oldRoll);
                      }
                      widget.onUpdate();
                    });

                    Navigator.pop(context);
                  }
                },
                child: Text('Save'),
              ),
            ],
          ),
    );
  }

  void _markAttendance(Student student) {
    setState(() {
      String dateKey = _selectedDate.toIso8601String().split('T')[0];
      _tempAttendance[student.rollNumber]![dateKey] =
          !(_tempAttendance[student.rollNumber]![dateKey] ?? false);
    });
  }

  Future<void> _saveAttendance() async {
    String dateKey = _selectedDate.toIso8601String().split('T')[0];
    setState(() {
      for (var student in widget.classroom.students) {
        if (_tempAttendance[student.rollNumber]!.containsKey(dateKey)) {
          student.attendance[dateKey] =
              _tempAttendance[student.rollNumber]![dateKey]!;
        }
      }
      widget.onUpdate();
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _initializeTempAttendance();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String dateKey = _selectedDate.toIso8601String().split('T')[0];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.classroom.name),
        backgroundColor: Colors.indigoAccent,
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: _selectDate,
            tooltip: 'Select Date',
          ),
          IconButton(
            icon: Icon(Icons.download),
            tooltip: 'Export Report',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => ReportExportScreen(classroom: widget.classroom),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              'Attendance for $dateKey',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              icon: Icon(Icons.save),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                minimumSize: Size(double.infinity, 45),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _saveAttendance,
              label: Text('Save Attendance'),
            ),
          ),
          Expanded(
            child:
                widget.classroom.students.isEmpty
                    ? Center(child: Text('No students yet. Add one!'))
                    : ListView.builder(
                      itemCount: widget.classroom.students.length,
                      padding: EdgeInsets.all(12),
                      itemBuilder: (context, index) {
                        final student = widget.classroom.students[index];
                        final isPresent =
                            _tempAttendance[student.rollNumber]![dateKey] ??
                            false;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            title: Text(
                              student.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text('Roll No: ${student.rollNumber}'),
                            trailing: Chip(
                              label: Text(
                                isPresent ? 'Present' : 'Absent',
                                style: TextStyle(
                                  color:
                                      isPresent
                                          ? Colors.green.shade800
                                          : Colors.red.shade800,
                                ),
                              ),
                              backgroundColor:
                                  isPresent
                                      ? Colors.green.shade100
                                      : Colors.red.shade100,
                            ),
                            onTap: () => _markAttendance(student),
                            onLongPress:
                                () => _showEditDeleteStudentDialog(index),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigoAccent,
        onPressed: _showAddStudentDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Student',
      ),
    );
  }
}
