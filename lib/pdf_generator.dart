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
          margin: const pw.EdgeInsets.all(16),
          build: (ctx) {
            final availableHeight = ctx.page.pageFormat.availableHeight;
            final a5Height = (availableHeight - 16) / 2;
            return pw.Column(
              children: [
                _a5Form(topRecord, ctx, height: a5Height),
                pw.SizedBox(height: 16),
                if (bottomRecord != null)
                  _a5Form(bottomRecord, ctx, height: a5Height)
                else
                  pw.Container(
                    height: a5Height,
                    decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.5, color: PdfColors.grey)),
                    child: pw.Center(child: pw.Text('（下段：空欄）', style: pw.TextStyle(color: PdfColors.grey)))
                  ),
              ],
            );
          },
        ),
      );
    }
    return await doc.save();
  }

  // --- ヘルパー ---
  pw.Widget _labelCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );
  }
  pw.Widget _valueCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  // --- A5フォーム本体 ---
  pw.Widget _a5Form(FormRecord r, pw.Context ctx, {required double height}) {
    final shipDateFormat = DateFormat('MM/dd');
    final insideDim = [r.insideLength, r.insideWidth, r.insideHeight].where((s) => s != null && s.isNotEmpty).join(' x ');
    final outsideDim = [r.outsideLength, r.outsideWidth, r.outsideHeight].where((s) => s != null && s.isNotEmpty).join(' x ');
    final availableWidth = ctx.page.pageFormat.availableWidth - 16; 

    return pw.Container(
      height: height,
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 1.0)),
      padding: const pw.EdgeInsets.fromLTRB(8, 4, 8, 8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 1. ヘッダー
          pw.SizedBox(
            height: 20,
            child: pw.Stack(
              alignment: pw.Alignment.center,
              children: [
                 pw.Text('工　　注　　票', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                 pw.Align(
                   alignment: pw.Alignment.centerLeft,
                   child: pw.SizedBox(
                     width: availableWidth * 0.55, 
                     child: pw.Row(
                       mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                       children: [
                         pw.Text('出荷日: ${shipDateFormat.format(r.shipDate)}', style: const pw.TextStyle(fontSize: 9)),
                         pw.Text('作業場所: ${r.workPlace}', style: const pw.TextStyle(fontSize: 9)),
                         pw.Text('指示者: ${r.instructor}', style: const pw.TextStyle(fontSize: 9)),
                       ]
                     ),
                   ),
                 ),
              ]
            ),
          ),
          pw.Divider(thickness: 0.8, height: 4, color: PdfColors.black),
          
          // 2. 基本情報テーブル
          pw.Table(
            border: pw.TableBorder.all(width: 0.6),
            // 8列分の定義
            columnWidths: const {
              0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth(3),
              2: pw.IntrinsicColumnWidth(), 3: pw.FlexColumnWidth(4),
              4: pw.IntrinsicColumnWidth(), 5: pw.FlexColumnWidth(2),
              6: pw.IntrinsicColumnWidth(), 7: pw.FlexColumnWidth(2),
            },
            children: [
              // --- 1行目 ---
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
              // --- 2行目 ---
              pw.TableRow(
                children: [
                  _labelCell('内寸'),
                  _valueCell(insideDim),
                  _labelCell('重量(net)'),
                  _valueCell(r.weightKg != null ? '${r.weightKg} kg' : ''),
                  // 👈 【修正】pw.TableCellを使用してセルを結合
                  pw.TableCell(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    colSpan: 4,
                    child: pw.Container(),
                  ),
                ]
              ),
              // --- 3行目 ---
               pw.TableRow(
                children: [
                  _labelCell('外寸'),
                  _valueCell(outsideDim),
                  _labelCell('重量(gross)'),
                  _valueCell(r.weightGrossKg != null ? '${r.weightGrossKg} kg' : ''),
                  // 👈 【修正】pw.TableCellを使用してセルを結合
                   pw.TableCell(
                    verticalAlignment: pw.TableCellVerticalAlignment.middle,
                    colSpan: 4,
                    child: pw.Container(),
                  ),
                ]
              ),
            ]
          ),
          
          // 3. 本体 (図面エリア)
          pw.Expanded(
            child: pw.Container(
              margin: const pw.EdgeInsets.only(top: 4),
              // この領域が図面や部材情報などが入るスペースになります
            )
          ),
        ],
      ),
    );
  }
}