// lib/pdf_generator.dart
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models.dart';

class PdfGenerator {
  Future<List<int>> buildA4WithTwoA5(List<FormRecord> records) async {
    final doc = pw.Document();

    final font = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansJP-Regular.ttf"));
    final boldFont = pw.Font.ttf(await rootBundle.load("assets/fonts/NotoSansJP-Bold.ttf"));
    
    final theme = pw.ThemeData.withFont(base: boldFont, bold: boldFont);

    for (var i = 0; i < records.length; i += 2) {
      final topRecord = records[i];
      final bottomRecord = (i + 1 < records.length) ? records[i + 1] : null;

      doc.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          // 👈 【変更】ページの余白は0にし、手動でコントロールします
          margin: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 0), 
          build: (ctx) {
            // --- ここからレイアウト計算方法を変更 ---
            // ★★★ 上下の余白を調整 (単位はポイント。28.35ポイント = 約1cm) ★★★
            const topPageMargin = 28.0; 
            const bottomPageMargin = 28.0; 
            const middleGap = 4.0;

            // 利用可能な高さから、手動で設定した上下の余白とフォーム間の隙間を引く
            final contentAreaHeight = ctx.page.pageFormat.availableHeight - topPageMargin - bottomPageMargin;
            final halfHeight = (contentAreaHeight - middleGap) / 2;
            
            return pw.Column(
              children: [
                pw.SizedBox(height: topPageMargin),
                
                _a5Form(topRecord, ctx, height: halfHeight),
                
                pw.SizedBox(height: middleGap), 
                
                if (bottomRecord != null)
                  _a5Form(bottomRecord, ctx, height: halfHeight)
                else
                  pw.Container(
                    height: halfHeight,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5, color: PdfColors.grey)),
                    child: pw.Center(child: pw.Text('（下段：空欄）', style: pw.TextStyle(color: PdfColors.grey)))
                  ),

                // pw.Expanded を使って残りのスペースを埋めることで、下の余白を確保
                pw.Expanded(child: pw.Container()),
              ],
            );
          },
        ),
      );
    }
    return await doc.save();
  }

  // --- ヘルパー (変更なし) ---
  pw.Widget _labelCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }
  pw.Widget _valueCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      constraints: const pw.BoxConstraints(minHeight: 15),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }
  
  pw.Widget _bigValueCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      constraints: const pw.BoxConstraints(minHeight: 17),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
    );
  }

  // --- A5フォーム本体 (変更なし) ---
  pw.Widget _a5Form(FormRecord r, pw.Context ctx, {required double height}) {
    final shipDateFormat = DateFormat('MM/dd');
    final insideDim = [r.insideLength, r.insideWidth, r.insideHeight].where((s) => s != null && s.isNotEmpty).join(' x ');
    final outsideDim = [r.outsideLength, r.outsideWidth, r.outsideHeight].where((s) => s != null && s.isNotEmpty).join(' x ');

    return pw.Container(
      height: height,
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.0)),
      padding: const pw.EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.SizedBox(
                height: 32,
                child: pw.Stack(
                  alignment: pw.Alignment.center,
                  children: [
                    pw.Text(
                      '工　注　票',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        decoration: pw.TextDecoration.underline,
                      ),
                    ),
                    pw.Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: pw.Table(
                         border: pw.TableBorder.all(width: 0.6),
                         columnWidths: const {
                           0: pw.IntrinsicColumnWidth(),
                           1: pw.IntrinsicColumnWidth(),
                           2: pw.IntrinsicColumnWidth(),
                         },
                         children: [
                           pw.TableRow(
                             children: [
                               _labelCell('出荷日'),
                               _labelCell('作業場所'),
                               _labelCell('指示者'),
                             ]
                           ),
                            pw.TableRow(
                             children: [
                               _valueCell(shipDateFormat.format(r.shipDate)),
                               _valueCell(r.workPlace),
                               _valueCell(r.instructor),
                             ]
                           )
                         ]
                      ),
                    ),
                  ]
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Table(
                border: pw.TableBorder.all(width: 0.6),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth(1),
                  2: pw.IntrinsicColumnWidth(), 3: pw.FlexColumnWidth(1),
                  4: pw.IntrinsicColumnWidth(), 5: pw.FlexColumnWidth(1),
                  6: pw.IntrinsicColumnWidth(), 7: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _labelCell('製番'),
                      _valueCell(r.productNo),
                      _labelCell('品名'),
                      _valueCell(r.productName),
                      _labelCell('荷姿'),
                      _valueCell(packageStyleLabel(r.packageStyle)),
                      _labelCell('材質'),
                      _valueCell(productMaterialTypeLabel(r.materialType)),
                    ]
                  ),
                ]
              ),
              pw.Table(
                border: pw.TableBorder.all(width: 0.6),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth(1),
                  2: pw.IntrinsicColumnWidth(), 3: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _labelCell('内寸'),
                      _bigValueCell(insideDim),
                      _labelCell('外寸'),
                      _bigValueCell(outsideDim),
                    ]
                  )
                ]
              ),
              pw.Table(
                border: pw.TableBorder.all(width: 0.6),
                defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth(1),
                  2: pw.IntrinsicColumnWidth(), 3: pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    children: [
                      _labelCell('重量(net)'),
                      _valueCell(r.weightKg != null ? '${r.weightKg} kg' : ''),
                      _labelCell('重量(gross)'),
                      _valueCell(r.weightGrossKg != null ? '${r.weightGrossKg} kg' : ''),
                    ]
                  )
                ]
              ),
            ]
          ),
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(top: 4),
            )
          ),
        ],
      ),
    );
  }
}