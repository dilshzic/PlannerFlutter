import 'package:flutter/material.dart';
import 'package:flutter_core_entities/task_node.dart';
import 'package:narwhal/data/repository/task_node_repository.dart';
import 'package:narwhal/services/ai/project_agent_service.dart';
import 'package:narwhal/ui/ai/components/chat_message.dart';

class ProjectAgentViewModel extends ChangeNotifier {
  final TaskNodeRepository _nodeRepo;
  final ProjectAgentService _agentService;
  final TaskNode project;

  List<TaskNode> _projectTasks = [];
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  // Breakdown Checklist State
  List<String> _suggestedTasks = [];
  List<bool> _selectedSuggestedTasks = [];
  bool _showBreakdownChecklist = false;

  ProjectAgentViewModel(this._nodeRepo, this._agentService, this.project) {
    _loadTasks();
    _messages.add(ChatMessage(
      text: "Hello! I am Narwhal, your Project AI Copilot. I have full context of this project's tasks, notes, and timeline. What would you like to plan or analyze today?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  List<String> get suggestedTasks => _suggestedTasks;
  List<bool> get selectedSuggestedTasks => _selectedSuggestedTasks;
  bool get showBreakdownChecklist => _showBreakdownChecklist;
  List<TaskNode> get projectTasks => _projectTasks;

  Future<void> _loadTasks() async {
    _projectTasks = await _nodeRepo.getDescendantsOf(project.id);
    notifyListeners();
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _showBreakdownChecklist = false; // Hide old breakdown checklist when user enters a new query
    notifyListeners();

    // Construct chat history (excluding current user query and helper/status messages)
    final historyList = _messages
        .sublist(0, _messages.length - 1)
        .where((m) =>
            !m.text.startsWith("Hello!") &&
            !m.text.startsWith("✅ Added") &&
            !m.text.startsWith("Here is a suggested checklist"))
        .map((m) => {
              'role': m.isUser ? 'user' : 'model',
              'text': m.text,
            })
        .toList();

    // Limit to context window of last 10 messages
    final limitedHistory = historyList.length > 10
        ? historyList.sublist(historyList.length - 10)
        : historyList;

    try {
      await _loadTasks(); // Get latest tasks
      final response = await _agentService.askAboutProject(
        project,
        _projectTasks,
        text,
        history: limitedHistory,
      );

      var responseText = response.text;

      // Parse commands
      final addTaskRegex = RegExp(r'\[ADD_TASK:\s*(.*?)\]');
      final completeTaskRegex = RegExp(r'\[COMPLETE_TASK:\s*(.*?)\]');

      final addMatches = addTaskRegex.allMatches(responseText);
      final completeMatches = completeTaskRegex.allMatches(responseText);

      // Execute ADD_TASK
      for (final match in addMatches) {
        final taskTitle = match.group(1)?.trim();
        if (taskTitle != null && taskTitle.isNotEmpty) {
          final node = TaskNode(
            title: taskTitle,
            parentId: project.id,
            nodeType: NodeType.task,
          );
          await _nodeRepo.upsertNode(node);
        }
      }

      // Execute COMPLETE_TASK
      for (final match in completeMatches) {
        final query = match.group(1)?.trim();
        if (query != null && query.isNotEmpty) {
          final allProjectNodes = await _nodeRepo.getDescendantsOf(project.id);
          // Find matching task node
          final matchingNode = allProjectNodes.firstWhere(
            (n) => n.id == query || n.title.toLowerCase().trim() == query.toLowerCase().trim(),
            orElse: () => allProjectNodes.firstWhere(
              (n) => n.title.toLowerCase().contains(query.toLowerCase()),
              orElse: () => TaskNode(title: '', nodeType: NodeType.task), // Dummy
            ),
          );
          if (matchingNode.id.isNotEmpty) {
            await _nodeRepo.toggleNodeCompletion(matchingNode.id, true);
          }
        }
      }

      // Clean the response text from the tags for beautiful display
      responseText = responseText
          .replaceAll(addTaskRegex, '')
          .replaceAll(completeTaskRegex, '')
          .trim();

      _messages.add(ChatMessage(
        text: responseText.isEmpty ? 'Action performed successfully!' : responseText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      await _loadTasks(); // Update the local task hierarchy
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Error executing command: $e",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> analyzeSchedule() async {
    if (_isLoading) return;

    _messages.add(ChatMessage(
      text: "🔍 Analyze Timeline & Conflicts",
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _showBreakdownChecklist = false;
    notifyListeners();

    try {
      await _loadTasks();
      final analysis = await _agentService.analyzeTimelineAndConflicts(project, _projectTasks);
      _messages.add(ChatMessage(
        text: analysis,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Error analyzing schedule: $e",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> suggestBreakdown(String topic) async {
    if (_isLoading) return;

    _messages.add(ChatMessage(
      text: "📝 Suggest Task Breakdown for: $topic",
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _isLoading = true;
    _showBreakdownChecklist = false;
    notifyListeners();

    try {
      await _loadTasks();
      final suggestions = await _agentService.suggestTaskBreakdown(project, _projectTasks, topic);
      if (suggestions.isEmpty) {
        _messages.add(ChatMessage(
          text: "I couldn't generate any subtask suggestions for this topic. Please try again.",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      } else {
        _suggestedTasks = suggestions;
        _selectedSuggestedTasks = List<bool>.filled(suggestions.length, true);
        _showBreakdownChecklist = true;
        _messages.add(ChatMessage(
          text: "Here is a suggested checklist of tasks to add to the project. You can check the ones you want to add below:",
          isUser: false,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Error generating task breakdown: $e",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void toggleSuggestedTaskSelection(int index, bool selected) {
    _selectedSuggestedTasks[index] = selected;
    notifyListeners();
  }

  Future<void> addSelectedTasksToProject() async {
    final List<String> tasksToAdd = [];
    for (int i = 0; i < _suggestedTasks.length; i++) {
      if (_selectedSuggestedTasks[i]) {
        tasksToAdd.add(_suggestedTasks[i]);
      }
    }

    if (tasksToAdd.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      for (final title in tasksToAdd) {
        final node = TaskNode(
          title: title,
          parentId: project.id,
          nodeType: NodeType.task,
        );
        await _nodeRepo.upsertNode(node);
      }

      _showBreakdownChecklist = false;
      _messages.add(ChatMessage(
        text: "✅ Added ${tasksToAdd.length} tasks to the project!",
        isUser: false,
        timestamp: DateTime.now(),
      ));
      await _loadTasks(); // Update local task lists
    } catch (e) {
      _messages.add(ChatMessage(
        text: "Failed to add tasks: $e",
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void dismissBreakdown() {
    _showBreakdownChecklist = false;
    notifyListeners();
  }

  void clearChat() {
    _messages.clear();
    _suggestedTasks.clear();
    _selectedSuggestedTasks.clear();
    _showBreakdownChecklist = false;
    _messages.add(ChatMessage(
      text: "Chat cleared! How can I assist you with this project now?",
      isUser: false,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
