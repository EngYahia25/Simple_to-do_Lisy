import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/storage_service.dart';

enum TaskFilter { all, active, completed }

enum TaskSort { dateNewest, dateOldest, priorityHigh, priorityLow }

class TaskProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();

  List<Task> _tasks = [];
  String _searchQuery = '';
  TaskFilter _filter = TaskFilter.all;
  TaskSort _sort = TaskSort.dateNewest;
  TaskCategory? _categoryFilter;
  bool _isDarkMode = false;
  bool _isLoaded = false;

  // ── Getters ────────────────────────────────────────────────────────────
  List<Task> get tasks => _filteredTasks;
  List<Task> get allTasks => List.unmodifiable(_tasks);
  String get searchQuery => _searchQuery;
  TaskFilter get filter => _filter;
  TaskSort get sort => _sort;
  TaskCategory? get categoryFilter => _categoryFilter;
  bool get isDarkMode => _isDarkMode;
  bool get isLoaded => _isLoaded;

  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  int get activeCount => _tasks.where((t) => !t.isCompleted).length;

  double get completionPercentage =>
      _tasks.isEmpty ? 0 : completedCount / totalCount;

  // ── Filtered & Sorted List ─────────────────────────────────────────────
  List<Task> get _filteredTasks {
    var result = List<Task>.from(_tasks);

    // Search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result
          .where((t) =>
              t.title.toLowerCase().contains(q) ||
              t.description.toLowerCase().contains(q))
          .toList();
    }

    // Filter
    switch (_filter) {
      case TaskFilter.active:
        result = result.where((t) => !t.isCompleted).toList();
        break;
      case TaskFilter.completed:
        result = result.where((t) => t.isCompleted).toList();
        break;
      case TaskFilter.all:
        break;
    }

    // Category
    if (_categoryFilter != null) {
      result = result.where((t) => t.category == _categoryFilter).toList();
    }

    // Sort
    switch (_sort) {
      case TaskSort.dateNewest:
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case TaskSort.dateOldest:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case TaskSort.priorityHigh:
        result.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case TaskSort.priorityLow:
        result.sort((a, b) => a.priority.index.compareTo(b.priority.index));
        break;
    }

    return result;
  }

  // ── Init ───────────────────────────────────────────────────────────────
  Future<void> init() async {
    _tasks = await _storageService.loadTasks();
    _isDarkMode = await _storageService.loadDarkMode();
    _isLoaded = true;
    notifyListeners();
  }

  // ── CRUD ───────────────────────────────────────────────────────────────
  Future<void> addTask(Task task) async {
    _tasks.insert(0, task);
    notifyListeners();
    await _storageService.saveTasks(_tasks);
  }

  Future<void> updateTask(Task updatedTask) async {
    final idx = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (idx != -1) {
      _tasks[idx] = updatedTask;
      notifyListeners();
      await _storageService.saveTasks(_tasks);
    }
  }

  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
    await _storageService.saveTasks(_tasks);
  }

  Future<void> toggleComplete(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _tasks[idx].isCompleted = !_tasks[idx].isCompleted;
      _tasks[idx].completedAt =
          _tasks[idx].isCompleted ? DateTime.now() : null;
      notifyListeners();
      await _storageService.saveTasks(_tasks);
    }
  }

  // Undo support — re‑insert at original position
  Future<void> insertTaskAt(int index, Task task) async {
    _tasks.insert(index.clamp(0, _tasks.length), task);
    notifyListeners();
    await _storageService.saveTasks(_tasks);
  }

  int indexOfTask(String id) => _tasks.indexWhere((t) => t.id == id);

  // ── Filters / Sort ────────────────────────────────────────────────────
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter(TaskFilter filter) {
    _filter = filter;
    notifyListeners();
  }

  void setCategoryFilter(TaskCategory? category) {
    _categoryFilter = category;
    notifyListeners();
  }

  void setSort(TaskSort sort) {
    _sort = sort;
    notifyListeners();
  }

  // ── Theme ──────────────────────────────────────────────────────────────
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    await _storageService.saveDarkMode(_isDarkMode);
  }
}
