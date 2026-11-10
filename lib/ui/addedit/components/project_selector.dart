import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/ui/addedit/components/section_card.dart';

class ProjectSelector extends StatelessWidget {
  final String? parentId;
  final List<TaskNode> availableProjects;
  final ValueChanged<String?> onParentChange;

  const ProjectSelector({
    super.key,
    required this.parentId,
    required this.availableProjects,
    required this.onParentChange,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Project',
      icon: Icons.folder,
      child: DropdownButtonFormField<String?>(
        value: availableProjects.any((p) => p.id == parentId) ? parentId : null,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Select Project',
        ),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('None (Inbox/General)'),
          ),
          ...availableProjects.map((p) => DropdownMenuItem<String?>(
            value: p.id,
            child: Text(p.title),
          )),
        ],
        onChanged: onParentChange,
      ),
    );
  }
}
