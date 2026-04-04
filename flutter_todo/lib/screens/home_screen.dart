import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../widgets/task_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/search_bar.dart';
import 'add_task_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  late AnimationController _fabCtrl;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..forward();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fabCtrl.dispose();
    super.dispose();
  }

  void _showAddTask(BuildContext context, {Task? existingTask}) async {
    final result = await showModalBottomSheet<Task>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTaskScreen(existingTask: existingTask),
    );

    if (result != null && context.mounted) {
      final provider = context.read<TaskProvider>();
      if (existingTask != null) {
        provider.updateTask(result);
      } else {
        provider.addTask(result);
      }
    }
  }

  void _deleteTask(BuildContext context, Task task) {
    final provider = context.read<TaskProvider>();
    final idx = provider.indexOfTask(task.id);
    provider.deleteTask(task.id);

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Task deleted',
          style: GoogleFonts.inter(fontWeight: FontWeight.w500),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: Theme.of(context).colorScheme.secondary,
          onPressed: () => provider.insertTaskAt(idx, task),
        ),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TaskProvider>();
    final isDark = provider.isDarkMode;
    final tasks = provider.tasks;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // ── Header ──
            _buildHeader(context, provider, isDark),
            const SizedBox(height: 8),

            // ── Progress bar ──
            if (provider.totalCount > 0) _buildProgressBar(provider, isDark),

            const SizedBox(height: 12),

            // ── Search bar ──
            TaskSearchBar(
              controller: _searchCtrl,
              onChanged: (q) => provider.setSearchQuery(q),
              onClear: () => provider.setSearchQuery(''),
            ),
            const SizedBox(height: 12),

            // ── Filter chips ──
            _buildFilterChips(provider, isDark),
            const SizedBox(height: 8),

            // ── Task list ──
            Expanded(
              child: tasks.isEmpty
                  ? EmptyState(
                      isSearching: provider.searchQuery.isNotEmpty)
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: tasks.length,
                      itemBuilder: (_, idx) {
                        final task = tasks[idx];
                        return TaskTile(
                          key: ValueKey(task.id),
                          task: task,
                          onToggle: () => provider.toggleComplete(task.id),
                          onDelete: () => _deleteTask(context, task),
                          onEdit: () =>
                              _showAddTask(context, existingTask: task),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.easeOutBack),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddTask(context),
          icon: const Icon(Icons.add_rounded, size: 24),
          label: Text(
            'Add Task',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader(
      BuildContext context, TaskProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Gradient icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child:
                const Icon(Icons.checklist_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Tasks',
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF2D2D3A),
                ),
              ),
              if (provider.totalCount > 0)
                Text(
                  '${provider.activeCount} remaining · ${provider.completedCount} done',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                ),
            ],
          ),
          const Spacer(),
          // Sort button
          _HeaderButton(
            icon: Icons.sort_rounded,
            isDark: isDark,
            onTap: () => _showSortMenu(context, provider),
          ),
          const SizedBox(width: 8),
          // Theme toggle
          _HeaderButton(
            icon: isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            isDark: isDark,
            onTap: () => provider.toggleTheme(),
          ),
        ],
      ),
    );
  }

  // ── Progress Bar ───────────────────────────────────────────────────────
  Widget _buildProgressBar(TaskProvider provider, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${(provider.completionPercentage * 100).toInt()}%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: provider.completionPercentage,
              minHeight: 6,
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter Chips ───────────────────────────────────────────────────────
  Widget _buildFilterChips(TaskProvider provider, bool isDark) {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          ...TaskFilter.values.map((f) {
            final selected = provider.filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_filterLabel(f)),
                selected: selected,
                onSelected: (_) => provider.setFilter(f),
                selectedColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                ),
              ),
            );
          }),
          // Category chips
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            color: isDark ? Colors.white12 : Colors.grey.shade300,
          ),
          ...TaskCategory.values.map((c) {
            final selected = provider.categoryFilter == c;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(_catShort(c)),
                selected: selected,
                onSelected: (_) =>
                    provider.setCategoryFilter(selected ? null : c),
                selectedColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                checkmarkColor: Theme.of(context).colorScheme.primary,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : (isDark ? Colors.white54 : Colors.grey.shade600),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Sort Menu ──────────────────────────────────────────────────────────
  void _showSortMenu(BuildContext context, TaskProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sort Tasks',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              ...TaskSort.values.map((s) => ListTile(
                    leading: Icon(
                      _sortIcon(s),
                      color: provider.sort == s
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(
                      _sortLabel(s),
                      style: GoogleFonts.inter(
                        fontWeight: provider.sort == s
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: provider.sort == s
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    trailing: provider.sort == s
                        ? Icon(Icons.check_rounded,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    onTap: () {
                      provider.setSort(s);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────
  String _filterLabel(TaskFilter f) {
    switch (f) {
      case TaskFilter.all:
        return 'All';
      case TaskFilter.active:
        return 'Active';
      case TaskFilter.completed:
        return 'Done';
    }
  }

  String _catShort(TaskCategory c) {
    switch (c) {
      case TaskCategory.personal:
        return '👤';
      case TaskCategory.work:
        return '💼';
      case TaskCategory.shopping:
        return '🛒';
      case TaskCategory.health:
        return '❤️';
      case TaskCategory.education:
        return '📚';
      case TaskCategory.other:
        return '📌';
    }
  }

  String _sortLabel(TaskSort s) {
    switch (s) {
      case TaskSort.dateNewest:
        return 'Newest first';
      case TaskSort.dateOldest:
        return 'Oldest first';
      case TaskSort.priorityHigh:
        return 'High priority first';
      case TaskSort.priorityLow:
        return 'Low priority first';
    }
  }

  IconData _sortIcon(TaskSort s) {
    switch (s) {
      case TaskSort.dateNewest:
        return Icons.arrow_downward_rounded;
      case TaskSort.dateOldest:
        return Icons.arrow_upward_rounded;
      case TaskSort.priorityHigh:
        return Icons.priority_high_rounded;
      case TaskSort.priorityLow:
        return Icons.low_priority_rounded;
    }
  }
}

// ── Header Button ────────────────────────────────────────────────────────
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDark ? Colors.white.withValues(alpha: 0.06) : Colors.grey.shade200,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
      ),
    );
  }
}
