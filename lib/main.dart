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
      title: '工注票（A5×2, A4出力）',
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
  List<FormRecord> list = [];
  final df = DateFormat('yyyy/MM/dd');

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final s = StorageService();
    final data = await s.loadAll();
    setState(() {
      list = data..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    });
  }

  Future<void> _add() async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const EditFormPage()));
    if (ok == true) _reload();
  }

  // 新しいメソッドを追加
  Future<void> _addFromTemplate() async {
    // テンプレートから作成するロジックをここに実装
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const EditFormPage()));
    if (ok == true) _reload();
  }

  Future<void> _edit(FormRecord r) async {
    final ok = await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => EditFormPage(initial: r)));
    if (ok == true) _reload();
  }

  Future<void> _delete(FormRecord r) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除しますか？'),
        content: Text('「${r.productName}」(${df.format(r.shipDate)}) を削除します。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('キャンセル')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('削除')),
        ],
      ),
    );
    if (yes == true) {
      await StorageService().delete(r.id);
      _reload();
    }
  }

  Future<void> _exportPdf(List<FormRecord> targets) async {
    if (targets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('出力対象がありません。')));
      return;
    }
    final bytes = await PdfGenerator().buildA4WithTwoA5(targets);
    await Printing.layoutPdf(onLayout: (format) async => Uint8List.fromList(bytes));
  }

  @override
  Widget build(BuildContext context) {
    final dfTime = DateFormat('yyyy/MM/dd HH:mm');
    return Scaffold(
      appBar: AppBar(
        title: const Text('工注票 一覧'),
        actions: [
          IconButton(
            tooltip: '全件をA4（A5×2）で出力',
            onPressed: () => _exportPdf(list),
            icon: const Icon(Icons.print),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _add,
                      icon: const Icon(Icons.add),
                      label: const Text('新規作成'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _addFromTemplate,
                      icon: const Icon(Icons.copy),
                      label: const Text('テンプレートから作成'),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: list.isEmpty
                  ? const Center(child: Text('データがありません。右下の「新規」から作成してください。'))
                  : ListView.separated(
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = list[i];
                        final subtitle = [
                          '出荷日:${df.format(r.shipDate)}',
                          if (r.productNo.isNotEmpty) '製番:${r.productNo}',
                        ].join('  ');
                        return ListTile(
                          title: Text(r.productName.isEmpty ? '（品名未入力）' : r.productName),
                          subtitle: Text('$subtitle\n更新:${dfTime.format(r.updatedAt)}'),
                          isThreeLine: true,
                          onTap: () => _edit(r),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: 'この1件を出力',
                                onPressed: () => _exportPdf([r]),
                                icon: const Icon(Icons.picture_as_pdf),
                              ),
                              IconButton(
                                tooltip: '削除',
                                onPressed: () => _delete(r),
                                icon: const Icon(Icons.delete),
                              ),
                            ],
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