import 'package:flutter/material.dart';

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

class OutlinedTextField extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      controller: TextEditingController(text: text)..selection = TextSelection.collapsed(offset: text.length),
      decoration: InputDecoration(
        hintText: "AI Quick Add (e.g. 'Study Cardio 2h')",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : null,
      ),
      onSubmitted: (_) => isLoading ? null : (text.isNotEmpty ? () => {} : null), // placeholder
    );
  }
}
