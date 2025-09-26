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
      // Seçili gün yeni ayda yoksa ay sonuna sabitle
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
    final theme = Theme.of(context);
    final days = _buildCalendarDays(_currentMonth);

    final monthTitle = _monthNameTr(_currentMonth.month);
    final year = _currentMonth.year.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text('Takvim', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimary)),
        centerTitle: true,
        foregroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(color: theme.colorScheme.primary),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Row(
              children: [
                IconButton(onPressed: _goToPrevMonth, tooltip: 'Önceki ay', icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: _openMonthPicker,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$monthTitle $year', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                      ],
                    ),
                  ),
                ),
                IconButton(onPressed: _goToNextMonth, tooltip: 'Sonraki ay', icon: const Icon(Icons.chevron_right)),
                const SizedBox(width: 6),
                TextButton.icon(
                  onPressed: _goToToday,
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                  icon: const Icon(Icons.today, size: 18),
                  label: const Text('Bugün'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _WeekdayLabel('PZT'),
                _WeekdayLabel('SAL'),
                _WeekdayLabel('ÇAR'),
                _WeekdayLabel('PER'),
                _WeekdayLabel('CUM'),
                _WeekdayLabel('CMT'),
                _WeekdayLabel('PAZ'),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragEnd: (details) {
                final v = details.primaryVelocity ?? 0;
                if (v > 200) {
                  _goToPrevMonth();
                } else if (v < -200) {
                  _goToNextMonth();
                }
              },
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                itemCount: days.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                ),
                itemBuilder: (context, index) {
                  final day = days[index];
                  final isCurrentMonth = day.month == _currentMonth.month;
                  final isToday = _stripTime(day) == _stripTime(DateTime.now());
                  final isSelected = _stripTime(day) == _selectedDate;
                  final events = mockEventsFor(day);
                  final hasEvents = events.isNotEmpty;

                  Color border = isSelected ? theme.colorScheme.primary : theme.dividerColor.withOpacity(0.25);
                  Color bg = isSelected
                      ? theme.colorScheme.primary.withOpacity(0.10)
                      : isCurrentMonth
                          ? theme.colorScheme.surface
                          : theme.colorScheme.surfaceVariant.withOpacity(0.35);
                  Color txt = isCurrentMonth
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withOpacity(0.6);

                  return InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      setState(() {
                        _selectedDate = _stripTime(day);
                        _currentMonth = _firstDayOfMonth(day);
                      });
                      _openEventsBottomSheet(context, day, events);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('${day.day}', style: theme.textTheme.bodyMedium?.copyWith(color: txt)),
                                if (isToday) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.circle, size: 6, color: theme.colorScheme.secondary),
                                ],
                              ],
                            ),
                            const Spacer(),
                            if (hasEvents)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  events.length > 3 ? 3 : events.length,
                                  (i) => Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.secondary,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          _InlineSelectedEvents(
            date: _selectedDate,
            events: mockEventsFor(_selectedDate),
            onOpenAll: () => _openEventsBottomSheet(context, _selectedDate, mockEventsFor(_selectedDate)),
          ),
        ],
      ),
    );
  }

  void _goToToday() {
    setState(() {
      final now = DateTime.now();
      _selectedDate = _stripTime(now);
      _currentMonth = _firstDayOfMonth(now);
    });
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
    final theme = Theme.of(context);
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
                      Icon(Icons.event, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Etkinlikler · $title', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Text('Bu gün için etkinlik yok', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor)),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
                      itemCount: events.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: theme.dividerColor.withOpacity(0.3)),
                      itemBuilder: (context, index) {
                        final ev = events[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                            child: Icon(Icons.event_note, size: 18, color: theme.colorScheme.primary),
                          ),
                          title: Text(ev.title, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(ev.timeRange, style: theme.textTheme.bodySmall),
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

  String formatDateTr(DateTime d) {
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    const weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    int weekdayFromMonday(int weekday) => weekday == DateTime.sunday ? 6 : weekday - 2;
    return '${weekdays[weekdayFromMonday(d.weekday)]}, ${d.day} ${months[d.month - 1]}';
  }

  List<_CalendarEvent> mockEventsFor(DateTime d) {
    final int day = d.day;
    if (day % 7 == 5) {
      return const [
        _CalendarEvent('Müşteri Görüşmesi', '10:00 - 11:30'),
        _CalendarEvent('Teklif Değerlendirme', '14:00 - 15:00'),
      ];
    }
    if (day % 7 == 1) {
      return const [
        _CalendarEvent('Bordro Kontrol', '09:00 - 10:00'),
      ];
    }
    if (day % 7 == 3) {
      return const [
        _CalendarEvent('Ekip Toplantısı', '16:00 - 17:00'),
        _CalendarEvent('Rapor Gönderimi', '17:30 - 18:00'),
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
    final theme = Theme.of(context);
    return SizedBox(
      width: 36,
      child: Center(
        child: Text(
          text,
          style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.hintColor),
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
  const _InlineSelectedEvents({required this.date, required this.events, required this.onOpenAll});
  final DateTime date;
  final List<_CalendarEvent> events;
  final VoidCallback onOpenAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = _formatDateTr(date);

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
        color: theme.colorScheme.surface,
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onOpenAll,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.event, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Etkinlikler · $title',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text('Tümü', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_up_rounded, color: theme.colorScheme.primary),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (events.isEmpty)
                      Text('Bu gün için etkinlik yok', style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor))
                    else ...[
                      ...events.take(2).map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '${e.title} · ${e.timeRange}',
                                    style: theme.textTheme.bodyMedium,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )),
                      if (events.length > 2)
                        Text('+${events.length - 2} daha', style: theme.textTheme.labelMedium?.copyWith(color: theme.hintColor)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDateTr(DateTime d) {
  const months = [
    'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
    'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
  ];
  const weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
  int weekdayFromMonday(int weekday) => weekday == DateTime.sunday ? 6 : weekday - 2;
  return '${weekdays[weekdayFromMonday(d.weekday)]}, ${d.day} ${months[d.month - 1]}';
}


