import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/appointments_service.dart';
import '../models/appointment_models.dart';
import 'appointment_detail_view.dart';
import '../theme/app_colors.dart';

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  DateTime _currentMonth = _firstDayOfMonth(DateTime.now());
  DateTime _selectedDate = _stripTime(DateTime.now());
  bool _loading = true;
  String? _errorMessage;
  final AppointmentsService _appointmentsService = AppointmentsService();
  final Map<DateTime, List<_CalendarEvent>> _eventsByDay = <DateTime, List<_CalendarEvent>>{};
  static const List<String> _weekdaysShortTr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  static DateTime _stripTime(DateTime date) => DateTime(date.year, date.month, date.day);
  static DateTime _firstDayOfMonth(DateTime date) => DateTime(date.year, date.month, 1);
  static DateTime _lastDayOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);
  // Pazartesi=0 ... Pazar=6
  static int _weekdayFromMonday(int weekday) => weekday == DateTime.sunday ? 6 : weekday - 1;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    final resp = await _appointmentsService.getAppointments();
    if (!mounted) return;
    if (resp.success) {
      final map = <DateTime, List<_CalendarEvent>>{};
      for (final AppointmentItem item in resp.appointments) {
        final dt = _parseTrDateTime(item.appointmentDate);
        if (dt == null) continue;
        final key = _stripTime(dt);
        final list = map.putIfAbsent(key, () => <_CalendarEvent>[]);
        final timeStr = _formatTime(dt);
        final color = _parseStatusColor(item.statusColor);
        list.add(
          _CalendarEvent(
            title: item.appointmentTitle,
            timeRange: timeStr,
            compName: item.compName,
            statusName: item.statusName,
            statusColor: color,
            description: item.appointmentDesc,
          ),
        );
      }
      setState(() {
        _eventsByDay
          ..clear()
          ..addAll(map);
        _loading = false;
      });
    } else {
      setState(() {
        _loading = false;
        _errorMessage = resp.errorMessage ?? resp.message;
      });
    }
  }

  static DateTime? _parseTrDateTime(String raw) {
    // Beklenen format: dd.MM.yyyy HH:mm
    try {
      final parts = raw.split(' ');
      if (parts.length < 2) return null;
      final datePart = parts[0];
      final timePart = parts[1];
      final d = datePart.split('.');
      final t = timePart.split(':');
      if (d.length != 3 || t.length < 2) return null;
      final day = int.parse(d[0]);
      final month = int.parse(d[1]);
      final year = int.parse(d[2]);
      final hour = int.parse(t[0]);
      final minute = int.parse(t[1]);
      return DateTime(year, month, day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  static String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static Color _parseStatusColor(String raw) {
    // Beklenen format: #RRGGBB veya #AARRGGBB; boşsa varsayılan mavi
    final fallback = const Color(0xFF4285F4);
    final s = raw.trim();
    if (s.isEmpty) return fallback;
    String hex = s.startsWith('#') ? s.substring(1) : s;
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    try {
      final value = int.parse(hex, radix: 16);
      return Color(value);
    } catch (_) {
      return fallback;
    }
  }

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

    // Takvim haftası Pazartesi ile başlasın (0..6)
    final leading = _weekdayFromMonday(first.weekday);
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
      backgroundColor: AppColors.background,
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
                    child: Icon(
                      Icons.chevron_left,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  GestureDetector(
                    onTap: _openMonthPicker,
                    child: Column(
                      children: [
                        Text(
                          _monthNameTr(_currentMonth.month),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          _currentMonth.year.toString(),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _goToNextMonth,
                    child: Icon(
                      Icons.chevron_right,
                      size: 28,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const LinearProgressIndicator(minHeight: 2),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    TextButton(onPressed: _fetchAppointments, child: const Text('Tekrar dene')),
                  ],
                ),
              ),
            
            // Weekday headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _weekdaysShortTr.map((w) => _WeekdayLabel(w)).toList(),
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
                    final events = _eventsByDay[_stripTime(day)] ?? const <_CalendarEvent>[];
                    final hasEvents = events.isNotEmpty;

                    Color bg = isSelected
                        ? AppColors.primary
                        : Colors.transparent;
                    Color txt = isSelected
                        ? Colors.white
                        : isCurrentMonth
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.45);
                    Color border = isToday && !isSelected
                        ? AppColors.primary
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
                                children: [
                                  ...List.generate(
                                    events.length > 3 ? 3 : events.length,
                                    (i) => Container(
                                      width: 6,
                                      height: 6,
                                      margin: const EdgeInsets.symmetric(horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: events[i].statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  if (events.length > 3) ...[
                                    const SizedBox(width: 2),
                                    Text(
                                      '+${events.length - 3}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected ? Colors.white70 : Colors.black45,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
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
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: _InlineSelectedEvents(
                date: _selectedDate,
                events: _eventsByDay[_selectedDate] ?? const <_CalendarEvent>[],
                onOpenAll: () => _openEventsBottomSheet(context, _selectedDate, _eventsByDay[_selectedDate] ?? const <_CalendarEvent>[]),
              ),
            ),
          ],
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
                      const Icon(Icons.event, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'Etkinlikler · $title', 
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
                            backgroundColor: ev.statusColor.withOpacity(0.15),
                            child: Icon(
                              Icons.event_note, 
                              size: 18, 
                              color: ev.statusColor,
                            ),
                          ),
                          title: Text(
                            ev.title, 
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev.compName,
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ev.timeRange,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              if (ev.description.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  ev.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: Colors.black45),
                                ),
                              ],
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ev.statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              ev.statusName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: ev.statusColor,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AppointmentDetailView(
                                  title: ev.title,
                                  companyName: ev.compName,
                                  time: '${_CalendarViewState.formatDateTrPublic(date)} · ${ev.timeRange}',
                                  statusName: ev.statusName,
                                  statusColor: ev.statusColor,
                                  description: ev.description,
                                ),
                              ),
                            );
                          },
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

  String _monthNameTr(int m) {
    const names = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return names[m - 1];
  }

  static String formatDateTr(DateTime d) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    return '${_weekdaysShortTr[_weekdayFromMonday(d.weekday)]}, ${d.day} ${months[d.month - 1]}';
  }

  // _InlineSelectedEvents içinde de kullanmak için public alias
  static String formatDateTrPublic(DateTime d) => formatDateTr(d);

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
  final String compName;
  final String statusName;
  final Color statusColor;
  final String description;

  const _CalendarEvent({
    required this.title,
    required this.timeRange,
    required this.compName,
    required this.statusName,
    required this.statusColor,
    required this.description,
  });
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
    if (events.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Text(
          'Bu gün için etkinlik yok',
          style: TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      );
    }

    final double itemExtent = 58;
    final double maxHeight = 200;
    final double listHeight = math.min(maxHeight, events.length * itemExtent);

    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${events.length} randevu',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              TextButton(
                onPressed: onOpenAll,
                child: const Text('Tümünü gör'),
              ),
            ],
          ),
          SizedBox(
            height: listHeight,
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 4, bottom: 4, right: 4),
              itemCount: events.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
              itemBuilder: (context, index) {
                final ev = events[index];
                return ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  leading: Icon(Icons.circle, size: 10, color: ev.statusColor),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ev.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: ev.statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          ev.statusName,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: ev.statusColor),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Row(
                    children: [
                      Expanded(
                        child: Text(
                          ev.compName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ev.timeRange,
                        style: const TextStyle(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailView(
                          title: ev.title,
                          companyName: ev.compName,
                          time: '${_CalendarViewState.formatDateTrPublic(date)} · ${ev.timeRange}',
                          statusName: ev.statusName,
                          statusColor: ev.statusColor,
                          description: ev.description,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
