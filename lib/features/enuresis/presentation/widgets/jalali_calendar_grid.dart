import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
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

  void _jumpToToday(Jalali today) {
    setState(() => _displayMonth = today.withDay(1));
    widget.onDaySelected(today);
  }

  EnuresisLogEntity? _logFor(Jalali day) {
    // Bridge the UI back to the DB: Convert the cell to Gregorian 'yyyy-MM-dd'
    final dbKey = DateFormat('yyyy-MM-dd').format(day.toDateTime());
    return widget.logMap[dbKey];
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

    final today = Jalali.now();
    final isCurrentMonth =
        _displayMonth.year == today.year && _displayMonth.month == today.month;

    final monthLogs = [
      for (var day = 1; day <= daysInMonth; day++)
        ?_logFor(_displayMonth.withDay(day)),
    ];
    final dryCount = monthLogs.where((l) => l.isDry).length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Header (Month/Year & Controls). Back and forward icons mirror in
        // RTL, so "previous" sits at the start of the row pointing outward.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              tooltip: 'ماه قبل',
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
              onPressed: _prevMonth,
            ),
            Text(
              '${formatter.mN} ${formatter.y}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            IconButton(
              tooltip: 'ماه بعد',
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onPressed: isCurrentMonth ? null : _nextMonth,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 2. Weekday Header Row
        Row(
          children: weekDays
              .map(
                (w) => Expanded(
                  child: Text(
                    w,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 8),

        // 3. The Responsive Grid
        GridView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
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

            return _DayCell(
              day: day,
              log: _logFor(currentDate),
              isSelected: currentDate == widget.selectedDate,
              isToday: currentDate == today,
              isFuture: currentDate > today,
              onTap: () => widget.onDaySelected(currentDate),
            );
          },
        ),
        const SizedBox(height: 12),

        // 4. Legend doubling as this month's tally
        Row(
          children: [
            _LegendItem(
              icon: Icons.wb_sunny_rounded,
              color: AppColors.success,
              label: '$dryCount شب خشک',
            ),
            const SizedBox(width: 16),
            _LegendItem(
              icon: Icons.nightlight_round,
              color: AppColors.gentle,
              label: '${monthLogs.length - dryCount} شب خیس',
            ),
            const Spacer(),
            if (!isCurrentMonth)
              TextButton(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => _jumpToToday(today),
                child: const Text(
                  'برو به امروز',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final int day;
  final EnuresisLogEntity? log;
  final bool isSelected;
  final bool isToday;
  final bool isFuture;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.log,
    required this.isSelected,
    required this.isToday,
    required this.isFuture,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final log = this.log;
    final isDry = log?.isDry == true;

    final fill = log == null
        ? (isSelected ? AppColors.primarySoft : Colors.transparent)
        : (isDry ? AppColors.successSoft : AppColors.gentleSoft);
    final textColor = isFuture
        ? const Color(0xFFCBD5E1)
        : log == null
        ? AppColors.ink
        : (isDry ? AppColors.successDark : AppColors.gentleDark);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isFuture ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: isSelected || isToday
              ? Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF7DD3FC),
                  width: isSelected ? 2 : 1.2,
                )
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                height: 1.2,
                fontWeight: isSelected || isToday
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: textColor,
              ),
            ),
            // The icon keeps dry/wet readable without relying on color alone.
            if (log != null)
              Icon(
                isDry ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                size: 11,
                color: isDry ? AppColors.success : AppColors.gentle,
              ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.inkSoft,
          ),
        ),
      ],
    );
  }
}
