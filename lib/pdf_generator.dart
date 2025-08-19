// lib/pdf_generator.dart
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models.dart';

class PdfGenerator {
  Future<List<int>> buildA4WithTwoA5(List<FormRecord> records) async {
    final doc = pw.Document();

    // 2件ずつで1ページ
    for (var i = 0; i < records.length; i += 2) {
      final top = records[i];
      final bottom = (i + 1 < records.length) ? records[i + 1] : null;

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (ctx) {
            final page = ctx.page;
            final availableH = page.pageFormat.availableHeight;
            // 上下の間隔 16 を差引いた上で 1/2
            final a5Height = (availableH - 16) / 2;
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                _a5Form(top, ctx, height: a5Height),
                pw.SizedBox(height: 16),
                _a5Form(
                  bottom ??
                      _placeholderRecord(
                        hint: '（下段：空欄）',
                        copyFrom: top,
                      ),
                  ctx,
                  height: a5Height,
                ),
              ],
            );
          },
        ),
      );
    }

    return await doc.save();
  }

  FormRecord _placeholderRecord({required String hint, required FormRecord copyFrom}) {
    return FormRecord(
      id: 'placeholder',
      shipDate: copyFrom.shipDate,
      workPlace: copyFrom.workPlace,
      instructor: copyFrom.instructor,
      slipNo: copyFrom.slipNo,
      productNo: '',
      productName: hint,
      weightKg: null,
      packageStyle: copyFrom.packageStyle,
    );
  }

  pw.Widget _a5Form(FormRecord r, pw.Context ctx, {required double height}) {
    final df = DateFormat('yyyy/MM/dd');
    final small = pw.TextStyle(fontSize: 8);
    final normal = pw.TextStyle(fontSize: 9);
    final bold = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

    return pw.Container(
      height: height,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.8),
      ),
      child: pw.Stack(
        children: [
          // 区切りライン（上:明細表 / 中:図面 / 下:付属材帯）
          _hLine(top: 52),
          _hLine(bottom: 52),

          // ヘッダー（出荷日／作業場所／指示者／伝票No）
          pw.Positioned(
            left: 8,
            top: 4,
            right: 8,
            child: pw.SizedBox(
              height: 18,
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  _headCell('出荷日', df.format(r.shipDate), flex: 3),
                  _headCell('作業場所', r.workPlace, flex: 4),
                  _headCell('指示者', r.instructor, flex: 3),
                  _headCell('伝票No', r.slipNo, flex: 2),
                ],
              ),
            ),
          ),

          // 上段 明細表（製番｜品名｜重量｜荷姿｜数量｜C/S｜腰下No）
          pw.Positioned(
            left: 8,
            right: 8,
            top: 24,
            child: pw.SizedBox(
              height: 26,
              child: pw.Row(
                children: [
                  _cell('製番', r.productNo, flex: 3, align: pw.TextAlign.left),
                  _cell('品名', r.productName, flex: 5, align: pw.TextAlign.left),
                  _cell(
                    '重量(kg)',
                    r.weightKg == null ? '' : _fmtNum(r.weightKg),
                    flex: 2,
                    align: pw.TextAlign.right,
                  ),
                  _cell(
                    '荷姿',
                    packageStyleLabel(r.packageStyle),
                    flex: 2,
                  ),
                ],
              ),
            ),
          ),

          // 中段：寸法・スケッチ
          pw.Positioned(
            left: 8,
            right: 8,
            top: 54,
            bottom: 80,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Expanded(
                  flex: 7,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.6),
                    ),
                    padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 4),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('荷姿: ${packageStyleLabel(r.packageStyle)}', style: normal),
                        pw.Text('材質: ${productMaterialTypeLabel(r.materialType)}', style: normal),
                        pw.Text('床板: ${floorPlateTypeLabel(r.floorPlate)}', style: normal),
                        pw.Text('滑材: ${r.subzai.yobisun != null ? yobisunLabel(r.subzai.yobisun!) : '未選択'} (${r.subzai.count ?? ''}本)', style: normal),
                        pw.Spacer(),
                        pw.Text('図面スケッチ', style: small),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 6),
                pw.Expanded(
                  flex: 5,
                  child: pw.Container(
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(width: 0.6),
                    ),
                    child: pw.Center(
                      child: pw.Text('図面エリア（未実装）', style: small),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 下段：付属材帯
          pw.Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: pw.SizedBox(
              height: 64,
              child: pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(width: 0.6),
                ),
                padding: const pw.EdgeInsets.fromLTRB(6, 4, 6, 4),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // 新しい部材の表示は、印刷レイアウト決定後に実装します。
                    pw.Text('付属材情報（未実装）', style: normal),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _headCell(String title, String value, {int flex = 1}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.6),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 1),
            pw.Text(value, style: pw.TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }

  pw.Widget _cell(String title, String value,
      {int flex = 1, pw.TextAlign align = pw.TextAlign.center}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.6),
        ),
        padding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        child: pw.Column(
          crossAxisAlignment: align == pw.TextAlign.left
              ? pw.CrossAxisAlignment.start
              : (align == pw.TextAlign.right
                  ? pw.CrossAxisAlignment.end
                  : pw.CrossAxisAlignment.center),
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 8)),
            pw.SizedBox(height: 1),
            pw.Text(value, style: pw.TextStyle(fontSize: 10), textAlign: align),
          ],
        ),
      ),
    );
  }

  String _fmtNum(num? v) {
    if (v == null) return '';
    final isInt = (v % 1) == 0;
    return isInt ? v.toInt().toString() : v.toStringAsFixed(1);
  }

  pw.Widget _hLine({double? top, double? bottom}) {
    return pw.Positioned(
      left: 6,
      right: 6,
      top: top,
      bottom: bottom,
      child: pw.Container(height: 0.8, color: PdfColors.black),
    );
  }
}