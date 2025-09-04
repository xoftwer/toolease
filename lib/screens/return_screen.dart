import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../providers/item_provider.dart';
import '../providers/borrow_record_provider.dart';
import '../models/student.dart' as models;
import '../models/borrow_record.dart' as models;

class ReturnScreen extends ConsumerStatefulWidget {
  const ReturnScreen({super.key});

  @override
  ConsumerState<ReturnScreen> createState() => _ReturnScreenState();
}

class _ReturnScreenState extends ConsumerState<ReturnScreen> {
  final _studentIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  models.Student? _selectedStudent;
  List<models.BorrowRecord> _activeBorrows = [];
  Map<int, models.ItemCondition> _itemConditions = {}; // itemId -> condition (for backward compatibility)
  Map<int, List<models.ItemCondition>> _quantityConditions = {}; // borrowItemId -> list of conditions per quantity

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _searchStudent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final databaseService = ref.read(databaseServiceProvider);
      final student = await databaseService.getStudentByStudentId(_studentIdController.text.trim());
      
      if (student != null) {
        final activeBorrows = await databaseService.getActiveBorrowsByStudent(student.id);
        setState(() {
          _selectedStudent = student;
          _activeBorrows = activeBorrows;
          _itemConditions.clear();
          _quantityConditions.clear();
          
          // Initialize all items as good condition and individual quantities
          for (final record in activeBorrows) {
            for (final item in record.items) {
              _itemConditions[item.itemId] = models.ItemCondition.good;
              
              // If item already has quantity conditions from database, use them
              if (item.quantityConditions.isNotEmpty) {
                final conditions = item.quantityConditions.map((qc) => qc.condition).toList();
                _quantityConditions[item.id] = conditions;
              } else {
                // Initialize all quantity units as good condition
                _quantityConditions[item.id] = List.filled(item.quantity, models.ItemCondition.good);
              }
            }
          }
        });
      } else {
        setState(() {
          _selectedStudent = null;
          _activeBorrows = [];
          _itemConditions.clear();
          _quantityConditions.clear();
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student not found or has no active borrows.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching student: $e')),
        );
      }
    }
  }

  Future<void> _returnItems() async {
    if (_selectedStudent == null || _activeBorrows.isEmpty) return;

    try {
      final databaseService = ref.read(databaseServiceProvider);
      
      for (final record in _activeBorrows) {
        final itemConditions = record.items.map((item) {
          final quantityConditions = _quantityConditions[item.id] ?? [];
          final List<models.QuantityCondition> conditions = [];
          
          for (int i = 0; i < quantityConditions.length; i++) {
            conditions.add(models.QuantityCondition(
              id: 0, // Will be assigned by database
              borrowItemId: item.id,
              quantityUnit: i + 1,
              condition: quantityConditions[i],
            ));
          }
          
          return (
            borrowItemId: item.id,
            quantityConditions: conditions,
          );
        }).toList();

        await databaseService.returnBorrowRecordWithQuantityConditions(
          borrowRecordId: record.id,
          itemConditions: itemConditions,
        );
      }

      // Invalidate providers to refresh dashboard data
      ref.invalidate(itemNotifierProvider);
      ref.invalidate(activeBorrowCountNotifierProvider);
      ref.invalidate(allItemsProvider);
      ref.invalidate(activeBorrowRecordsCountProvider);
      ref.invalidate(recentBorrowRecordsWithNamesNotifierProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items returned successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error returning items: $e')),
        );
      }
    }
  }

  Future<String> _getItemName(int itemId) async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final items = await databaseService.getAllItems();
      final item = items.firstWhere((item) => item.id == itemId);
      return item.name;
    } catch (e) {
      return 'Unknown Item';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Return Items'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Search Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Student Information', 
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _studentIdController,
                              decoration: const InputDecoration(
                                labelText: 'Student ID',
                                border: OutlineInputBorder(),
                                hintText: 'Enter student ID',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter student ID';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _searchStudent,
                            child: const Text('Search'),
                          ),
                        ],
                      ),
                      if (_selectedStudent != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('✓ Student Found', 
                                style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
                              Text('Name: ${_selectedStudent!.name}'),
                              Text('Year Level: ${_selectedStudent!.yearLevel}'),
                              Text('Section: ${_selectedStudent!.section}'),
                              Text('Active Borrows: ${_activeBorrows.length}'),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Active Borrows List
            if (_activeBorrows.isNotEmpty) ...[
              const Text('Borrowed Items', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: _activeBorrows.length,
                  itemBuilder: (context, recordIndex) {
                    final record = _activeBorrows[recordIndex];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Borrow ID: ${record.borrowId}',
                                  style: const TextStyle(fontWeight: FontWeight.bold)),
                                Text('Date: ${record.borrowedAt.toLocal().toString().split(' ')[0]}',
                                  style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ...record.items.map((item) => FutureBuilder<String>(
                              future: _getItemName(item.itemId),
                              builder: (context, snapshot) {
                                final itemName = snapshot.data ?? 'Loading...';
                                final quantityConditions = _quantityConditions[item.id] ?? [];
                                
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    itemName,
                                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                  Text(
                                                    'Total Quantity: ${item.quantity}',
                                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        const Text('Condition per unit:', 
                                          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: List.generate(item.quantity, (index) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(color: Colors.grey.shade300),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Text('Unit ${index + 1}:', 
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                                  const SizedBox(width: 8),
                                                  DropdownButton<models.ItemCondition>(
                                                    value: quantityConditions.length > index 
                                                        ? quantityConditions[index] 
                                                        : models.ItemCondition.good,
                                                    isDense: true,
                                                    underline: const SizedBox.shrink(),
                                                    items: models.ItemCondition.values.map((condition) {
                                                      return DropdownMenuItem(
                                                        value: condition,
                                                        child: Text(condition.name.toUpperCase(),
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            color: condition == models.ItemCondition.good 
                                                                ? Colors.green.shade700 
                                                                : condition == models.ItemCondition.damaged 
                                                                    ? Colors.orange.shade700 
                                                                    : Colors.red.shade700,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                    onChanged: (newCondition) {
                                                      if (newCondition != null) {
                                                        setState(() {
                                                          final conditions = List<models.ItemCondition>.from(_quantityConditions[item.id] ?? []);
                                                          
                                                          // Ensure the list is long enough
                                                          while (conditions.length <= index) {
                                                            conditions.add(models.ItemCondition.good);
                                                          }
                                                          
                                                          conditions[index] = newCondition;
                                                          _quantityConditions[item.id] = conditions;
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          }),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            )).toList(),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else if (_selectedStudent != null) ...[
              const Center(
                child: Text('No active borrows found for this student.',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: _selectedStudent != null && _activeBorrows.isNotEmpty 
        ? FloatingActionButton.extended(
            onPressed: _returnItems,
            label: Text(
              'Return ${_activeBorrows.fold(0, (sum, record) => sum + record.items.fold(0, (itemSum, item) => itemSum + item.quantity))} Units',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            icon: const Icon(Icons.assignment_return),
            backgroundColor: Colors.orange,
          )
        : null,
    );
  }
}