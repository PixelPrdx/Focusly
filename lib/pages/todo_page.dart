import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../widgets/task_tile.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  State<TodoPage> createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  late CollectionReference tasksRef;
  late String userId;

  @override
  void initState() {
    super.initState();
    tasksRef = FirebaseFirestore.instance.collection('tasks');
    userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
  }

  /// Bugünün başlangıç zamanını al (00:00:00)
  DateTime get _todayStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  Future<void> _addNewTask() async {
    await tasksRef.add({
      'userId': userId,
      'text': '',
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteTask(String taskId) async {
    try {
      await tasksRef.doc(taskId).delete();
    } catch (e) {
      debugPrint('Error: Task could not be deleted - $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F3460),
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'todoTitle'.tr(),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF0F3460), const Color(0xFF16213E)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF00B4D8), const Color(0xFF0096C7)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00B4D8).withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'todoTasks'.tr(),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'todoDescription'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: tasksRef.where('userId', isEqualTo: userId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // Hata detayını konsola yaz
                  debugPrint('Todo Error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Hata oluştu',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'todoEmpty'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                // Client-side filterleme: sadece bugünün görevlerini göster
                final allTasks = snapshot.data!.docs;
                final todayTasks =
                    allTasks.where((doc) {
                      final createdAt = doc['createdAt'] as Timestamp?;
                      if (createdAt == null) {
                        return true; // Yeni oluşturulan görevleri göster
                      }
                      return createdAt.toDate().isAfter(_todayStart) ||
                          createdAt.toDate().isAtSameMomentAs(_todayStart);
                    }).toList();

                if (todayTasks.isEmpty) {
                  return Center(
                    child: Text(
                      'todoEmpty'.tr(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final tasks = todayTasks;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (_, index) {
                    final doc = tasks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TaskTile(
                        key: ValueKey(doc.id),
                        taskId: doc.id,
                        initialText: doc['text'] ?? '',
                        isCompleted: doc['completed'] ?? false,
                        onChanged: (text) {
                          doc.reference.update({'text': text});
                        },
                        onCompletedChanged: (value) {
                          final updateData = <String, dynamic>{
                            'completed': value,
                          };
                          if (value) {
                            // Görev tamamlandığında completedAt ekle
                            updateData['completedAt'] =
                                FieldValue.serverTimestamp();
                          } else {
                            // Görev tekrar açıldığında completedAt kaldır
                            updateData['completedAt'] = FieldValue.delete();
                          }
                          doc.reference.update(updateData);
                        },
                        onDelete: () {
                          _deleteTask(doc.id);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewTask,
        backgroundColor: const Color(0xFF00B4D8),
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
