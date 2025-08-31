// lib/template_list_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'template_files_screen.dart';

class TemplateListScreen extends StatefulWidget {
  const TemplateListScreen({super.key});

  @override
  State<TemplateListScreen> createState() => _TemplateListScreenState();
}

class _TemplateListScreenState extends State<TemplateListScreen> {
  bool _isLoading = true;
  List<Directory> _allFolders = [];
  List<Directory> _filteredFolders = [];
  final TextEditingController _searchController = TextEditingController();
  static const _templateDir = 'templates';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterFolders);
    _loadProductFolders();
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterFolders);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProductFolders() async {
    setState(() {
      _isLoading = true;
    });
    
    final appDir = await getApplicationDocumentsDirectory();
    final templateRootDir = Directory('${appDir.path}/$_templateDir');

    final List<Directory> folders = [];
    if (await templateRootDir.exists()) {
      final entities = templateRootDir.listSync();
      for (var entity in entities) {
        if (entity is Directory) {
          folders.add(entity);
        }
      }
      folders.sort((a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()));
    }

    setState(() {
      _allFolders = folders;
      _filteredFolders = folders;
      _isLoading = false;
    });
  }

  void _filterFolders() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredFolders = _allFolders;
      } else {
        _filteredFolders = _allFolders.where((folder) {
          final folderName = _getFolderName(folder).toLowerCase();
          return folderName.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _deleteFolder(Directory folder) async {
    final folderName = _getFolderName(folder);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('フォルダの削除'),
        content: Text('「$folderName」フォルダを削除しますか？\nフォルダ内のすべてのテンプレートも削除されます。'),
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
        await folder.delete(recursive: true);
        await _loadProductFolders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('「$folderName」フォルダを削除しました。'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('フォルダの削除に失敗しました: $e')),
          );
        }
      }
    }
  }

  String _getFolderName(Directory folder) {
    return folder.path.split(Platform.pathSeparator).last;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('製品フォルダを選択'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '製品フォルダを検索',
                hintText: '製品名を入力...',
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
                : _allFolders.isEmpty
                    ? const Center(
                        child: Text(
                          '保存された製品フォルダがありません。\n入力画面からテンプレートを保存してください。',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : _filteredFolders.isEmpty
                        ? const Center(
                            child: Text(
                              '該当する製品フォルダが見つかりません。',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredFolders.length,
                            itemBuilder: (context, index) {
                              final folder = _filteredFolders[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                child: ListTile(
                                  leading: const Icon(Icons.folder_open),
                                  title: Text(_getFolderName(folder)),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    // isPopped は bool? 型なので、明示的にチェック
                                    Navigator.of(context).push<bool>(
                                      MaterialPageRoute(
                                        builder: (context) => TemplateFilesScreen(folderPath: folder.path),
                                      ),
                                    ).then((isPopped) {
                                      // ファイル選択画面から直接戻ってきた(isPopped == true)ら、
                                      // この画面も閉じてホームに戻る
                                      if (isPopped == true) {
                                        Navigator.of(context).pop(true);
                                      } else {
                                        // フォルダが削除された可能性を考慮して再読み込み
                                        _loadProductFolders();
                                      }
                                    });
                                  },
                                  onLongPress: () {
                                    _deleteFolder(folder);
                                  },
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