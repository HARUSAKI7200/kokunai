import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'models.dart';
import 'storage.dart';

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

  Widget _componentEditor(String title, ComponentSpec c,
      {bool countIsPlaces = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          dense: true,
          title: Text('$title：${c.enabled ? "有" : "無"}'),
          value: c.enabled,
          onChanged: (v) => setState(() => c.enabled = v),
        ),
        if (title == '他')
          _textField(
            label: '他の内容メモ',
            initial: c.note,
            onChanged: (v) => c.note = v,
          )
        else
          Row(
            children: [
              Expanded(
                child: _numField(
                  label: '幅',
                  suffix: 'mm',
                  initial: c.widthMm?.toString() ?? '',
                  onChanged: (v) => c.widthMm = _numOrNull<double>(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numField(
                  label: '厚さ',
                  suffix: 'mm',
                  initial: c.thicknessMm?.toString() ?? '',
                  onChanged: (v) => c.thicknessMm = _numOrNull<double>(v),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _numField(
                  label: countIsPlaces ? '箇所数' : '本数',
                  initial: c.count?.toString() ?? '',
                  integer: true,
                  onChanged: (v) => c.count = _numOrNull<int>(v),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
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
          )
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
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _textField(
                      label: '指示者',
                      initial: rec.instructor,
                      onChanged: (v) => rec.instructor = v,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _textField(
                      label: '伝票No',
                      initial: rec.slipNo,
                      onChanged: (v) => rec.slipNo = v,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text('明細（上段表）', style: styleSection),
              const SizedBox(height: 6),
              _textField(
                label: '① 製番',
                initial: rec.productNo,
                onChanged: (v) => rec.productNo = v,
              ),
              const SizedBox(height: 8),
              _textField(
                label: '② 品名',
                initial: rec.productName,
                onChanged: (v) => rec.productName = v,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _numField(
                      label: '③ 重量',
                      suffix: 'kg',
                      initial: rec.weightKg?.toString() ?? '',
                      onChanged: (v) => rec.weightKg = _numOrNull<double>(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<PackageStyle>(
                      value: rec.packageStyle,
                      items: PackageStyle.values
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(packageStyleLabel(e)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => rec.packageStyle = v!),
                      decoration: const InputDecoration(
                        labelText: '④ 荷姿',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _textField(
                      label: '荷姿（その他）',
                      initial: rec.packageOtherText,
                      onChanged: (v) => rec.packageOtherText = v,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _numField(
                      label: '⑤ 数量',
                      initial: rec.quantity?.toString() ?? '',
                      integer: true,
                      onChanged: (v) => rec.quantity = _numOrNull<int>(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _numField(
                      label: '⑥ C/S',
                      initial: rec.cases?.toString() ?? '',
                      integer: true,
                      onChanged: (v) => rec.cases = _numOrNull<int>(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _textField(
                      label: '⑦ 腰下No',
                      initial: rec.waistNo,
                      onChanged: (v) => rec.waistNo = v,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text('寸法・図面情報（中段）', style: styleSection),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _numField(
                      label: '外のり幅',
                      suffix: 'mm',
                      initial: rec.outerWidthMm?.toString() ?? '',
                      onChanged: (v) => rec.outerWidthMm = _numOrNull<double>(v),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _numField(
                      label: '内のり高',
                      suffix: 'mm',
                      initial: rec.innerHeightMm?.toString() ?? '',
                      onChanged: (v) => rec.innerHeightMm = _numOrNull<double>(v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _textField(
                label: '内容品質量（自由記述）',
                initial: rec.contentQuality,
                onChanged: (v) => rec.contentQuality = v,
                maxLines: 2,
              ),

              const SizedBox(height: 16),
              Text('付属材（下段帯）', style: styleSection),
              const SizedBox(height: 6),
              _componentEditor('梁', rec.beam),
              _componentEditor('ゲタ', rec.geta),
              _componentEditor('押', rec.oshi),
              _componentEditor('止', rec.tome, countIsPlaces: true),
              _componentEditor('他', rec.other),

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
}
