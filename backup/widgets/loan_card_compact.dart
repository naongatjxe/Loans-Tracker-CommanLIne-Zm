import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../theme/theme_controller.dart';

class LoanCardCompact extends StatelessWidget {
  final Person loan;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const LoanCardCompact({
    super.key,
    required this.loan,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeController = Provider.of<ThemeController>(
      context,
      listen: false,
    );

    // Calculate status information
    final now = DateTime.now();
    final daysLeft = loan.dueDate.difference(now).inDays;
    final isOverdue = daysLeft < 0;
    final isDueToday = daysLeft == 0;
    final isDueSoon = daysLeft > 0 && daysLeft <= 7;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main row: avatar + name/info + total
              Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: themeController.accent.withValues(
                      alpha: 0.15,
                    ),
                    child: Text(
                      loan.name.isNotEmpty ? loan.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: themeController.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name and details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'K${loan.amount.toStringAsFixed(0)} • ${_formatDate(loan.dueDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Total amount with label
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'To Pay',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.6,
                          ),
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        'K${loan.calculateAmountDue(loan.dueDate).toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: themeController.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status and actions row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        loan.isPaid,
                        isOverdue,
                        isDueSoon,
                      ).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(
                        loan.isPaid,
                        isOverdue,
                        isDueSoon,
                        isDueToday,
                        daysLeft,
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(
                          loan.isPaid,
                          isOverdue,
                          isDueSoon,
                        ),
                      ),
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      _simpleButton(
                        icon: Icons.edit,
                        onTap: onEdit,
                        color: themeController.accent,
                        label: 'Edit',
                      ),
                      const SizedBox(width: 8),
                      _simpleButton(
                        icon: Icons.delete,
                        onTap: onDelete,
                        color: Colors.red,
                        label: 'Delete',
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime d) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  static Color _getStatusColor(bool isPaid, bool isOverdue, bool isDueSoon) {
    if (isPaid) return Colors.green;
    if (isOverdue) return Colors.red;
    if (isDueSoon) return Colors.orange;
    return Colors.blue;
  }

  static String _getStatusText(
    bool isPaid,
    bool isOverdue,
    bool isDueSoon,
    bool isDueToday,
    int daysLeft,
  ) {
    if (isPaid) return 'PAID';
    if (isOverdue) return '${(-daysLeft)} DAYS LATE';
    if (isDueToday) return 'DUE TODAY';
    if (isDueSoon) return '$daysLeft DAYS LEFT';
    return 'ACTIVE';
  }

  static Widget _simpleButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color color,
    String? label,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
