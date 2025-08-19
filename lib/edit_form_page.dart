import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'storage.dart';
import 'drawing_page.dart';

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
    if (!_formKey.currentState!.validate()) return;
    await StorageService().upsert(rec);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final styleSection = Theme.of(context).textTheme.titleMedium;
    return Scaffold(
      appBar: AppBar(
        title: const Text('工注票 編集'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: '保存',
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text('ヘッダー', style: styleSection),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
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
                    child: _textField(
                      label: '作業場所',
                      initial: rec.workPlace,
                      onChanged: (v) => rec.workPlace = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _textField(
                      label: '指示者',
                      initial: rec.instructor,
                      onChanged: (v) => rec.instructor = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('基本情報', style: styleSection),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      label: '製番',
                      initial: rec.productNo,
                      onChanged: (v) => rec.productNo = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _textField(
                      label: '品名',
                      initial: rec.productName,
                      onChanged: (v) => rec.productName = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
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
              Text('荷姿', style: styleSection),
              const SizedBox(height: 6),
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
              const SizedBox(height: 16),
              Text('材質', style: styleSection),
              const SizedBox(height: 6),
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
              Text('床板', style: styleSection),
              const SizedBox(height: 6),
              Row(
                children: FloorPlateType.values
                    .map((e) => Expanded(
                          child: RadioListTile<FloorPlateType>(
                            title: Text(floorPlateTypeLabel(e)),
                            value: e,
                            groupValue: rec.floorPlate,
                            onChanged: (v) => setState(() => rec.floorPlate = v!),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text('ゲタ or すり材', style: styleSection),
              const SizedBox(height: 6),
              Row(
                children: GetaOrSuriType.values
                    .map((e) => Expanded(
                          child: RadioListTile<GetaOrSuriType>(
                            title: Text(getaOrSuriTypeLabel(e)),
                            value: e,
                            groupValue: rec.getaOrSuri,
                            onChanged: (v) => setState(() => rec.getaOrSuri = v!),
                          ),
                        ))
                    .toList(),
              ),
              _yobisunComponentEditor(getaOrSuriTypeLabel(rec.getaOrSuri), rec.getaOrSuriSpec),
              const SizedBox(height: 16),
              Text('部材情報', style: styleSection),
              const SizedBox(height: 6),
              _yobisunComponentEditor('滑材', rec.subzai),
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
              Row(
                children: [
                  _drawingButton('滑材', rec.subzaiDrawing, (data) {
                    setState(() => rec.subzaiDrawing = data);
                  }, 'assets/images/国内工注票滑材.jpg'),
                  const SizedBox(width: 8),
                  _drawingButton('腰下', rec.yokoshitaDrawing, (data) {
                    setState(() => rec.yokoshitaDrawing = data);
                  }, 'assets/images/国内工注票腰下図面.jpg'),
                  const SizedBox(width: 8),
                  _drawingButton('側ツマ', rec.hiraichiDrawing, (data) {
                    setState(() => rec.hiraichiDrawing = data);
                  }, 'assets/images/国内工注票平打ち.jpg'),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text('保存する'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawingButton(
      String label, DrawingData? data, Function(DrawingData?) onSave, String imagePath) {
    return Expanded(
      child: Column(
        children: [
          FilledButton.icon(
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DrawingPage(
                    initialData: data,
                    backgroundImage: imagePath,
                  ),
                ),
              );
              if (result != null && result is DrawingData) {
                onSave(result);
              }
            },
            icon: const Icon(Icons.edit),
            label: Text('$label図面'),
          ),
          if (data != null && data.elements.isNotEmpty)
            const Text('描画済み'),
        ],
      ),
    );
  }
}