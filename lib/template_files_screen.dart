// lib/template_files_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'edit_form_page.dart';
import 'models.dart';

class TemplateFilesScreen extends StatefulWidget {
  final String folderPath;

  const TemplateFilesScreen({super.key, required this.folderPath});

  @override
  State<TemplateFilesScreen> createState() => _TemplateFilesScreenState();
}

class _TemplateFilesScreenState extends State<TemplateFilesScreen> {
  bool _isLoading = true;
  List<File> _allFiles = [];
  List<File> _filteredFiles = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterFiles);
    _loadTemplateFiles();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFiles);
    _searchController.dispose();
    super.dispose();
  }

  String get _folderName {
    return widget.folderPath.split(Platform.pathSeparator).last;
  }

  Future<void> _loadTemplateFiles() async {
    setState(() => _isLoading = true);
    final directory = Directory(widget.folderPath);
    final List<File> files = [];
    
    if (await directory.exists()) {
      final entities = directory.listSync();
      for (var entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          files.add(entity);
        }
      }
      files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    }
    
    setState(() {
      _allFiles = files;
      _filteredFiles = files;
      _isLoading = false;
    });
  }

  void _filterFiles() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFiles = _allFiles;
      } else {
        _filteredFiles = _allFiles.where((file) {
          final fileName = _getFileName(file).toLowerCase();
          return fileName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadTemplateAndNavigate(File file) async {
    try {
      final jsonString = await file.readAsString();
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      final templateRecord = FormRecord.fromJson(jsonData);

      if (!mounted) return;

      final newRecord = templateRecord.copyWith(
        id: const Uuid().v4(),
        shipDate: DateTime.now(),
        slipNo: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // ▼▼▼【変更】EditFormPageにテンプレートのパスを渡す ▼▼▼
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (context) => EditFormPage(
            initial: newRecord,
            templatePath: file.path, // 👈 この行を追加
          ),
        ),
      );
      // ▲▲▲ ここまで変更 ▲▲▲

      if (ok == true) {
        Navigator.of(context).pop(true);
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('テンプレートの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Future<void> _deleteTemplate(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('削除の確認'),
        content: Text('「${_getFileName(file)}」を本当に削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await file.delete();
        await _loadTemplateFiles();
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('テンプレートを削除しました。'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  String _getFileName(File file) {
    return file.path.split(Platform.pathSeparator).last.replaceAll('.json', '');
  }

  String _formatDateTime(DateTime dt) {
    return DateFormat('yyyy/MM/dd HH:mm').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_folderName のテンプレート'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'テンプレートを検索',
                hintText: '保存名を入力...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _allFiles.isEmpty
                    ? const Center(child: Text('この製品のテンプレートはありません。'))
                    : _filteredFiles.isEmpty
                        ? const Center(child: Text('該当するテンプレートが見つかりません。'))
                        : ListView.builder(
                            itemCount: _filteredFiles.length,
                            itemBuilder: (context, index) {
                              final file = _filteredFiles[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.description_outlined),
                                  title: Text(_getFileName(file)),
                                  subtitle: Text('更新日時: ${_formatDateTime(file.lastModifiedSync())}'),
                                  onTap: () => _loadTemplateAndNavigate(file),
                                  onLongPress: () => _deleteTemplate(file),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}