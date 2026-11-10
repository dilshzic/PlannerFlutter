import 'package:flutter/material.dart';
import 'package:narwhal/ui/addedit/components/section_card.dart';
import 'package:narwhal/ui/addedit/components/priority_selector.dart';

class MainInfoSection extends StatefulWidget {
  final String title;
  final int priority;
  final ValueChanged<String> onTitleChange;
  final ValueChanged<int> onPriorityChange;

  const MainInfoSection({
    super.key,
    required this.title,
    required this.priority,
    required this.onTitleChange,
    required this.onPriorityChange,
  });

  @override
  State<MainInfoSection> createState() => _MainInfoSectionState();
}

class _MainInfoSectionState extends State<MainInfoSection> {
  late final TextEditingController _titleController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
  }

  @override
  void didUpdateWidget(covariant MainInfoSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.title != _titleController.text) {
      _titleController.value = TextEditingValue(
        text: widget.title,
        selection: TextSelection.collapsed(offset: widget.title.length),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Main Info',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            onChanged: widget.onTitleChange,
            decoration: const InputDecoration(
              hintText: 'Task Title',
              border: InputBorder.none,
            ),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          PrioritySelector(
            priority: widget.priority,
            onPriorityChange: widget.onPriorityChange,
          ),
        ],
      ),
    );
  }
}
