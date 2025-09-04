import 'package:drift/drift.dart';
import '../database/database.dart';
import '../models/student.dart' as models;
import '../models/storage.dart' as models;
import '../models/item.dart' as models;
import '../models/borrow_record.dart' as models;

class DatabaseService {
  final AppDatabase _database;

  DatabaseService(this._database);

  // Students
  Future<List<models.Student>> getAllStudents() async {
    final students = await _database.select(_database.students).get();
    return students
        .map(
          (s) => models.Student(
            id: s.id,
            studentId: s.studentId,
            name: s.name,
            yearLevel: s.yearLevel,
            section: s.section,
            createdAt: s.createdAt,
          ),
        )
        .toList();
  }

  Future<models.Student?> getStudentByStudentId(String studentId) async {
    final student = await (_database.select(
      _database.students,
    )..where((s) => s.studentId.equals(studentId))).getSingleOrNull();

    if (student == null) return null;

    return models.Student(
      id: student.id,
      studentId: student.studentId,
      name: student.name,
      yearLevel: student.yearLevel,
      section: student.section,
      createdAt: student.createdAt,
    );
  }

  Future<int> insertStudent(models.Student student) async {
    return await _database
        .into(_database.students)
        .insert(
          StudentsCompanion(
            studentId: Value(student.studentId),
            name: Value(student.name),
            yearLevel: Value(student.yearLevel),
            section: Value(student.section),
          ),
        );
  }

  Future<void> updateStudent(models.Student student) async {
    await (_database.update(
      _database.students,
    )..where((s) => s.id.equals(student.id))).write(
      StudentsCompanion(
        name: Value(student.name),
        yearLevel: Value(student.yearLevel),
        section: Value(student.section),
      ),
    );
  }

  Future<void> deleteStudent(int studentId) async {
    await (_database.delete(
      _database.students,
    )..where((s) => s.id.equals(studentId))).go();
  }

  // Storages
  Future<List<models.Storage>> getAllStorages() async {
    final storages = await _database.select(_database.storages).get();
    return storages
        .map(
          (s) => models.Storage(
            id: s.id,
            name: s.name,
            description: s.description,
            createdAt: s.createdAt,
          ),
        )
        .toList();
  }

  // Items
  Future<List<models.Item>> getAllItems() async {
    final items = await _database.select(_database.items).get();
    return items
        .map(
          (i) => models.Item(
            id: i.id,
            name: i.name,
            description: i.description,
            storageId: i.storageId,
            totalQuantity: i.totalQuantity,
            availableQuantity: i.availableQuantity,
            createdAt: i.createdAt,
          ),
        )
        .toList();
  }

  Future<List<models.Item>> getItemsByStorage(int storageId) async {
    final items = await (_database.select(
      _database.items,
    )..where((i) => i.storageId.equals(storageId))).get();
    return items
        .map(
          (i) => models.Item(
            id: i.id,
            name: i.name,
            description: i.description,
            storageId: i.storageId,
            totalQuantity: i.totalQuantity,
            availableQuantity: i.availableQuantity,
            createdAt: i.createdAt,
          ),
        )
        .toList();
  }

  // Borrow Records
  Future<List<models.BorrowRecord>> getAllBorrowRecords() async {
    final records = await _database.select(_database.borrowRecords).get();

    List<models.BorrowRecord> borrowRecords = [];
    for (final record in records) {
      final items = await (_database.select(
        _database.borrowItems,
      )..where((bi) => bi.borrowRecordId.equals(record.id))).get();

      List<models.BorrowItem> borrowItems = [];
      for (final bi in items) {
        // Get quantity conditions for this borrow item
        final quantityConditions = await (_database.select(
          _database.borrowItemConditions,
        )..where((bic) => bic.borrowItemId.equals(bi.id))).get();

        final conditions = quantityConditions
            .map(
              (qc) => models.QuantityCondition(
                id: qc.id,
                borrowItemId: qc.borrowItemId,
                quantityUnit: qc.quantityUnit,
                condition: models.ItemCondition.values.firstWhere(
                  (c) => c.name == qc.condition,
                ),
              ),
            )
            .toList();

        borrowItems.add(
          models.BorrowItem(
            id: bi.id,
            borrowRecordId: bi.borrowRecordId,
            itemId: bi.itemId,
            quantity: bi.quantity,
            quantityConditions: conditions,
          ),
        );
      }

      borrowRecords.add(
        models.BorrowRecord(
          id: record.id,
          borrowId: record.borrowId,
          studentId: record.studentId,
          status: models.BorrowStatus.values.firstWhere(
            (s) => s.name == record.status,
          ),
          borrowedAt: record.borrowedAt,
          returnedAt: record.returnedAt,
          items: borrowItems,
        ),
      );
    }
    return borrowRecords;
  }

  Future<List<models.BorrowRecord>> getReturnedBorrowRecords() async {
    final records = await (_database.select(_database.borrowRecords)..where(
          (br) => br.status.equals('returned'),
        )).get();

    List<models.BorrowRecord> borrowRecords = [];
    for (final record in records) {
      final items = await (_database.select(
        _database.borrowItems,
      )..where((bi) => bi.borrowRecordId.equals(record.id))).get();

      List<models.BorrowItem> borrowItems = [];
      for (final bi in items) {
        // Get quantity conditions for this borrow item
        final quantityConditions = await (_database.select(
          _database.borrowItemConditions,
        )..where((bic) => bic.borrowItemId.equals(bi.id))).get();

        final conditions = quantityConditions
            .map(
              (qc) => models.QuantityCondition(
                id: qc.id,
                borrowItemId: qc.borrowItemId,
                quantityUnit: qc.quantityUnit,
                condition: models.ItemCondition.values.firstWhere(
                  (c) => c.name == qc.condition,
                ),
              ),
            )
            .toList();

        borrowItems.add(
          models.BorrowItem(
            id: bi.id,
            borrowRecordId: bi.borrowRecordId,
            itemId: bi.itemId,
            quantity: bi.quantity,
            quantityConditions: conditions,
          ),
        );
      }

      borrowRecords.add(
        models.BorrowRecord(
          id: record.id,
          borrowId: record.borrowId,
          studentId: record.studentId,
          status: models.BorrowStatus.values.firstWhere(
            (s) => s.name == record.status,
          ),
          borrowedAt: record.borrowedAt,
          returnedAt: record.returnedAt,
          items: borrowItems,
        ),
      );
    }
    return borrowRecords;
  }

  Future<List<models.QuantityCondition>> getDamagedItemRecords() async {
    final conditions = await (_database.select(
      _database.borrowItemConditions,
    )..where((bic) => bic.condition.equals('damaged'))).get();

    return conditions
        .map(
          (qc) => models.QuantityCondition(
            id: qc.id,
            borrowItemId: qc.borrowItemId,
            quantityUnit: qc.quantityUnit,
            condition: models.ItemCondition.damaged,
          ),
        )
        .toList();
  }

  Future<List<models.QuantityCondition>> getLostItemRecords() async {
    final conditions = await (_database.select(
      _database.borrowItemConditions,
    )..where((bic) => bic.condition.equals('lost'))).get();

    return conditions
        .map(
          (qc) => models.QuantityCondition(
            id: qc.id,
            borrowItemId: qc.borrowItemId,
            quantityUnit: qc.quantityUnit,
            condition: models.ItemCondition.lost,
          ),
        )
        .toList();
  }

  Future<List<models.BorrowRecord>> getActiveBorrowsByStudent(
    int studentId,
  ) async {
    final records =
        await (_database.select(_database.borrowRecords)..where(
              (br) =>
                  br.studentId.equals(studentId) & br.status.equals('active'),
            ))
            .get();

    List<models.BorrowRecord> borrowRecords = [];
    for (final record in records) {
      final items = await (_database.select(
        _database.borrowItems,
      )..where((bi) => bi.borrowRecordId.equals(record.id))).get();

      List<models.BorrowItem> borrowItems = [];
      for (final bi in items) {
        // Get quantity conditions for this borrow item
        final quantityConditions = await (_database.select(
          _database.borrowItemConditions,
        )..where((bic) => bic.borrowItemId.equals(bi.id))).get();

        final conditions = quantityConditions
            .map(
              (qc) => models.QuantityCondition(
                id: qc.id,
                borrowItemId: qc.borrowItemId,
                quantityUnit: qc.quantityUnit,
                condition: models.ItemCondition.values.firstWhere(
                  (c) => c.name == qc.condition,
                ),
              ),
            )
            .toList();

        borrowItems.add(
          models.BorrowItem(
            id: bi.id,
            borrowRecordId: bi.borrowRecordId,
            itemId: bi.itemId,
            quantity: bi.quantity,
            quantityConditions: conditions,
          ),
        );
      }

      borrowRecords.add(
        models.BorrowRecord(
          id: record.id,
          borrowId: record.borrowId,
          studentId: record.studentId,
          status: models.BorrowStatus.values.firstWhere(
            (s) => s.name == record.status,
          ),
          borrowedAt: record.borrowedAt,
          returnedAt: record.returnedAt,
          items: borrowItems,
        ),
      );
    }
    return borrowRecords;
  }

  Future<int> getActiveBorrowRecordsCount() async {
    final count = await (_database.selectOnly(_database.borrowRecords)
          ..addColumns([_database.borrowRecords.id.count()])
          ..where(_database.borrowRecords.status.equals('active')))
        .getSingle();
    
    return count.read(_database.borrowRecords.id.count()) ?? 0;
  }

  Future<String> generateBorrowId() async {
    final year = DateTime.now().year;
    final prefix = year.toString().substring(2); // Get last 2 digits of year

    final lastRecord =
        await (_database.select(_database.borrowRecords)
              ..orderBy([(br) => OrderingTerm.desc(br.id)])
              ..limit(1))
            .getSingleOrNull();

    int nextSequence = 1;
    if (lastRecord != null && lastRecord.borrowId.startsWith(prefix)) {
      final sequence = int.tryParse(lastRecord.borrowId.substring(2)) ?? 0;
      nextSequence = sequence + 1;
    }

    return '$prefix${nextSequence.toString().padLeft(5, '0')}';
  }

  Future<int> createBorrowRecord({
    required int studentId,
    required List<({int itemId, int quantity})> items,
  }) async {
    return await _database.transaction(() async {
      final borrowId = await generateBorrowId();

      final recordId = await _database
          .into(_database.borrowRecords)
          .insert(
            BorrowRecordsCompanion(
              borrowId: Value(borrowId),
              studentId: Value(studentId),
              status: const Value('active'),
            ),
          );

      for (final item in items) {
        await _database
            .into(_database.borrowItems)
            .insert(
              BorrowItemsCompanion(
                borrowRecordId: Value(recordId),
                itemId: Value(item.itemId),
                quantity: Value(item.quantity),
              ),
            );

        final currentItem = await (_database.select(
          _database.items,
        )..where((i) => i.id.equals(item.itemId))).getSingle();

        await (_database.update(
          _database.items,
        )..where((i) => i.id.equals(item.itemId))).write(
          ItemsCompanion(
            availableQuantity: Value(
              currentItem.availableQuantity - item.quantity,
            ),
          ),
        );
      }

      return recordId;
    });
  }

  Future<void> returnBorrowRecord({
    required int borrowRecordId,
    required List<({int itemId, models.ItemCondition condition})>
    itemConditions,
  }) async {
    await _database.transaction(() async {
      await (_database.update(
        _database.borrowRecords,
      )..where((br) => br.id.equals(borrowRecordId))).write(
        BorrowRecordsCompanion(
          status: const Value('returned'),
          returnedAt: Value(DateTime.now()),
        ),
      );

      for (final item in itemConditions) {
        final borrowItem =
            await (_database.select(_database.borrowItems)..where(
                  (bi) =>
                      bi.borrowRecordId.equals(borrowRecordId) &
                      bi.itemId.equals(item.itemId),
                ))
                .getSingle();

        await (_database.update(_database.borrowItems)
          ..where((bi) => bi.id.equals(borrowItem.id)));

        // Only add back items in good condition to available stock
        if (item.condition == models.ItemCondition.good) {
          final currentItem = await (_database.select(
            _database.items,
          )..where((i) => i.id.equals(item.itemId))).getSingle();

          await (_database.update(
            _database.items,
          )..where((i) => i.id.equals(item.itemId))).write(
            ItemsCompanion(
              availableQuantity: Value(
                currentItem.availableQuantity + borrowItem.quantity,
              ),
            ),
          );
        }
      }
    });
  }

  Future<void> returnBorrowRecordWithQuantityConditions({
    required int borrowRecordId,
    required List<
      ({int borrowItemId, List<models.QuantityCondition> quantityConditions})
    >
    itemConditions,
  }) async {
    await _database.transaction(() async {
      await (_database.update(
        _database.borrowRecords,
      )..where((br) => br.id.equals(borrowRecordId))).write(
        BorrowRecordsCompanion(
          status: const Value('returned'),
          returnedAt: Value(DateTime.now()),
        ),
      );

      for (final item in itemConditions) {
        final borrowItem = await (_database.select(
          _database.borrowItems,
        )..where((bi) => bi.id.equals(item.borrowItemId))).getSingle();

        // Insert individual quantity conditions
        for (final quantityCondition in item.quantityConditions) {
          await _database
              .into(_database.borrowItemConditions)
              .insert(
                BorrowItemConditionsCompanion(
                  borrowItemId: Value(item.borrowItemId),
                  quantityUnit: Value(quantityCondition.quantityUnit),
                  condition: Value(quantityCondition.condition.name),
                ),
              );
        }

        // Update available quantity based on good condition items only
        final goodConditionQuantity = item.quantityConditions
            .where((qc) => qc.condition == models.ItemCondition.good)
            .length;

        // Debug logging
        print('DEBUG: Returning ${item.quantityConditions.length} total units for borrowItem ${item.borrowItemId}');
        print('DEBUG: $goodConditionQuantity units in good condition');
        for (int i = 0; i < item.quantityConditions.length; i++) {
          final qc = item.quantityConditions[i];
          print('DEBUG: Unit ${qc.quantityUnit}: ${qc.condition.name}');
        }

        if (goodConditionQuantity > 0) {
          final currentItem = await (_database.select(
            _database.items,
          )..where((i) => i.id.equals(borrowItem.itemId))).getSingle();

          print('DEBUG: Current available quantity for item ${borrowItem.itemId}: ${currentItem.availableQuantity}');
          print('DEBUG: Adding $goodConditionQuantity units back to stock');

          await (_database.update(
            _database.items,
          )..where((i) => i.id.equals(borrowItem.itemId))).write(
            ItemsCompanion(
              availableQuantity: Value(
                currentItem.availableQuantity + goodConditionQuantity,
              ),
            ),
          );

          print('DEBUG: New available quantity: ${currentItem.availableQuantity + goodConditionQuantity}');
        } else {
          print('DEBUG: No good condition units to add back to stock');
        }
      }
    });
  }

  // Storage management
  Future<int> insertStorage(models.Storage storage) async {
    return await _database
        .into(_database.storages)
        .insert(
          StoragesCompanion(
            name: Value(storage.name),
            description: Value(storage.description),
          ),
        );
  }

  Future<void> updateStorage(models.Storage storage) async {
    await (_database.update(
      _database.storages,
    )..where((s) => s.id.equals(storage.id))).write(
      StoragesCompanion(
        name: Value(storage.name),
        description: Value(storage.description),
      ),
    );
  }

  Future<void> deleteStorage(int storageId) async {
    await (_database.delete(
      _database.storages,
    )..where((s) => s.id.equals(storageId))).go();
  }

  // Item management
  Future<int> insertItem(models.Item item) async {
    return await _database
        .into(_database.items)
        .insert(
          ItemsCompanion(
            name: Value(item.name),
            description: Value(item.description),
            storageId: Value(item.storageId),
            totalQuantity: Value(item.totalQuantity),
            availableQuantity: Value(item.availableQuantity),
          ),
        );
  }

  Future<void> updateItem(models.Item item) async {
    await (_database.update(
      _database.items,
    )..where((i) => i.id.equals(item.id))).write(
      ItemsCompanion(
        name: Value(item.name),
        description: Value(item.description),
        storageId: Value(item.storageId),
        totalQuantity: Value(item.totalQuantity),
        availableQuantity: Value(item.availableQuantity),
      ),
    );
  }

  Future<void> deleteItem(int itemId) async {
    await (_database.delete(
      _database.items,
    )..where((i) => i.id.equals(itemId))).go();
  }

  // Settings management
  Future<String> getSetting(String key, {String defaultValue = 'true'}) async {
    final setting = await (_database.select(_database.settings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();

    if (setting == null) {
      // Initialize with default value
      await _database.into(_database.settings).insert(
            SettingsCompanion(
              key: Value(key),
              value: Value(defaultValue),
            ),
          );
      return defaultValue;
    }

    return setting.value;
  }

  Future<void> updateSetting(String key, String value) async {
    final existingSetting = await (_database.select(_database.settings)
          ..where((s) => s.key.equals(key)))
        .getSingleOrNull();

    if (existingSetting == null) {
      await _database.into(_database.settings).insert(
            SettingsCompanion(
              key: Value(key),
              value: Value(value),
            ),
          );
    } else {
      await (_database.update(_database.settings)
            ..where((s) => s.key.equals(key)))
          .write(
        SettingsCompanion(
          value: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<Map<String, String>> getAllSettings() async {
    final settings = await _database.select(_database.settings).get();
    return {for (final setting in settings) setting.key: setting.value};
  }

  Future<bool> isScreenEnabled(String screenKey) async {
    final value = await getSetting(screenKey);
    return value.toLowerCase() == 'true';
  }

  // Archive/Restore functionality
  Future<void> archiveBorrowRecord(int borrowRecordId) async {
    await (_database.update(
      _database.borrowRecords,
    )..where((br) => br.id.equals(borrowRecordId))).write(
      BorrowRecordsCompanion(
        status: const Value('archived'),
      ),
    );
  }

  Future<void> restoreBorrowRecord(int borrowRecordId) async {
    final record = await (_database.select(_database.borrowRecords)..where(
      (br) => br.id.equals(borrowRecordId),
    )).getSingle();

    // Determine the correct status based on return date
    final newStatus = record.returnedAt != null ? 'returned' : 'active';
    
    await (_database.update(
      _database.borrowRecords,
    )..where((br) => br.id.equals(borrowRecordId))).write(
      BorrowRecordsCompanion(
        status: Value(newStatus),
      ),
    );
  }

  Future<List<models.BorrowRecord>> getArchivedBorrowRecords() async {
    final records = await (_database.select(_database.borrowRecords)..where(
          (br) => br.status.equals('archived'),
        )).get();

    List<models.BorrowRecord> borrowRecords = [];
    for (final record in records) {
      final items = await (_database.select(
        _database.borrowItems,
      )..where((bi) => bi.borrowRecordId.equals(record.id))).get();

      List<models.BorrowItem> borrowItems = [];
      for (final bi in items) {
        // Get quantity conditions for this borrow item
        final quantityConditions = await (_database.select(
          _database.borrowItemConditions,
        )..where((bic) => bic.borrowItemId.equals(bi.id))).get();

        final conditions = quantityConditions
            .map(
              (qc) => models.QuantityCondition(
                id: qc.id,
                borrowItemId: qc.borrowItemId,
                quantityUnit: qc.quantityUnit,
                condition: models.ItemCondition.values.firstWhere(
                  (c) => c.name == qc.condition,
                ),
              ),
            )
            .toList();

        borrowItems.add(
          models.BorrowItem(
            id: bi.id,
            borrowRecordId: bi.borrowRecordId,
            itemId: bi.itemId,
            quantity: bi.quantity,
            quantityConditions: conditions,
          ),
        );
      }

      borrowRecords.add(
        models.BorrowRecord(
          id: record.id,
          borrowId: record.borrowId,
          studentId: record.studentId,
          status: models.BorrowStatus.values.firstWhere(
            (s) => s.name == record.status,
          ),
          borrowedAt: record.borrowedAt,
          returnedAt: record.returnedAt,
          items: borrowItems,
        ),
      );
    }
    return borrowRecords;
  }

  Future<void> bulkArchiveBorrowRecords(List<int> recordIds) async {
    await _database.transaction(() async {
      for (final recordId in recordIds) {
        await archiveBorrowRecord(recordId);
      }
    });
  }

  Future<void> bulkRestoreBorrowRecords(List<int> recordIds) async {
    await _database.transaction(() async {
      for (final recordId in recordIds) {
        await restoreBorrowRecord(recordId);
      }
    });
  }

  Future<List<models.BorrowRecord>> getRecentBorrowRecords([int limit = 5]) async {
    // Get all records first, then sort by most recent activity in memory
    final records = await _database.select(_database.borrowRecords).get();
    
    // Sort by most recent activity (return date if exists, otherwise borrow date)
    records.sort((a, b) {
      final aDate = a.returnedAt ?? a.borrowedAt;
      final bDate = b.returnedAt ?? b.borrowedAt;
      return bDate.compareTo(aDate);
    });
    
    // Take only the requested limit
    final limitedRecords = records.take(limit).toList();

    List<models.BorrowRecord> borrowRecords = [];
    for (final record in limitedRecords) {
      final items = await (_database.select(
        _database.borrowItems,
      )..where((bi) => bi.borrowRecordId.equals(record.id))).get();

      List<models.BorrowItem> borrowItems = [];
      for (final bi in items) {
        // Get quantity conditions for this borrow item
        final quantityConditions = await (_database.select(
          _database.borrowItemConditions,
        )..where((bic) => bic.borrowItemId.equals(bi.id))).get();

        final conditions = quantityConditions
            .map(
              (qc) => models.QuantityCondition(
                id: qc.id,
                borrowItemId: qc.borrowItemId,
                quantityUnit: qc.quantityUnit,
                condition: models.ItemCondition.values.firstWhere(
                  (c) => c.name == qc.condition,
                ),
              ),
            )
            .toList();

        borrowItems.add(
          models.BorrowItem(
            id: bi.id,
            borrowRecordId: bi.borrowRecordId,
            itemId: bi.itemId,
            quantity: bi.quantity,
            quantityConditions: conditions,
          ),
        );
      }

      borrowRecords.add(
        models.BorrowRecord(
          id: record.id,
          borrowId: record.borrowId,
          studentId: record.studentId,
          status: models.BorrowStatus.values.firstWhere(
            (s) => s.name == record.status,
          ),
          borrowedAt: record.borrowedAt,
          returnedAt: record.returnedAt,
          items: borrowItems,
        ),
      );
    }

    return borrowRecords;
  }

  Future<List<Map<String, dynamic>>> getRecentBorrowRecordsWithStudentNames([int limit = 5]) async {
    // Get all records first, then sort by most recent activity in memory
    final records = await _database.select(_database.borrowRecords).get();
    
    // Sort by most recent activity (return date if exists, otherwise borrow date)
    records.sort((a, b) {
      final aDate = a.returnedAt ?? a.borrowedAt;
      final bDate = b.returnedAt ?? b.borrowedAt;
      return bDate.compareTo(aDate);
    });
    
    // Take only the requested limit
    final limitedRecords = records.take(limit).toList();

    List<Map<String, dynamic>> borrowRecordsWithNames = [];
    for (final record in limitedRecords) {
      // Get student information
      final student = await (_database.select(_database.students)
        ..where((s) => s.id.equals(record.studentId))).getSingleOrNull();
      
      final items = await (_database.select(
        _database.borrowItems,
      )..where((bi) => bi.borrowRecordId.equals(record.id))).get();

      List<models.BorrowItem> borrowItems = [];
      for (final bi in items) {
        // Get quantity conditions for this borrow item
        final quantityConditions = await (_database.select(
          _database.borrowItemConditions,
        )..where((bic) => bic.borrowItemId.equals(bi.id))).get();

        final conditions = quantityConditions
            .map(
              (qc) => models.QuantityCondition(
                id: qc.id,
                borrowItemId: qc.borrowItemId,
                quantityUnit: qc.quantityUnit,
                condition: models.ItemCondition.values.firstWhere(
                  (c) => c.name == qc.condition,
                ),
              ),
            )
            .toList();

        borrowItems.add(
          models.BorrowItem(
            id: bi.id,
            borrowRecordId: bi.borrowRecordId,
            itemId: bi.itemId,
            quantity: bi.quantity,
            quantityConditions: conditions,
          ),
        );
      }

      final borrowRecord = models.BorrowRecord(
        id: record.id,
        borrowId: record.borrowId,
        studentId: record.studentId,
        status: models.BorrowStatus.values.firstWhere(
          (s) => s.name == record.status,
        ),
        borrowedAt: record.borrowedAt,
        returnedAt: record.returnedAt,
        items: borrowItems,
      );

      borrowRecordsWithNames.add({
        'borrowRecord': borrowRecord,
        'studentName': student?.name ?? 'Unknown Student',
      });
    }

    return borrowRecordsWithNames;
  }
}
