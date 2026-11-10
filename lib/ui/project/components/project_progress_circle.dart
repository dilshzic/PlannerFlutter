import 'package:flutter/material.dart';

class ProjectProgressCircle extends StatelessWidget {
  final double percentage;
  final double size;

  const ProjectProgressCircle({
    super.key,
    required this.percentage,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), width: 8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percentage,
              strokeWidth: 8,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(percentage * 100).toInt()}%',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: size / 4),
          ),
        ],
      ),
    );
  }
}
