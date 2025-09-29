import 'package:flutter/material.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _currentMonth = _firstDayOfMonth(DateTime.now());
  DateTime _selectedDate = _stripTime(DateTime.now());

  static DateTime _stripTime(DateTime date) => DateTime(date.year, date.month, date.day);
  static DateTime _firstDayOfMonth(DateTime date) => DateTime(date.year, date.month, 1);
  static DateTime _lastDayOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);

  void _goToPrevMonth() {
    setState(() {
      _currentMonth = _firstDayOfMonth(DateTime(_currentMonth.year, _currentMonth.month - 1, 1));
      final last = _lastDayOfMonth(_currentMonth);
      if (_selectedDate.year == _currentMonth.year && _selectedDate.month == _currentMonth.month) {
        // aynı ayda ise dokunma
      } else {
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, last.day);
      }
    });
  }

  void _goToNextMonth() {
    setState(() {
      _currentMonth = _firstDayOfMonth(DateTime(_currentMonth.year, _currentMonth.month + 1, 1));
      final last = _lastDayOfMonth(_currentMonth);
      if (_selectedDate.year == _currentMonth.year && _selectedDate.month == _currentMonth.month) {
        // aynı ayda ise dokunma
      } else {
        _selectedDate = DateTime(_currentMonth.year, _currentMonth.month, last.day);
      }
    });
  }

  List<DateTime> _buildCalendarDays(DateTime month) {
    final List<DateTime> days = [];
    final first = _firstDayOfMonth(month);
    final last = _lastDayOfMonth(month);

    // Takvim haftası Pazartesi ile başlasın
    int weekdayFromMonday(int weekday) => weekday == DateTime.sunday ? 7 : weekday - 1;

    final leading = weekdayFromMonday(first.weekday) - 1; // 0..6
    for (int i = leading; i > 0; i--) {
      days.add(first.subtract(Duration(days: i)));
    }
    // Ay günleri
    for (int d = 0; d < last.day; d++) {
      days.add(DateTime(month.year, month.month, d + 1));
    }
    // Trailing günler 42 hücreye (6 hafta) tamamla
    while (days.length % 7 != 0) {
      days.add(days.last.add(const Duration(days: 1)));
    }
    // En az 42 hücre
    while (days.length < 42) {
      days.add(days.last.add(const Duration(days: 1)));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays(_currentMonth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _goToPrevMonth,
                    child: const Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: Colors.black87,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openMonthPicker,
                    child: Column(
                      children: [
                        Text(
                          _monthNameEn(_currentMonth.month),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          _currentMonth.year.toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _goToNextMonth,
                    child: const Icon(
                      Icons.chevron_right,
                      size: 28,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            
            // Weekday headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _WeekdayLabel('Pzt'),
                  _WeekdayLabel('Salı'),
                  _WeekdayLabel('Çar'),
                  _WeekdayLabel('Per'),
                  _WeekdayLabel('Cum'),
                  _WeekdayLabel('Cmt'),
                  _WeekdayLabel('Paz'),
                ],
              ),
            ),
            
            // Calendar Grid
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.builder(
                  itemCount: days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1.0,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    final isCurrentMonth = day.month == _currentMonth.month;
                    final isToday = _stripTime(day) == _stripTime(DateTime.now());
                    final isSelected = _stripTime(day) == _selectedDate;
                    final events = mockEventsFor(day);
                    final hasEvents = events.isNotEmpty;

                    Color bg = isSelected
                        ? const Color(0xFF4285F4)
                        : Colors.transparent;
                    Color txt = isSelected
                        ? Colors.white
                        : isCurrentMonth
                            ? Colors.black87
                            : Colors.black38;
                    Color border = isToday && !isSelected
                        ? const Color(0xFF4285F4)
                        : Colors.transparent;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = _stripTime(day);
                          _currentMonth = _firstDayOfMonth(day);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                          border: border != Colors.transparent 
                              ? Border.all(color: border, width: 1) 
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${day.day}',
                              style: TextStyle(
                                color: txt,
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (hasEvents)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  events.length > 3 ? 3 : events.length,
                                  (i) => Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 1),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF4285F4),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              )
                            else
                              const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Bottom Events Section
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: _InlineSelectedEvents(
                date: _selectedDate,
                events: mockEventsFor(_selectedDate),
                onOpenAll: () => _openEventsBottomSheet(context, _selectedDate, mockEventsFor(_selectedDate)),
              ),
            ),
          ],
        ),
      ),
      
      // Floating Action Button
      floatingActionButton: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFF6366F1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 24,
        ),
      ),
      
      
    );
  }

  Future<void> _openMonthPicker() async {
    final DateTime initial = _currentMonth;
    final DateTime first = DateTime(initial.year - 3, 1, 1);
    final DateTime last = DateTime(initial.year + 3, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: 'Ay seç',
      fieldLabelText: 'Tarih',
      cancelText: 'İptal',
      confirmText: 'Seç',
    );
    if (picked != null) {
      setState(() {
        _currentMonth = _firstDayOfMonth(picked);
        _selectedDate = _stripTime(picked);
      });
    }
  }

  void _openEventsBottomSheet(BuildContext context, DateTime date, List<_CalendarEvent> events) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final String title = formatDateTr(date);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.event, color: Color(0xFF4285F4)),
                      const SizedBox(width: 8),
                      Text(
                        'Etkinlikler · $title', 
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (events.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Text(
                      'Bu gün için etkinlik yok',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: events.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1, 
                        color: Colors.grey.withOpacity(0.3),
                      ),
                      itemBuilder: (context, index) {
                        final ev = events[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: const Color(0xFF4285F4).withOpacity(0.15),
                            child: const Icon(
                              Icons.event_note, 
                              size: 18, 
                              color: Color(0xFF4285F4),
                            ),
                          ),
                          title: Text(
                            ev.title, 
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            ev.timeRange,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right, 
                            color: Colors.black.withOpacity(0.35),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  String _monthNameEn(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[m - 1];
  }

  static String formatDateTr(DateTime d) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    int weekdayFromMonday(int weekday) => weekday == DateTime.sunday ? 6 : weekday - 1;
    return '${weekdays[weekdayFromMonday(d.weekday)]}, ${d.day} ${months[d.month - 1]}';
  }

  List<_CalendarEvent> mockEventsFor(DateTime d) {
    // Tasarımdaki örneklere göre events
    if (d.day == 2) { // Seçili gün
      return const [
        _CalendarEvent('Design new UX flow for Michael', '10:00-13:00'),
        _CalendarEvent('Brainstorm with the team', '14:00-15:00'),
        _CalendarEvent('Workout with Ella', '19:00-20:00'),
      ];
    }
    if (d.day == 3) {
      return const [
        _CalendarEvent('Meeting with client', '10:00-11:00'),
        _CalendarEvent('Review project', '15:00-16:00'),
      ];
    }
    if (d.day == 6) {
      return const [
        _CalendarEvent('Team standup', '09:00-09:30'),
      ];
    }
    if (d.day == 9) {
      return const [
        _CalendarEvent('Project presentation', '14:00-15:30'),
      ];
    }
    if (d.day == 10) {
      return const [
        _CalendarEvent('Code review', '11:00-12:00'),
        _CalendarEvent('Planning session', '16:00-17:00'),
      ];
    }
    if (d.day == 15) {
      return const [
        _CalendarEvent('Client call', '13:00-14:00'),
      ];
    }
    if (d.day == 17) {
      return const [
        _CalendarEvent('Sprint planning', '10:00-11:30'),
      ];
    }
    if (d.day == 23) {
      return const [
        _CalendarEvent('Design review', '15:00-16:00'),
      ];
    }
    if (d.day == 29) {
      return const [
        _CalendarEvent('Monthly review', '09:00-10:00'),
        _CalendarEvent('Team lunch', '12:00-13:00'),
        _CalendarEvent('Project wrap-up', '15:00-16:30'),
      ];
    }
    return const [];
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _CalendarEvent {
  final String title;
  final String timeRange;
  const _CalendarEvent(this.title, this.timeRange);
}

class _InlineSelectedEvents extends StatelessWidget {
  const _InlineSelectedEvents({
    required this.date, 
    required this.events, 
    required this.onOpenAll,
  });
  final DateTime date;
  final List<_CalendarEvent> events;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.circle,
                color: Color(0xFF4285F4),
                size: 8,
              ),
              const SizedBox(width: 8),
              Text(
                '${events.isNotEmpty ? events.first.timeRange : '10:00-13:00'}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF4285F4),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            events.isNotEmpty ? events.first.title : 'Design new UX flow for Michael',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Start from screen 16',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          
          if (events.length > 1) ...[
            Row(
              children: [
                const Icon(
                  Icons.circle,
                  color: Color(0xFF9C27B0),
                  size: 8,
                ),
                const SizedBox(width: 8),
                Text(
                  events.length > 1 ? events[1].timeRange : '14:00-15:00',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF9C27B0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              events.length > 1 ? events[1].title : 'Brainstorm with the team',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Define the problem or question that...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          if (events.length > 2) ...[
            Row(
              children: [
                const Icon(
                  Icons.circle,
                  color: Color(0xFF4285F4),
                  size: 8,
                ),
                const SizedBox(width: 8),
                Text(
                  events.length > 2 ? events[2].timeRange : '19:00-20:00',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4285F4),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              events.length > 2 ? events[2].title : 'Workout with Ella',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'We will do the legs and back workout',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
