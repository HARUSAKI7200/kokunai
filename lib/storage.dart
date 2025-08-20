import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'dart:convert';

class StorageService {
  static const _key = 'kojucho_forms_v1';
  static const _templatePrefix = 'template_';

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

  Future<void> deleteAll() async {
    // 空のリストを保存することで、全件削除を実現
    await saveAll([]);
  }

  Future<FormRecord?> find(String id) async {
    final list = await loadAll();
    return list.where((e) => e.id == id).cast<FormRecord?>().firstWhere(
          (e) => e?.id == id,
          orElse: () => null,
        );
  }

  // --- Template Methods ---

  Future<void> saveTemplate(String productName, String templateName, FormRecord record) async {
    final sp = await SharedPreferences.getInstance();
    final key = '$_templatePrefix${productName}_$templateName';
    final recordJson = jsonEncode(record.toJson());
    await sp.setString(key, recordJson);
  }

  Future<Map<String, String>> getTemplateList() async {
    final sp = await SharedPreferences.getInstance();
    final keys = sp.getKeys();
    final templateKeys = keys.where((key) => key.startsWith(_templatePrefix));

    final Map<String, String> templates = {};
    for (final key in templateKeys) {
      final displayName = key.substring(_templatePrefix.length).replaceAll('_', ' / ');
      templates[key] = displayName;
    }
    return templates;
  }

  Future<FormRecord?> loadTemplate(String key) async {
    final sp = await SharedPreferences.getInstance();
    final jsonString = sp.getString(key);
    if (jsonString == null) return null;
    return FormRecord.fromJson(jsonDecode(jsonString));
  }

  Future<void> deleteTemplate(String key) async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(key);
  }
}