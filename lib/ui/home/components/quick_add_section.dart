import 'package:flutter/material.dart';
import 'package:narwhal/ui/components/narwhal_icon.dart';

class QuickAddSection extends StatelessWidget {
  final String text;
  final ValueChanged<String> onTextChange;
  final VoidCallback onAdd;
  final bool isLoading;

  const QuickAddSection({
    super.key,
    required this.text,
    required this.onTextChange,
    required this.onAdd,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedTextField(
              text: text,
              onChanged: onTextChange,
              isLoading: isLoading,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: onAdd,
            icon: const Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }
}

class OutlinedTextField extends StatefulWidget {
  final String text;
  final ValueChanged<String> onChanged;
  final bool isLoading;

  const OutlinedTextField({
    super.key,
    required this.text,
    required this.onChanged,
    required this.isLoading,
  });

  @override
  State<OutlinedTextField> createState() => _OutlinedTextFieldState();
}

class _OutlinedTextFieldState extends State<OutlinedTextField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }

  @override
  void didUpdateWidget(covariant OutlinedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.text,
        selection: TextSelection.collapsed(offset: widget.text.length),
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
    return TextField(
      onChanged: widget.onChanged,
      controller: _controller,
      decoration: InputDecoration(
        hintText: "Narwhal Quick Add (e.g. 'Study Cardio 2h')",
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12.0),
          child: NarwhalIcon(size: 20),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: widget.isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      onSubmitted: (_) => widget.isLoading ? null : (widget.text.isNotEmpty ? () => {} : null), // placeholder
    );
  }
}
