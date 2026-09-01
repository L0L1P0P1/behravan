import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:intl/intl.dart';
import '../../../../data/database/app_database.dart';

class JalaliCalendarGrid extends StatefulWidget {
  final Jalali selectedDate;
  final ValueChanged<Jalali> onDaySelected;
  final Map<String, EnuresisLogEntity> logMap;

  const JalaliCalendarGrid({
    super.key,
    required this.selectedDate,
    required this.onDaySelected,
    required this.logMap,
  });

  @override
  State<JalaliCalendarGrid> createState() => _JalaliCalendarGridState();
}

class _JalaliCalendarGridState extends State<JalaliCalendarGrid> {
  late Jalali _displayMonth;

  @override
  void initState() {
    super.initState();
    // Initialize the calendar view to the currently selected date's month
    _displayMonth = widget.selectedDate.withDay(1);
  }

  void _nextMonth() {
    setState(() {
      int y = _displayMonth.year;
      int m = _displayMonth.month + 1;
      if (m > 12) {
        m = 1;
        y++;
      }
      _displayMonth = Jalali(y, m, 1);
    });
  }

  void _prevMonth() {
    setState(() {
      int y = _displayMonth.year;
      int m = _displayMonth.month - 1;
      if (m < 1) {
        m = 12;
        y--;
      }
      _displayMonth = Jalali(y, m, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Math Engine: Determine grid shift
    // weekDay in shamsi_date: 1 = Shanbe ... 7 = Jomeh
    final offset = _displayMonth.weekDay - 1;
    final daysInMonth = _displayMonth.monthLength;
    final totalGridCells = daysInMonth + offset;

    final formatter = _displayMonth.formatter;
    final weekDays = ['ش', 'ی', 'د', 'س', 'چ', 'پ', 'ج'];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header (Month/Year & Controls)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: _nextMonth,
            ),
            Text(
              '${formatter.mN} ${formatter.y}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_back_ios, size: 16),
              onPressed: _prevMonth,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Weekday Header Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: weekDays
              .map(
                (w) => Text(
                  w,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),

        // 3. The Responsive Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: totalGridCells,
          itemBuilder: (context, index) {
            // Render empty cells until we hit the first day of the month
            if (index < offset) return const SizedBox.shrink();

            final day = index - offset + 1;
            final currentDate = _displayMonth.withDay(day);
            final isSelected = currentDate == widget.selectedDate;

            // Bridge the UI back to the DB: Convert current grid cell to Gregorian 'yyyy-MM-dd'
            final gDate = currentDate.toDateTime();
            final dbKey = DateFormat('yyyy-MM-dd').format(gDate);
            final log = widget.logMap[dbKey];

            return GestureDetector(
              onTap: () => widget.onDaySelected(currentDate),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.blue.withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: isSelected
                      ? Border.all(color: Colors.blue, width: 1.5)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected
                            ? Colors.blue.shade800
                            : Colors.black87,
                      ),
                    ),
                    // Status dot rendering
                    if (log != null)
                      Container(
                        // FIX: Use EdgeInsets.only() instead of EdgeInsets.top()
                        margin: const EdgeInsets.only(top: 4),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: log.isDry
                              ? Colors.green
                              : Colors.amber.shade800,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
