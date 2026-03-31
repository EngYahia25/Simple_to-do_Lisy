import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task.dart';

class AddTaskScreen extends StatefulWidget {
  final Task? existingTask; // null = add, non-null = edit

  const AddTaskScreen({super.key, this.existingTask});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  TaskCategory _category = TaskCategory.personal;
  TaskPriority _priority = TaskPriority.medium;

  bool get _isEditing => widget.existingTask != null;

  @override
  void initState() {
    super.initState();
    _titleCtrl =
        TextEditingController(text: widget.existingTask?.title ?? '');
    _descCtrl =
        TextEditingController(text: widget.existingTask?.description ?? '');
    if (_isEditing) {
      _category = widget.existingTask!.category;
      _priority = widget.existingTask!.priority;
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final task = _isEditing
        ? widget.existingTask!.copyWith(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            category: _category,
            priority: _priority,
          )
        : Task(
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            category: _category,
            priority: _priority,
          );

    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                _isEditing ? 'Edit Task' : 'New Task',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF2D2D3A),
                ),
              ),
              const SizedBox(height: 24),

              // Task title field
              _label('Title', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                autofocus: !_isEditing,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF2D2D3A),
                ),
                decoration: InputDecoration(
                  hintText: 'What needs to be done?',
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                  ),
                  prefixIcon: Icon(
                    Icons.title_rounded,
                    color: primary.withValues(alpha: 0.6),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),

              // Description field
              _label('Description (optional)', isDark),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF2D2D3A),
                ),
                decoration: InputDecoration(
                  hintText: 'Add some details...',
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white30 : Colors.grey.shade400,
                  ),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(bottom: 44),
                    child: Icon(
                      Icons.notes_rounded,
                      color: primary.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Category selector
              _label('Category', isDark),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskCategory.values.map((cat) {
                  final selected = _category == cat;
                  return ChoiceChip(
                    label: Text(_categoryLabel(cat)),
                    selected: selected,
                    onSelected: (_) => setState(() => _category = cat),
                    selectedColor: primary.withValues(alpha: 0.15),
                    labelStyle: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: selected
                          ? primary
                          : (isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                    checkmarkColor: primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Priority selector
              _label('Priority', isDark),
              const SizedBox(height: 10),
              Row(
                children: TaskPriority.values.map((p) {
                  final selected = _priority == p;
                  final color = _priorityColor(p);
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: p != TaskPriority.high ? 8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _priority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: selected
                                ? color.withValues(alpha: 0.15)
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.06)
                                    : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: selected
                                  ? color
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _priorityLabel(p),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight:
                                    selected ? FontWeight.w700 : FontWeight.w500,
                                color: selected
                                    ? color
                                    : (isDark
                                        ? Colors.white54
                                        : Colors.grey.shade500),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                    textStyle: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: Text(_isEditing ? 'Update Task' : 'Add Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white54 : Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      );

  String _categoryLabel(TaskCategory cat) {
    switch (cat) {
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

  String _priorityLabel(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return '🟢 Low';
      case TaskPriority.medium:
        return '🟡 Medium';
      case TaskPriority.high:
        return '🔴 High';
    }
  }

  Color _priorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.low:
        return const Color(0xFF4CAF50);
      case TaskPriority.medium:
        return const Color(0xFFFF9800);
      case TaskPriority.high:
        return const Color(0xFFE53935);
    }
  }
}
