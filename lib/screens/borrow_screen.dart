import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/database_provider.dart';
import '../models/student.dart' as models;
import '../models/storage.dart' as models;
import '../models/item.dart' as models;

class BorrowScreen extends ConsumerStatefulWidget {
  const BorrowScreen({super.key});

  @override
  ConsumerState<BorrowScreen> createState() => _BorrowScreenState();
}

class _BorrowScreenState extends ConsumerState<BorrowScreen> {
  final _studentIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  models.Student? _selectedStudent;
  models.Storage? _selectedStorage;
  List<models.Storage> _storages = [];
  List<models.Item> _items = [];
  Map<int, int> _selectedItems = {}; // itemId -> quantity

  @override
  void initState() {
    super.initState();
    _loadStorages();
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    super.dispose();
  }

  Future<void> _loadStorages() async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final storages = await databaseService.getAllStorages();
      setState(() {
        _storages = storages;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading storages: $e')),
        );
      }
    }
  }

  Future<void> _searchStudent() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final databaseService = ref.read(databaseServiceProvider);
      final student = await databaseService.getStudentByStudentId(_studentIdController.text.trim());
      
      setState(() {
        _selectedStudent = student;
      });

      if (student == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Student not found. Please register first.')),
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

  Future<void> _loadItemsByStorage(models.Storage storage) async {
    try {
      final databaseService = ref.read(databaseServiceProvider);
      final items = await databaseService.getItemsByStorage(storage.id);
      setState(() {
        _selectedStorage = storage;
        _items = items;
        _selectedItems.clear();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading items: $e')),
        );
      }
    }
  }

  Future<void> _createBorrowRecord() async {
    if (_selectedStudent == null || _selectedItems.isEmpty) return;

    try {
      final databaseService = ref.read(databaseServiceProvider);
      final borrowItems = _selectedItems.entries
          .map((e) => (itemId: e.key, quantity: e.value))
          .toList();

      await databaseService.createBorrowRecord(
        studentId: _selectedStudent!.id,
        items: borrowItems,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items borrowed successfully!')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating borrow record: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Borrow Items'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
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
            
            // Storage Selection
            if (_selectedStudent != null) ...[
              const Text('Select Storage', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _storages.length,
                  itemBuilder: (context, index) {
                    final storage = _storages[index];
                    final isSelected = _selectedStorage?.id == storage.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(storage.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            _loadItemsByStorage(storage);
                          }
                        },
                        backgroundColor: Colors.grey.shade200,
                        selectedColor: Colors.blue.shade100,
                      ),
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Items List
              if (_items.isNotEmpty) ...[
                Text('Available Items in ${_selectedStorage!.name}', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 400,
                  child: ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      final selectedQuantity = _selectedItems[item.id] ?? 0;
                      return Card(
                        child: ListTile(
                          title: Text(
                            item.name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.description ?? '',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                              Text(
                                'Available: ${item.availableQuantity}/${item.totalQuantity}',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
                          trailing: item.availableQuantity > 0 
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: selectedQuantity > 0 ? () {
                                      setState(() {
                                        if (selectedQuantity == 1) {
                                          _selectedItems.remove(item.id);
                                        } else {
                                          _selectedItems[item.id] = selectedQuantity - 1;
                                        }
                                      });
                                    } : null,
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text(selectedQuantity.toString()),
                                  IconButton(
                                    onPressed: selectedQuantity < item.availableQuantity ? () {
                                      setState(() {
                                        _selectedItems[item.id] = selectedQuantity + 1;
                                      });
                                    } : null,
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              )
                            : const Text('Out of Stock'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
      floatingActionButton: _selectedStudent != null && _selectedItems.isNotEmpty 
        ? FloatingActionButton.extended(
            onPressed: _createBorrowRecord,
            label: Text(
              'Borrow ${_selectedItems.values.fold(0, (sum, qty) => sum + qty)} Items',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            icon: const Icon(Icons.check),
            backgroundColor: Colors.green,
          )
        : null,
    );
  }
}