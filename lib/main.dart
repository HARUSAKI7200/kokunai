// lib/main.dart
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:printing/printing.dart';
import 'package:uuid/uuid.dart';
import 'edit_form_page.dart';
import 'models.dart';
import 'pdf_generator.dart';
import 'storage.dart';
import 'template_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'ja_JP';
  await initializeDateFormatting('ja_JP', null);
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '工注票アプリ',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        inputDecorationTheme: const InputDecorationTheme(
          filled: false,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FormRecord> _historyList = [];
  bool _isLoading = true;
  // 👈 【修正】日付のフォーマットを変更
  final df = DateFormat('MM/dd');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _isLoading = true);
    final s = StorageService();
    final data = await s.loadAll();
    setState(() {
      _historyList = data..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      _isLoading = false;
    });
  }

  Future<void> _add() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const EditFormPage())
    );
    _reload();
  }

  Future<void> _addFromTemplate() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TemplateListScreen()),
    );
    _reload();
  }

  Future<void> _addFromHistory(FormRecord historyRecord) async {
    final newRecord = historyRecord.copyWith(
      id: const Uuid().v4(),
      shipDate: DateTime.now(),
      slipNo: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditFormPage(initial: newRecord))
    );
    _reload();
  }

  Future<void> _resetHistory() async {
     if (_historyList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('削除できる履歴がありません。')));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('すべての履歴を削除しますか？'),
        content: const Text('この操作は元に戻せません。本当によろしいですか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('すべて削除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await StorageService().deleteAll();
      _reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('作成履歴をリセットしました。'), backgroundColor: Colors.green),
        );
      }
    }
  }

  Future<void> _exportPdf(List<FormRecord> targets) async {
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('出力対象がありません。')));
      return;
    }
    final bytes = await PdfGenerator().buildPdf(targets);
    await Printing.layoutPdf(onLayout: (format) async => Uint8List.fromList(bytes));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('工注票アプリ ホーム'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reload,
            tooltip: '履歴を再読み込み',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add_circle_outline),
              label: const Text('新規工注票を作成'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: _add,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('テンプレートから作成'),
               style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
                backgroundColor: Colors.teal,
              ),
              onPressed: _addFromTemplate,
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '最近作成した工注票',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_sweep, size: 20),
                  label: const Text('履歴をリセット'),
                  onPressed: _resetHistory,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    textStyle: const TextStyle(fontSize: 12)
                  ),
                ),
              ],
            ),
            const Divider(),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _historyList.isEmpty
                      ? Center(
                          child: Text(
                            '作成履歴はありません。\n「履歴に保存して印刷」を押すと履歴に保存されます。',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _historyList.length,
                          itemBuilder: (context, index) {
                            final historyData = _historyList[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6.0),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '出荷日: ${df.format(historyData.shipDate)}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          if (historyData.productNo.isNotEmpty) Text('製番: ${historyData.productNo}'),
                                          Text('品名: ${historyData.productName.isEmpty ? '(品名未入力)' : historyData.productName}'),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _addFromHistory(historyData),
                                      child: const Text('この内容で作成'),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}