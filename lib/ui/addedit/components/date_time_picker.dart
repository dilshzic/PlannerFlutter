import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimePicker extends StatelessWidget {
  final DateTime? selectedDate;
  final TimeOfDay? selectedTime;
  final ValueChanged<DateTime> onDateChange;
  final ValueChanged<TimeOfDay> onTimeChange;

  const DateTimePicker({
    super.key,
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateChange,
    required this.onTimeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Date', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: Text(
              selectedDate == null ? 'Not set' : DateFormat('MMM dd, yyyy').format(selectedDate!),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
              );
              if (date != null) onDateChange(date);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.access_time),
            title: const Text('Time', style: TextStyle(fontSize: 12, color: Colors.grey)),
            subtitle: Text(
              selectedTime == null ? 'Not set' : selectedTime!.format(context),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: selectedTime ?? TimeOfDay.now(),
              );
              if (time != null) onTimeChange(time);
            },
          ),
        ),
      ],
    );
  }
}
