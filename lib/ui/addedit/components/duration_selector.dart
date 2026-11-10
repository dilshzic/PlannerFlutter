import 'package:flutter/material.dart';

class DurationSelector extends StatelessWidget {
  final int durationMinutes;
  final bool isCustomDuration;
  final void Function(int, {bool isCustom}) setDuration;

  const DurationSelector({
    super.key,
    required this.durationMinutes,
    required this.isCustomDuration,
    required this.setDuration,
  });

  @override
  Widget build(BuildContext context) {
    final presets = [0, 1, 2, 5];
    
    return Column(
      children: [
        Row(
          children: [
            ...presets.map((p) {
              final isSelected = durationMinutes == p && !isCustomDuration;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text('${p}m'),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setDuration(p, isCustom: false);
                  },
                ),
              );
            }),
            ChoiceChip(
              label: const Text('Custom'),
              selected: isCustomDuration,
              onSelected: (val) {
                setDuration(durationMinutes, isCustom: val);
              },
            ),
          ],
        ),
        if (isCustomDuration) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$durationMinutes min', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: durationMinutes.toDouble(),
            min: 0,
            max: 120,
            divisions: 24,
            onChanged: (value) => setDuration(value.round(), isCustom: true),
          ),
        ],
      ],
    );
  }
}
