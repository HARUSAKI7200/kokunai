import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class StorageService {
  static const _key = 'kojucho_forms_v1';

  Future<List<FormRecord>> loadAll() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    return RecordList.decode(raw).items;
  }

  Future<void> saveAll(List<FormRecord> list) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, RecordList(list).encode());
  }

  Future<void> upsert(FormRecord rec) async {
    final list = await loadAll();
    final idx = list.indexWhere((e) => e.id == rec.id);
    if (idx >= 0) {
      list[idx] = rec..updatedAt = DateTime.now();
    } else {
      list.add(rec);
    }
    await saveAll(list);
  }

  Future<void> delete(String id) async {
    final list = await loadAll();
    list.removeWhere((e) => e.id == id);
    await saveAll(list);
  }

  Future<FormRecord?> find(String id) async {
    final list = await loadAll();
    return list.where((e) => e.id == id).cast<FormRecord?>().firstWhere(
          (e) => e?.id == id,
          orElse: () => null,
        );
  }
}
