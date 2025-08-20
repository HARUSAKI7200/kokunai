import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'storage.dart';
import 'drawing_page.dart';
import 'package:printing/printing.dart';
import 'pdf_generator.dart';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';

import 'drawing_canvas.dart';


class EditFormPage extends StatefulWidget {
  final FormRecord? initial;
  const EditFormPage({super.key, this.initial});

  @override
  State<EditFormPage> createState() => _EditFormPageState();
}

class _EditFormPageState extends State<EditFormPage> {
  final _formKey = GlobalKey<FormState>();
  late FormRecord rec;
  final df = DateFormat('yyyy/MM/dd');
  final Map<String, GlobalKey> _drawingKeys = {};

  @override
  void initState() {
    super.initState();
    rec = widget.initial ??
        FormRecord(
          id: const Uuid().v4(),
          shipDate: DateTime.now(),
          workPlace: '',
          instructor: '',
          slipNo: '',
          productNo: '',
          productName: '',
        );

    _drawingKeys['subzai'] = GlobalKey();
    _drawingKeys['yokoshita'] = GlobalKey();
    _drawingKeys['hiraichi'] = GlobalKey();

    // 非同期でプレビュー画像を生成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _generateAllPreviews();
    });
  }

  Future<void> _generateAllPreviews() async {
    await _generatePreview('subzai', rec.subzaiDrawing);
    await _generatePreview('yokoshita', rec.yokoshitaDrawing);
    await _generatePreview('hiraichi', rec.hiraichiDrawing);
  }

  Future<void> _generatePreview(String key, DrawingData? data) async {
    if (data != null && data.elements.isNotEmpty && _drawingKeys[key]?.currentContext != null) {
      try {
        RenderRepaintBoundary boundary =
            _drawingKeys[key]!.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 1.5); // 解像度を少し上げる
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          if(mounted) {
            setState(() {
              data.previewBytes = byteData.buffer.asUint8List();
            });
          }
        }
      } catch (e) {
        print("Error generating preview for $key: $e");
      }
    }
  }


  T? _numOrNull<T extends num>(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    final v = num.tryParse(s.replaceAll(',', ''));
    if (v == null) return null;
    if (T == int) return v.toInt() as T;
    return v.toDouble() as T;
  }

  Widget _numField({
    required String label,
    String? initial,
    void Function(String)? onChanged,
    String? suffix,
    bool integer = false,
  }) {
    return TextFormField(
      initialValue: initial ?? '',
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (v) {
        if (v == null || v.isEmpty) return null;
        final n = num.tryParse(v.replaceAll(',', ''));
        if (n == null) return '数値で入力';
        if (integer && (n % 1 != 0)) return '整数で入力';
        return null;
      },
      onChanged: onChanged,
    );
  }

  Widget _textField({
    required String label,
    String? initial,
    void Function(String)? onChanged,
    int maxLines = 1,
  }) {
    return TextFormField(
      initialValue: initial ?? '',
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      maxLines: maxLines,
      onChanged: onChanged,
    );
  }

  Widget _yobisunComponentEditor(String title, ComponentSpec c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<Yobisun>(
                  value: c.yobisun,
                  items: Yobisun.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(yobisunLabel(e)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => c.yobisun = v),
                  decoration: const InputDecoration(
                    labelText: '呼び寸',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numField(
                  label: '本数',
                  initial: c.count?.toString() ?? '',
                  onChanged: (v) => c.count = _numOrNull<int>(v),
                  integer: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nedomeComponentEditor(String title, ComponentSpec c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<Yobisun>(
                  value: c.yobisun,
                  items: Yobisun.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(yobisunLabel(e)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => c.yobisun = v),
                  decoration: const InputDecoration(
                    labelText: '呼び寸',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _numField(
                  label: '長さ',
                  initial: c.lengthMm?.toString() ?? '',
                  onChanged: (v) => c.lengthMm = _numOrNull<double>(v),
                  suffix: 'mm',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _numField(
                  label: '本数',
                  initial: c.count?.toString() ?? '',
                  onChanged: (v) => c.count = _numOrNull<int>(v),
                  integer: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _otherComponentEditor(String title, ComponentSpec c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          _textField(
            label: '部材名',
            initial: c.partName,
            onChanged: (v) => c.partName = v,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<Yobisun>(
                  value: c.yobisun,
                  items: Yobisun.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(yobisunLabel(e)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => c.yobisun = v),
                  decoration: const InputDecoration(
                    labelText: '呼び寸',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _numField(
                  label: '長さ',
                  initial: c.lengthMm?.toString() ?? '',
                  onChanged: (v) => c.lengthMm = _numOrNull<double>(v),
                  suffix: 'mm',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _numField(
                  label: '本数',
                  initial: c.count?.toString() ?? '',
                  onChanged: (v) => c.count = _numOrNull<int>(v),
                  integer: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('入力内容にエラーがあります。確認してください。')),
      );
      return;
    }
    await StorageService().upsert(rec);
  }
  
  Future<void> _saveAndPop() async {
    await _save();
    if(mounted) Navigator.of(context).pop(true);
  }

  Future<void> _printPreview() async {
    await _save();
    if (!mounted) return;
     if (!_formKey.currentState!.validate()){
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('入力内容にエラーがあります。')));
       return;
     }

    final bytes = await PdfGenerator().buildA4WithTwoA5([rec]);
    await Printing.layoutPdf(onLayout: (format) async => Uint8List.fromList(bytes));
  }
  
  Future<void> _saveAsTemplate() async {
    await _save();
    if (!mounted) return;

    final productNameController = TextEditingController(text: rec.productName);
    final templateNameController = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('テンプレートとして保存'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productNameController,
              decoration: const InputDecoration(labelText: '製品名（フォルダ名）'),
            ),
            TextField(
              controller: templateNameController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'テンプレート名（ファイル名）'),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('キャンセル'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          FilledButton(
            child: const Text('保存'),
            onPressed: () {
              if (productNameController.text.isNotEmpty &&
                  templateNameController.text.isNotEmpty) {
                Navigator.of(context).pop({
                  'productName': productNameController.text,
                  'templateName': templateNameController.text,
                });
              }
            },
          ),
        ],
      ),
    );

    if (result != null) {
      final productName = result['productName']!;
      final templateName = result['templateName']!;
      await StorageService().saveTemplate(productName, templateName, rec);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('「$productName / $templateName」としてテンプレートを保存しました。')),
        );
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final styleSection = Theme.of(context).textTheme.titleMedium;
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        _saveAndPop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('工注票 編集'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text('基本情報', style: styleSection),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: rec.shipDate,
                            firstDate: DateTime(1990),
                            lastDate: DateTime(2100),
                          );
                          if (d != null) setState(() => rec.shipDate = d);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: '出荷日',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                          ),
                          child: Text(df.format(rec.shipDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _textField(
                        label: '作業場所',
                        initial: rec.workPlace,
                        onChanged: (v) => rec.workPlace = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _textField(
                        label: '指示者',
                        initial: rec.instructor,
                        onChanged: (v) => rec.instructor = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: _textField(
                        label: '製番',
                        initial: rec.productNo,
                        onChanged: (v) => rec.productNo = v,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _textField(
                        label: '品名',
                        initial: rec.productName,
                        onChanged: (v) => rec.productName = v,
                      ),
                    ),
                     const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: _numField(
                        label: '重量',
                        initial: rec.weightKg?.toString() ?? '',
                        onChanged: (v) => rec.weightKg = _numOrNull<double>(v),
                        suffix: 'kg',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSectionHeader('寸法（長×幅×高）'),
                Row(
                  children: [
                    const SizedBox(width: 40, child: Text('内寸:', textAlign: TextAlign.right)),
                    const SizedBox(width: 8),
                    Expanded(child: _textField(label: 'L', initial: rec.insideLength, onChanged: (v) => rec.insideLength = v)),
                    const SizedBox(width: 8),
                    Expanded(child: _textField(label: 'W', initial: rec.insideWidth, onChanged: (v) => rec.insideWidth = v)),
                    const SizedBox(width: 8),
                    Expanded(child: _textField(label: 'H', initial: rec.insideHeight, onChanged: (v) => rec.insideHeight = v)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 40, child: Text('外寸:', textAlign: TextAlign.right)),
                    const SizedBox(width: 8),
                    Expanded(child: _textField(label: 'L', initial: rec.outsideLength, onChanged: (v) => rec.outsideLength = v)),
                    const SizedBox(width: 8),
                    Expanded(child: _textField(label: 'W', initial: rec.outsideWidth, onChanged: (v) => rec.outsideWidth = v)),
                    const SizedBox(width: 8),
                    Expanded(child: _textField(label: 'H', initial: rec.outsideHeight, onChanged: (v) => rec.outsideHeight = v)),
                  ],
                ),
                _buildSectionHeader('荷姿'),
                Row(
                  children: PackageStyle.values
                      .map((e) => Expanded(
                            child: RadioListTile<PackageStyle>(
                              title: Text(packageStyleLabel(e)),
                              value: e,
                              groupValue: rec.packageStyle,
                              onChanged: (v) => setState(() => rec.packageStyle = v!),
                            ),
                          ))
                      .toList(),
                ),

                _buildSectionHeader('材質'),
                 Row(
                  children: ProductMaterialType.values
                      .map((e) => Expanded(
                            child: RadioListTile<ProductMaterialType>(
                              title: Text(productMaterialTypeLabel(e)),
                              value: e,
                              groupValue: rec.materialType,
                              onChanged: (v) => setState(() => rec.materialType = v!),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
               
                Text('部材情報', style: styleSection),
                const SizedBox(height: 6),
                _yobisunComponentEditor('滑材', rec.subzai),
                _yobisunComponentEditor(getaOrSuriTypeLabel(rec.getaOrSuri), rec.getaOrSuriSpec),
                _yobisunComponentEditor('H', rec.h),
                _yobisunComponentEditor('負荷材1', rec.fukazai1),
                _yobisunComponentEditor('負荷材2', rec.fukazai2),
                _nedomeComponentEditor('根止め1', rec.nedome1),
                _nedomeComponentEditor('根止め2', rec.nedome2),
                _nedomeComponentEditor('根止め3', rec.nedome3),
                _nedomeComponentEditor('根止め4', rec.nedome4),
                _yobisunComponentEditor('押さえ', rec.osae),
                _yobisunComponentEditor('梁', rec.ryo),
                _otherComponentEditor('他1', rec.other1),
                _otherComponentEditor('他2', rec.other2),
                const SizedBox(height: 16),
                Text('図面', style: styleSection),
                const SizedBox(height: 6),
                Column(
                  children: [
                    _drawingButton('滑材', 'subzai', rec.subzaiDrawing, (data) {
                      setState(() => rec.subzaiDrawing = data);
                    }, 'assets/images/国内工注票滑材.jpg'),
                    const SizedBox(height: 16),
                    _drawingButton('腰下', 'yokoshita', rec.yokoshitaDrawing, (data) {
                      setState(() => rec.yokoshitaDrawing = data);
                    }, 'assets/images/国内工注票腰下図面.jpg'),
                    const SizedBox(height: 16),
                    _drawingButton('側ツマ', 'hiraichi', rec.hiraichiDrawing, (data) {
                      setState(() => rec.hiraichiDrawing = data);
                    }, 'assets/images/国内工注票平打ち.jpg'),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _saveAsTemplate,
                        icon: const Icon(Icons.save_as),
                        label: const Text('テンプレートとして保存'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _printPreview,
                        icon: const Icon(Icons.print),
                        label: const Text('この内容で印刷プレビュー'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 6.0),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _drawingButton(
      String label, String key, DrawingData? data, Function(DrawingData?) onSave, String imagePath) {
    return Column(
      children: [
        FractionallySizedBox(
          widthFactor: 0.8,
          child: AspectRatio(
            aspectRatio: 4 / 3,
            child: InkWell(
              onTap: () => _navigateToDrawingPage(data, onSave, imagePath, key),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: data?.previewBytes != null
                      ? Image.memory(data!.previewBytes, fit: BoxFit.contain)
                      : (data != null && data.elements.isNotEmpty
                          ? RepaintBoundary(
                              key: _drawingKeys[key],
                              child: CustomPaint(
                                foregroundPainter: DrawingPreviewPainter(
                                  elements: data.elements.map((e) => DrawingElement.fromJson(e)).toList(),
                                  sourceSize: (data.sourceWidth != null && data.sourceHeight != null)
                                      ? Size(data.sourceWidth!, data.sourceHeight!)
                                      : null,
                                ),
                                child: Image.asset(imagePath, fit: BoxFit.contain),
                              ),
                            )
                          : Image.asset(imagePath, fit: BoxFit.contain)),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  void _navigateToDrawingPage(DrawingData? data, Function(DrawingData?) onSave, String imagePath, String previewKey) async {
    final result = await Navigator.of(context).push<DrawingData>(
      MaterialPageRoute(
        builder: (_) => DrawingPage(
          initialData: data,
          backgroundImage: imagePath,
        ),
      ),
    );
    if (result != null) {
      onSave(result);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generatePreview(previewKey, result);
      });
    }
  }
}

class DrawingPreviewPainter extends CustomPainter {
  final List<DrawingElement> elements;
  final Size? sourceSize;

  DrawingPreviewPainter({required this.elements, this.sourceSize});

  @override
  void paint(Canvas canvas, Size size) {
    // レイヤーを保存し、BlendMode.clear（消しゴム）が正しく機能するようにする
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 描画ズレを補正
    if (sourceSize == null || (sourceSize!.width == 0 || sourceSize!.height == 0)) {
      // 古いデータ or 不正なデータの場合は、とりあえず描画
      for (final element in elements) {
        element.draw(canvas, size);
      }
    } else {
      // 背景画像と同じように `BoxFit.contain` のロジックで描画内容をスケーリング
      final FittedSizes fittedSizes = applyBoxFit(BoxFit.contain, sourceSize!, size);
      final Rect destRect = Alignment.center.inscribe(fittedSizes.destination, Rect.fromLTWH(0, 0, size.width, size.height));
      final double scale = destRect.width / sourceSize!.width;
      final Offset translate = destRect.topLeft;

      canvas.save();
      canvas.translate(translate.dx, translate.dy);
      canvas.scale(scale, scale);

      // 変換後のキャンバスに描画
      for (final element in elements) {
        element.draw(canvas, sourceSize!);
      }
      canvas.restore();
    }
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant DrawingPreviewPainter oldDelegate) => true;
}