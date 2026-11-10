import 'package:flutter/material.dart';
import 'package:narwhal/ui/addedit/components/section_card.dart';
import 'package:narwhal/ui/addedit/components/date_time_picker.dart';
import 'package:narwhal/ui/addedit/components/duration_selector.dart';

class SchedulingSection extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final int durationMinutes;
  final bool isCustomDuration;
  final ValueChanged<DateTime> onDateChange;
  final ValueChanged<TimeOfDay> onTimeChange;
  final void Function(int, {bool isCustom}) setDuration;
  final VoidCallback clearSchedule;

  const SchedulingSection({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.durationMinutes,
    required this.isCustomDuration,
    required this.onDateChange,
    required this.onTimeChange,
    required this.setDuration,
    required this.clearSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Scheduling',
      icon: Icons.event_note,
      action: selectedDate != null 
          ? TextButton.icon(
              onPressed: clearSchedule,
              icon: const Icon(Icons.close, size: 14),
              label: const Text('UNSCHEDULE', style: TextStyle(fontSize: 10)),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DateTimePicker(
            selectedDate: selectedDate,
            selectedTime: selectedTime,
            onDateChange: onDateChange,
            onTimeChange: onTimeChange,
          ),
          const Divider(height: 32),
          const Text('Estimation', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DurationSelector(
            durationMinutes: durationMinutes,
            isCustomDuration: isCustomDuration,
            setDuration: setDuration,
          ),
        ],
      ),
    );
  }
}
