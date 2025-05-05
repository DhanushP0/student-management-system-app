import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:student_management_app/core/widgets/custom_loader.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _schedule = [];
  String? _errorMessage;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;

  final List<String> _timeSlots = [
    '8:00 AM - 9:00 AM',
    '9:00 AM - 10:00 AM',
    '10:00 AM - 11:00 AM',
    '11:00 AM - 12:00 PM',
    '1:00 PM - 2:00 PM',
    '2:00 PM - 3:00 PM',
    '3:00 PM - 4:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _loadSchedule();
  }

  Future<void> _loadSchedule() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final response = await Supabase.instance.client
          .from('schedule')
          .select()
          .order('day_of_week');

      setState(() {
        _schedule = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load schedule: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _addClass(String timeSlot, String subject) async {
    try {
      await Supabase.instance.client.from('schedule').insert({
        'day_of_week': _selectedDay.weekday,
        'time_slot': timeSlot,
        'subject': subject,
      });

      _loadSchedule();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add class: $e')));
    }
  }

  String _getDayName(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CustomLoader());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            ElevatedButton(
              onPressed: _loadSchedule,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadSchedule),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2024, 12, 31),
            focusedDay: _focusedDay,
            calendarFormat: _calendarFormat,
            selectedDayPredicate: (day) {
              return isSameDay(_selectedDay, day);
            },
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              setState(() {
                _calendarFormat = format;
              });
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _timeSlots.length,
              itemBuilder: (context, index) {
                final timeSlot = _timeSlots[index];
                final classesForTimeSlot =
                    _schedule.where((class_) {
                      return class_['day_of_week'] == _selectedDay.weekday &&
                          class_['time_slot'] == timeSlot;
                    }).toList();

                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text(timeSlot),
                    subtitle:
                        classesForTimeSlot.isEmpty
                            ? const Text('No class scheduled')
                            : Text(classesForTimeSlot.first['subject']),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final subject = await showDialog<String>(
                          context: context,
                          builder: (context) => const SubjectDialog(),
                        );
                        if (subject != null) {
                          _addClass(timeSlot, subject);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SubjectDialog extends StatefulWidget {
  const SubjectDialog({super.key});

  @override
  State<SubjectDialog> createState() => _SubjectDialogState();
}

class _SubjectDialogState extends State<SubjectDialog> {
  String _selectedSubject = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Class'),
      content: DropdownButtonFormField<String>(
        value: _selectedSubject.isEmpty ? null : _selectedSubject,
        decoration: const InputDecoration(labelText: 'Subject'),
        items: const [
          DropdownMenuItem(value: 'Math', child: Text('Math')),
          DropdownMenuItem(value: 'Science', child: Text('Science')),
          DropdownMenuItem(value: 'English', child: Text('English')),
        ],
        onChanged: (value) {
          setState(() {
            _selectedSubject = value!;
          });
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_selectedSubject.isNotEmpty) {
              Navigator.pop(context, _selectedSubject);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
