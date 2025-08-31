import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/borrow_record.dart';
import 'database_provider.dart';

final allBorrowRecordsProvider = FutureProvider<List<BorrowRecord>>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getAllBorrowRecords();
});

final activeBorrowRecordsCountProvider = FutureProvider<int>((ref) async {
  final databaseService = ref.watch(databaseServiceProvider);
  return await databaseService.getActiveBorrowRecordsCount();
});

final borrowRecordNotifierProvider = StateNotifierProvider<BorrowRecordNotifier, AsyncValue<List<BorrowRecord>>>(
  (ref) => BorrowRecordNotifier(ref),
);

final activeBorrowCountNotifierProvider = StateNotifierProvider<ActiveBorrowCountNotifier, AsyncValue<int>>(
  (ref) => ActiveBorrowCountNotifier(ref),
);

class BorrowRecordNotifier extends StateNotifier<AsyncValue<List<BorrowRecord>>> {
  final Ref _ref;

  BorrowRecordNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadBorrowRecords();
  }

  Future<void> _loadBorrowRecords() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final borrowRecords = await databaseService.getAllBorrowRecords();
      state = AsyncValue.data(borrowRecords);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshBorrowRecords() async {
    state = const AsyncValue.loading();
    await _loadBorrowRecords();
  }
}

class ActiveBorrowCountNotifier extends StateNotifier<AsyncValue<int>> {
  final Ref _ref;

  ActiveBorrowCountNotifier(this._ref) : super(const AsyncValue.loading()) {
    _loadActiveBorrowCount();
  }

  Future<void> _loadActiveBorrowCount() async {
    try {
      final databaseService = _ref.read(databaseServiceProvider);
      final count = await databaseService.getActiveBorrowRecordsCount();
      state = AsyncValue.data(count);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> refreshActiveBorrowCount() async {
    state = const AsyncValue.loading();
    await _loadActiveBorrowCount();
  }
}