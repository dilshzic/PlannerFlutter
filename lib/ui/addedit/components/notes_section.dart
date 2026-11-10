import 'package:flutter/material.dart';
import 'package:narwhal/ui/addedit/components/section_card.dart';

class NotesSection extends StatefulWidget {
  final String description;
  final ValueChanged<String> onDescriptionChange;

  const NotesSection({
    super.key,
    required this.description,
    required this.onDescriptionChange,
  });

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.description);
  }

  @override
  void didUpdateWidget(covariant NotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.description != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.description,
        selection: TextSelection.collapsed(offset: widget.description.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Notes',
      icon: Icons.description,
      child: TextField(
        controller: _controller,
        onChanged: widget.onDescriptionChange,
        maxLines: 8,
        decoration: const InputDecoration(
          hintText: 'Add some details...',
          border: InputBorder.none,
        ),
      ),
    );
  }
}
