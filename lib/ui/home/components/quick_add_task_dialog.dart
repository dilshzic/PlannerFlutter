import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_core_entities/category.dart';

class QuickAddTaskDialog extends StatefulWidget {
  final List<Category> categories;
  final Function(String title, String? categoryId, DateTime? date, int priority, String? colorHex) onConfirm;
  final Function(String title) onEditMore;
  final VoidCallback onDismiss;

  const QuickAddTaskDialog({
    super.key,
    required this.categories,
    required this.onConfirm,
    required this.onEditMore,
    required this.onDismiss,
  });

  @override
  State<QuickAddTaskDialog> createState() => _QuickAddTaskDialogState();
}

class _QuickAddTaskDialogState extends State<QuickAddTaskDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _selectedCategoryId;
  DateTime? _selectedDate = DateTime.now();
  int _priority = 1;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bolt, color: Colors.amber),
                const SizedBox(width: 8),
                Text('Quick Add Task', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'What needs to be done?',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionRow(context),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => widget.onEditMore(_controller.text),
                  child: const Text('EDIT MORE'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      widget.onConfirm(
                        _controller.text,
                        _selectedCategoryId,
                        _selectedDate,
                        _priority,
                        null, // Color is now strictly from project
                      );
                      widget.onDismiss();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('ADD TASK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Category Picker
        _buildChip(
          icon: Icons.label_outline,
          label: _selectedCategoryId != null 
              ? widget.categories.firstWhere((c) => c.id == _selectedCategoryId).name 
              : 'Category',
          onTap: _showCategoryPicker,
        ),
        // Date Picker
        _buildChip(
          icon: Icons.calendar_today,
          label: _selectedDate == null ? 'Schedule' : DateFormat('MMM d').format(_selectedDate!),
          onTap: _showDatePicker,
        ),
        // Priority Picker
        _buildChip(
          icon: Icons.priority_high,
          label: 'P$_priority',
          onTap: _cyclePriority,
          color: _getPriorityColor(_priority),
        ),
      ],
    );
  }

  Widget _buildChip({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color?.withOpacity(0.1) ?? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color?.withOpacity(0.5) ?? Colors.transparent),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color ?? Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => ListView.builder(
        shrinkWrap: true,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          final cat = widget.categories[index];
          return ListTile(
            leading: const Icon(Icons.label),
            title: Text(cat.name),
            onTap: () {
              setState(() => _selectedCategoryId = cat.id);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _cyclePriority() {
    setState(() {
      _priority = _priority % 4 + 1;
    });
  }

  Color _getPriorityColor(int p) {
    switch (p) {
      case 1: return Colors.green;
      case 2: return Colors.blue;
      case 3: return Colors.orange;
      default: return Colors.red;
    }
  }
}
