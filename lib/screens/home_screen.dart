import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'classroom_screen.dart';
import 'settings_screen.dart';

class Classroom {
  String name;
  List<Student> students;

  Classroom({required this.name, required this.students});

  Map<String, dynamic> toJson() => {
    'name': name,
    'students': students.map((s) => s.toJson()).toList(),
  };

  factory Classroom.fromJson(Map<String, dynamic> json) => Classroom(
    name: json['name'],
    students:
        (json['students'] as List).map((s) => Student.fromJson(s)).toList(),
  );
}

class Student {
  String name;
  int rollNumber;
  Map<String, bool> attendance;

  Student({
    required this.name,
    required this.rollNumber,
    required this.attendance,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'rollNumber': rollNumber,
    'attendance': attendance,
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    name: json['name'],
    rollNumber: json['rollNumber'],
    attendance: Map<String, bool>.from(json['attendance']),
  );
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Classroom> classrooms = [];
  TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortMode = 'Name';

  @override
  void initState() {
    super.initState();
    _loadClassrooms();

    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  Future<void> _loadClassrooms() async {
    final prefs = await SharedPreferences.getInstance();
    final String? classroomsJson = prefs.getString('classrooms');
    setState(() {
      classrooms =
          classroomsJson != null
              ? (jsonDecode(classroomsJson) as List)
                  .map((c) => Classroom.fromJson(c))
                  .toList()
              : [];
    });
  }

  Future<void> _saveClassrooms() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'classrooms',
      jsonEncode(classrooms.map((c) => c.toJson()).toList()),
    );
  }

  List<Classroom> _filteredAndSortedClassrooms() {
    List<Classroom> filtered =
        classrooms
            .where((c) => c.name.toLowerCase().contains(_searchQuery))
            .toList();

    if (_sortMode == 'Name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortMode == 'Students') {
      filtered.sort((b, a) => a.students.length.compareTo(b.students.length));
    }

    return filtered;
  }

  void _showAddClassroomDialog() {
    final TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Classroom'),
            content: TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Classroom Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    setState(() {
                      classrooms.add(
                        Classroom(name: _controller.text, students: []),
                      );
                      _saveClassrooms();
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

  void _showEditDeleteDialog(int index) {
    final TextEditingController _controller = TextEditingController(
      text: classrooms[index].name,
    );
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Manage Classroom'),
            content: TextField(
              controller: _controller,
              decoration: InputDecoration(labelText: 'Classroom Name'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    classrooms.removeAt(index);
                    _saveClassrooms();
                  });
                  Navigator.pop(context);
                },
                child: Text('Delete'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
              TextButton(
                onPressed: () {
                  if (_controller.text.isNotEmpty) {
                    setState(() {
                      classrooms[index].name = _controller.text;
                      _saveClassrooms();
                    });
                    Navigator.pop(context);
                  }
                },
                child: Text('Edit'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Magister',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        backgroundColor: Color.fromARGB(255, 23, 62, 80),
        elevation: 6,
        actions: [
          // IconButton(
          //   icon: Icon(Icons.bolt, color: Colors.white),
          //   tooltip: 'Add Dummy Data',
          //   onPressed: () {
          //     setState(() {
          //       classrooms.addAll([
          //         Classroom(
          //           name: 'Biology',
          //           students: List.generate(
          //             15,
          //             (i) => Student(
          //               name: 'Student ${i + 1}',
          //               rollNumber: i + 1,
          //               attendance: {},
          //             ),
          //           ),
          //         ),
          //         Classroom(
          //           name: 'Physics',
          //           students: List.generate(
          //             12,
          //             (i) => Student(
          //               name: 'Learner ${i + 1}',
          //               rollNumber: i + 1,
          //               attendance: {},
          //             ),
          //           ),
          //         ),
          //       ]);
          //       _saveClassrooms();
          //     });
          //   },
          // ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => SettingsScreen(
                        onClassroomsUpdated: (List<Classroom> newClassrooms) {
                          setState(() {
                            classrooms = newClassrooms;
                            _saveClassrooms();
                          });
                        },
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Classrooms...',
                      prefixIcon: Icon(Icons.search),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey[850]
                              : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                PopupMenuButton<String>(
                  icon: Icon(Icons.sort, color: Color.fromARGB(255, 23, 62, 80)),
                  onSelected: (value) {
                    setState(() => _sortMode = value);
                  },
                  itemBuilder:
                      (context) => [
                        PopupMenuItem(
                          value: 'Name',
                          child: Text('Sort by Name'),
                        ),
                        PopupMenuItem(
                          value: 'Students',
                          child: Text('Sort by Students'),
                        ),
                      ],
                ),
              ],
            ),
          ),
          Expanded(
            child:
                _filteredAndSortedClassrooms().isEmpty
                    ? Center(
                      child: Text(
                        'No matching classrooms.',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                    : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _filteredAndSortedClassrooms().length,
                      itemBuilder: (context, index) {
                        final classroom = _filteredAndSortedClassrooms()[index];
                        return Card(
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(18),
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFF082634),
                              child: Icon(Icons.class_, color: Colors.white),
                            ),
                            title: Text(
                              classroom.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              '${classroom.students.length} students',
                              style: TextStyle(color: Colors.grey.shade700),
                            ),
                            trailing: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${classroom.students.length}',
                                style: TextStyle(color: Colors.indigo),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => ClassroomScreen(
                                        classroom: classroom,
                                        onUpdate: () {
                                          setState(() => _saveClassrooms());
                                        },
                                      ),
                                ),
                              );
                            },
                            onLongPress: () => _showEditDeleteDialog(index),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color.fromARGB(255, 23, 62, 80),
        onPressed: _showAddClassroomDialog,
        child: Icon(Icons.add),
        tooltip: 'Add Classroom',
      ),
    );
  }
}
