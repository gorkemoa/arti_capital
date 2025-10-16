import 'package:arti_capital/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/appointments_service.dart';
import '../models/appointment_models.dart';
import 'appointment_detail_view.dart';
import '../services/storage_service.dart';

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
  bool _isListView = false; // false = calendar view, true = list view
  final AppointmentsService _appointmentsService = AppointmentsService();
  final Map<DateTime, List<_CalendarEvent>> _eventsByDay = <DateTime, List<_CalendarEvent>>{};
  static const List<String> _weekdaysShortTr = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  static DateTime _stripTime(DateTime date) => DateTime(date.year, date.month, date.day);
  static DateTime _firstDayOfMonth(DateTime date) => DateTime(date.year, date.month, 1);
  static DateTime _lastDayOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);
  // Pazartesi=0 ... Pazar=6 döndür
  static int _weekdayFromMonday(int weekday) => weekday == DateTime.sunday ? 6 : weekday - 1;
  // no-op helpers removed

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
        final priorityColor = _parseStatusColor(item.priorityColor);
        list.add(
          _CalendarEvent(
            appointmentID: item.appointmentID,
            compID: item.compID,
            appointmentDateRaw: item.appointmentDate,
            title: item.appointmentTitle,
            timeRange: timeStr,
            compName: item.compName,
            statusName: item.statusName,
            statusColor: color,
            description: item.appointmentDesc,
            statusID: item.statusID,
            location: item.appointmentLocation,
            priority: item.appointmentPriority,
            priorityName: item.priorityName,
            priorityColor: priorityColor,
            logs: item.logs,
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
    final fallback = AppColors.primary;
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



  List<DateTime> _buildCalendarDays(DateTime month) {
    final List<DateTime> days = [];
    final first = _firstDayOfMonth(month);
    final last = _lastDayOfMonth(month);

    // Takvim haftası Pazartesi ile başlasın
    final leading = _weekdayFromMonday(first.weekday) - 1; // 0..6
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

  Widget _buildCalendarGrid(List<DateTime> days) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.builder(
        itemCount: days.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
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
                  ? Colors.black87
                  : Colors.black38;
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
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: txt,
                                fontWeight: FontWeight.w500,
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
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
    );
  }

  Widget _buildListView() {
    // Get all appointments sorted by date
    final List<MapEntry<DateTime, _CalendarEvent>> allAppointments = [];
    
    for (final entry in _eventsByDay.entries) {
      for (final event in entry.value) {
        allAppointments.add(MapEntry(entry.key, event));
      }
    }
    
    // Sort by date
    allAppointments.sort((a, b) => a.key.compareTo(b.key));
    
    if (allAppointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 28,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Henüz randevu yok',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Randevu eklemek için + butonunu kullanın',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    // Separate future/today and past appointments
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final upcomingAppointments = <MapEntry<DateTime, _CalendarEvent>>[];
    final pastAppointments = <MapEntry<DateTime, _CalendarEvent>>[];
    
    for (final entry in allAppointments) {
      if (entry.key.isBefore(today)) {
        pastAppointments.add(entry);
      } else {
        upcomingAppointments.add(entry);
      }
    }
    
    // Reverse past appointments to show most recent first
    pastAppointments.sort((a, b) => b.key.compareTo(a.key));
    
    // Group appointments by date
    final Map<DateTime, List<_CalendarEvent>> upcomingGrouped = {};
    for (final entry in upcomingAppointments) {
      upcomingGrouped.putIfAbsent(entry.key, () => []).add(entry.value);
    }
    
    final Map<DateTime, List<_CalendarEvent>> pastGrouped = {};
    for (final entry in pastAppointments) {
      pastGrouped.putIfAbsent(entry.key, () => []).add(entry.value);
    }
    
    final upcomingDates = upcomingGrouped.keys.toList()..sort();
    final pastDates = pastGrouped.keys.toList()..sort((a, b) => b.compareTo(a));
    
    final totalSections = upcomingDates.length + (pastDates.isNotEmpty ? pastDates.length + 1 : 0);
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: totalSections,
      itemBuilder: (context, index) {
        // Upcoming appointments
        if (index < upcomingDates.length) {
          final date = upcomingDates[index];
          final events = upcomingGrouped[date]!;
          final dateLabel = _getDateLabel(date);
          
          return _buildDateSection(date, events, dateLabel, index == 0, false);
        }
        
        // "Geçmiş" header
        if (index == upcomingDates.length && pastDates.isNotEmpty) {
          return Padding(
            padding: const EdgeInsets.only(top: 20, bottom: 8),
            child: Text(
              'Geçmiş',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                height: 1.0,
              ),
            ),
          );
        }
        
        // Past appointments
        final pastIndex = index - upcomingDates.length - 1;
        final date = pastDates[pastIndex];
        final events = pastGrouped[date]!;
        final dateLabel = _getDateLabel(date);
        
        return _buildDateSection(date, events, dateLabel, false, true);
      },
    );
  }
  
  Widget _buildDateSection(DateTime date, List<_CalendarEvent> events, String dateLabel, bool isFirst, bool isPast) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tarih başlığı - iOS tarzı
        Padding(
          padding: EdgeInsets.only(left: 0, top: isFirst ? 6 : 12, bottom: 4),
          child: Text(
            dateLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 18,
              color: isPast ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5) : Theme.of(context).colorScheme.onSurface,
              height: 1.0,
            ),
          ),
        ),
        
        // Randevular listesi
        ...events.map((event) {
          return GestureDetector(
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AppointmentDetailView(
                    title: event.title,
                    companyName: event.compName,
                    time: '${formatDateTr(date)} · ${event.timeRange}',
                    statusName: event.statusName,
                    statusColor: event.statusColor,
                    description: event.description,
                    appointmentID: event.appointmentID,
                    compID: event.compID,
                    appointmentDateRaw: event.appointmentDateRaw,
                    statusID: event.statusID,
                    location: event.location,
                    priority: event.priority,
                    priorityName: event.priorityName,
                    priorityColor: event.priorityColor,
                    logs: event.logs,
                  ),
                ),
              );
              if (result == true) {
                await _fetchAppointments();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.12),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // Sol - Checkbox (durum rengi)
                  Container(
                    width: 18,
                    height: 18,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isPast ? event.statusColor.withOpacity(0.4) : event.statusColor,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: isPast ? event.statusColor.withOpacity(0.4) : event.statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  
                  // Orta - İçerik
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: isPast ? Theme.of(context).colorScheme.onSurface.withOpacity(0.4) : Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '${event.timeRange} · ${event.compName}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            color: isPast ? Theme.of(context).colorScheme.onSurface.withOpacity(0.25) : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                  // Sağ - Durum badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPast ? event.statusColor.withOpacity(0.08) : event.statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      event.statusName,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontSize: 9,
                        color: isPast ? event.statusColor.withOpacity(0.6) : event.statusColor,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
  
  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    if (targetDate == today) {
      return 'Bugün';
    } else {
      const months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      final monthName = months[date.month - 1];
      final dayName = _weekdaysShortTr[_weekdayFromMonday(date.weekday)];
      return '${date.day} $monthName $dayName';
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _buildCalendarDays(_currentMonth);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: () {
              setState(() {
                _isListView = !_isListView;
              });
            },
            icon: Icon(
              _isListView ? Icons.calendar_month : Icons.view_list,
              color: AppColors.onPrimary,
            ),
            tooltip: _isListView ? 'Takvim Görünümü' : 'Liste Görünümü',
          ),
        ),
        title: Text(
          'Takvim',
          style: TextStyle(
            fontSize: Theme.of(context).appBarTheme.titleTextStyle?.fontSize,
            fontWeight: FontWeight.w600,
            color: AppColors.onPrimary,
          ),
        ),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.onPrimary),
            actions: [
          if (StorageService.hasPermission('appointments', 'add'))
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: TextButton(
                onPressed: () async {
                  // Yeni randevu eklendikten sonra takvimi yenilemek için await kullan
                  final shouldRefresh = await Navigator.of(context).pushNamed('/new-appointment');
                  // True döndüyse randevuları yenile
                  if (shouldRefresh == true) {
                    _fetchAppointments();
                  }
                },
                style: TextButton.styleFrom(backgroundColor: Colors.white, 
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.all(6),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add, size: 15, color: AppColors.primary),
                    const SizedBox(width: 6),
                    const Text('Randevu Ekle', style: TextStyle(fontSize: 12, color: AppColors.primary),),
                  ],
                ),
              ),
            ),



  ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Sol taraf - geri butonu (sadece takvim modunda)
                  if (!_isListView)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 32),
                
                  // Orta - ay/yıl veya başlık
                  GestureDetector(
                    onTap: _isListView ? null : _openMonthPicker,
                    child: Column(
                      children: [
                        Text(
                          _isListView ? 'Randevular' : _monthNameTr(_currentMonth.month),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (!_isListView)
                          Text(
                            _currentMonth.year.toString(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.black54,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Sağ taraf - ileri butonu
                  if (!_isListView)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 32),
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
            
            // Content area - switches between calendar and list view
            Expanded(
              child: _isListView ? _buildListView() : Column(
                children: [
                  // Weekday headers (only in calendar mode)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: _weekdaysShortTr.map((w) => _WeekdayLabel(w)).toList(),
                    ),
                  ),
                  
                  // Calendar Grid
                  Expanded(
                    flex: 2,
                    child: _buildCalendarGrid(days),
                  ),
                ],
              ),
            ),
            
            // Selected events (only in calendar mode)
            if (!_isListView)
              Expanded(
                flex: 1,
                child: Container(
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
                    events: _eventsByDay[_selectedDate] ?? const <_CalendarEvent>[],
                    onOpenAll: () => _openEventsBottomSheet(context, _selectedDate, _eventsByDay[_selectedDate] ?? const <_CalendarEvent>[]),
                    onRefresh: _fetchAppointments,
                    showSeeAll: false,
                    fillAvailable: true,
                  ),
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
                      Icon(Icons.event, color: AppColors.primary, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        'Etkinlikler · $title', 
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                if (events.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    child: Text(
                      'Bu gün için etkinlik yok',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          leading: CircleAvatar(
                            radius: 16,
                            backgroundColor: ev.statusColor.withOpacity(0.15),
                            child: Icon(
                              Icons.event_note, 
                              size: 16, 
                              color: ev.statusColor,
                            ),
                          ),
                          title: Text(
                            ev.title, 
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
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
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: ev.statusColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              ev.statusName,
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                fontSize: 11,
                                color: ev.statusColor,
                              ),
                            ),
                          ),
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AppointmentDetailView(
                                  title: ev.title,
                                  companyName: ev.compName,
                                  time: '${_CalendarViewState.formatDateTrPublic(date)} · ${ev.timeRange}',
                                  statusName: ev.statusName,
                                  statusColor: ev.statusColor,
                                  description: ev.description,
                                  appointmentID: ev.appointmentID,
                                  compID: ev.compID,
                                  appointmentDateRaw: ev.appointmentDateRaw,
                                  statusID: ev.statusID,
                                  location: ev.location,
                                  priority: ev.priority,
                                  priorityName: ev.priorityName,
                                  priorityColor: ev.priorityColor,
                                  logs: ev.logs,
                                ),
                              ),
                            );
                            if (result == true) {
                              await _fetchAppointments();
                            }
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

  // eski diyalog kaldırıldı; FAB doğrudan yeni sayfaya gidiyor

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
    final int idx = _weekdayFromMonday(d.weekday); // 0..6
    return '${_weekdaysShortTr[idx]}, ${d.day} ${months[d.month - 1]}';
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
      width: 32,
      child: Center(
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _CalendarEvent {
  final int appointmentID;
  final int compID;
  final String appointmentDateRaw;
  final String title;
  final String timeRange;
  final String compName;
  final String statusName;
  final Color statusColor;
  final String description;
  final int statusID;
  final String location;
  final int priority;
  final String priorityName;
  final Color priorityColor;
  final List<AppointmentLog> logs;

  const _CalendarEvent({
    required this.appointmentID,
    required this.compID,
    required this.appointmentDateRaw,
    required this.title,
    required this.timeRange,
    required this.compName,
    required this.statusName,
    required this.statusColor,
    required this.description,
    required this.statusID,
    required this.location,
    required this.priority,
    required this.priorityName,
    required this.priorityColor,
    required this.logs,
  });
}

class _InlineSelectedEvents extends StatelessWidget {
  const _InlineSelectedEvents({
    required this.date, 
    required this.events, 
    required this.onOpenAll,
    this.onRefresh,
    this.showSeeAll = true,
    this.fillAvailable = false,
  });
  final DateTime date;
  final List<_CalendarEvent> events;
  final VoidCallback onOpenAll;
  final Future<void> Function()? onRefresh;
  final bool showSeeAll;
  final bool fillAvailable;

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
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${events.length} randevu',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (showSeeAll)
                TextButton(
                  onPressed: onOpenAll,
                  child: const Text('Tümünü gör'),
                ),
            ],
          ),
          if (fillAvailable)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.only(top: 4, bottom: 4, right: 4),
                itemCount: events.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
                itemBuilder: (context, index) {
                  final ev = events[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    leading: Icon(Icons.circle, size: 8, color: ev.statusColor),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            ev.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: ev.statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ev.statusName,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontSize: 10,
                              color: ev.statusColor,
                            ),
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
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ev.timeRange,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => AppointmentDetailView(
                            title: ev.title,
                            companyName: ev.compName,
                            time: '${_CalendarViewState.formatDateTrPublic(date)} · ${ev.timeRange}',
                            statusName: ev.statusName,
                            statusColor: ev.statusColor,
                            description: ev.description,
                            appointmentID: ev.appointmentID,
                            compID: ev.compID,
                            appointmentDateRaw: ev.appointmentDateRaw,
                            statusID: ev.statusID,
                            location: ev.location,
                            priority: ev.priority,
                            priorityName: ev.priorityName,
                            priorityColor: ev.priorityColor,
                            logs: ev.logs,
                          ),
                        ),
                      );
                      if (result == true && onRefresh != null) {
                        await onRefresh!();
                      }
                    },
                  );
                },
              ),
            )
          else
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
                  onTap: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AppointmentDetailView(
                          title: ev.title,
                          companyName: ev.compName,
                          time: '${_CalendarViewState.formatDateTrPublic(date)} · ${ev.timeRange}',
                          statusName: ev.statusName,
                          statusColor: ev.statusColor,
                          description: ev.description,
                          appointmentID: ev.appointmentID,
                          compID: ev.compID,
                          appointmentDateRaw: ev.appointmentDateRaw,
                          statusID: ev.statusID,
                          location: ev.location,
                          priority: ev.priority,
                          priorityName: ev.priorityName,
                          priorityColor: ev.priorityColor,
                          logs: ev.logs,
                        ),
                      ),
                    );
                    if (result == true && onRefresh != null) {
                      await onRefresh!();
                    }
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
