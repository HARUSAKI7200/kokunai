// lib/storage.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageService {
  static const _key = 'kojucho_forms_v1';
  // 履歴とは別のフォルダにテンプレートを保存
  static const _templateDir = 'templates';

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

  // --- Template Methods (File System based) ---

  Future<void> saveTemplate(String productName, String templateName, FormRecord record) async {
    final directory = await getApplicationDocumentsDirectory();
    // 製品名のフォルダを作成
    final productDir = Directory('${directory.path}/$_templateDir/$productName');
    if (!await productDir.exists()) {
      await productDir.create(recursive: true);
    }
    
    // テンプレートファイルをJSONとして保存
    final file = File('${productDir.path}/$templateName.json');
    final recordJson = jsonEncode(record.toJson());
    await file.writeAsString(recordJson);
  }
}