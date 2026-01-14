import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class TaskTile extends StatefulWidget {
  final String taskId;
  final String initialText;
  final bool isCompleted;
  final Function(String) onChanged;
  final Function(bool) onCompletedChanged;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.taskId,
    required this.initialText,
    required this.isCompleted,
    required this.onChanged,
    required this.onCompletedChanged,
    required this.onDelete,
  });

  @override
  State<TaskTile> createState() => _TaskTileState();
}

class _TaskTileState extends State<TaskTile> {
  late TextEditingController _controller;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _isCompleted = widget.isCompleted;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B4D8).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            // Checkbox
            GestureDetector(
              onTap:
                  _controller.text.isEmpty
                      ? null
                      : () {
                        setState(() => _isCompleted = !_isCompleted);
                        widget.onCompletedChanged(_isCompleted);
                      },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      _isCompleted
                          ? const Color(0xFF00B4D8)
                          : Colors.transparent,
                  border: Border.all(
                    color:
                        _controller.text.isEmpty
                            ? Colors.grey.shade300
                            : (_isCompleted
                                ? const Color(0xFF00B4D8)
                                : Colors.grey.shade400),
                    width: 2.5,
                  ),
                ),
                child:
                    _isCompleted
                        ? const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18,
                        )
                        : null,
              ),
            ),
            const SizedBox(width: 16),
            // Text field
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (v) => widget.onChanged(v),
                decoration: InputDecoration(
                  hintText: 'todoAddTask'.tr(),
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 16,
                  ),
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                style: TextStyle(
                  fontSize: 16,
                  color:
                      _isCompleted
                          ? Colors.grey.shade400
                          : Colors.grey.shade800,
                  decoration:
                      _isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                  decorationColor: Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Delete button
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder:
                      (BuildContext dialogContext) => AlertDialog(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'deleteTask'.tr(),
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        content: Text(
                          'deleteConfirmation'.tr(),
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'cancel'.tr(),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext);
                              widget.onDelete();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE94560),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                            ),
                            child: Text(
                              'delete'.tr(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
