import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high }

enum TaskCategory { personal, work, shopping, health, education, other }

class Task {
  final String id;
  String title;
  String description;
  TaskCategory category;
  TaskPriority priority;
  bool isCompleted;
  final DateTime createdAt;
  DateTime? completedAt;

  Task({
    String? id,
    required this.title,
    this.description = '',
    this.category = TaskCategory.personal,
    this.priority = TaskPriority.medium,
    this.isCompleted = false,
    DateTime? createdAt,
    this.completedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category.index,
        'priority': priority.index,
        'isCompleted': isCompleted,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        category: TaskCategory.values[json['category'] as int? ?? 0],
        priority: TaskPriority.values[json['priority'] as int? ?? 1],
        isCompleted: json['isCompleted'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
      );

  Task copyWith({
    String? title,
    String? description,
    TaskCategory? category,
    TaskPriority? priority,
    bool? isCompleted,
    DateTime? completedAt,
  }) =>
      Task(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        category: category ?? this.category,
        priority: priority ?? this.priority,
        isCompleted: isCompleted ?? this.isCompleted,
        createdAt: createdAt,
        completedAt: completedAt ?? this.completedAt,
      );

  // UI helpers
  String get categoryLabel {
    switch (category) {
      case TaskCategory.personal:
        return '👤 Personal';
      case TaskCategory.work:
        return '💼 Work';
      case TaskCategory.shopping:
        return '🛒 Shopping';
      case TaskCategory.health:
        return '❤️ Health';
      case TaskCategory.education:
        return '📚 Education';
      case TaskCategory.other:
        return '📌 Other';
    }
  }

  String get priorityLabel {
    switch (priority) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
    }
  }
}
