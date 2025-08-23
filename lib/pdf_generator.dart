// lib/pdf_generator.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'models.dart';
// 描画モデルクラスをインポート
import 'drawing_canvas.dart' as dc;

class PdfGenerator {
  Future<List<int>> buildPdf(List<FormRecord> records) async {
    final doc = pw.Document();

    // フォントデータを読み込む
    final fontData = await rootBundle.load("assets/fonts/NotoSansJP-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    // 👈【修正】pw.Fontオブジェクトから低レベルAPI用のPdfFontを取得
    final pdfFont = ttf.font;

    final theme = pw.ThemeData.withFont(base: ttf, bold: ttf);

    for (final record in records) {
      doc.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (ctx) {
            // ページコンテンツのビルドにPdfFontを渡す
            return _buildPageContent(ctx, record, pdfFont);
          },
        ),
      );
    }
    return await doc.save();
  }

  pw.Widget _buildPageContent(pw.Context ctx, FormRecord r, PdfFont pdfFont) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(r),
        pw.SizedBox(height: 12),
        _buildDrawings(r, pdfFont), // 描画にはPdfFontを使用
        pw.SizedBox(height: 12),
        pw.Text('部材情報', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        _buildComponentsTable(r),
      ],
    );
  }

  pw.Widget _buildHeader(FormRecord r) {
    final shipDateFormat = DateFormat('yyyy/MM/dd');
    final insideDim = [r.insideLength, r.insideWidth, r.insideHeight].where((s) => s != null && s.isNotEmpty).join(' x ');
    final outsideDim = [r.outsideLength, r.outsideWidth, r.outsideHeight].where((s) => s != null && s.isNotEmpty).join(' x ');
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.SizedBox(
          height: 40,
          child: pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              pw.Text('工　注　票', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, decoration: pw.TextDecoration.underline)),
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Table(
                   border: pw.TableBorder.all(width: 0.6),
                   columnWidths: const {
                     0: pw.IntrinsicColumnWidth(), 1: pw.IntrinsicColumnWidth(), 2: pw.IntrinsicColumnWidth(),
                   },
                   children: [
                     pw.TableRow(children: [_labelCell('出荷日'), _labelCell('作業場所'), _labelCell('指示者')]),
                     pw.TableRow(children: [_valueCell(shipDateFormat.format(r.shipDate)), _valueCell(r.workPlace), _valueCell(r.instructor)])
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
            0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth(1), 2: pw.IntrinsicColumnWidth(), 3: pw.FlexColumnWidth(1),
            4: pw.IntrinsicColumnWidth(), 5: pw.FlexColumnWidth(1), 6: pw.IntrinsicColumnWidth(), 7: pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(children: [
                _labelCell('製番'), _valueCell(r.productNo),
                _labelCell('品名'), _valueCell(r.productName),
                _labelCell('荷姿'), _valueCell(packageStyleLabel(r.packageStyle)),
                _labelCell('材質'), _valueCell(productMaterialTypeLabel(r.materialType)),
            ]),
          ]
        ),
        pw.Table(
          border: pw.TableBorder.all(width: 0.6), defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          columnWidths: const { 0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth(1), 2: pw.IntrinsicColumnWidth(), 3: pw.FlexColumnWidth(1) },
          children: [pw.TableRow(children: [_labelCell('内寸'), _bigValueCell(insideDim), _labelCell('外寸'), _bigValueCell(outsideDim)])]
        ),
        pw.Table(
          border: pw.TableBorder.all(width: 0.6), defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
          columnWidths: const { 0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth(1), 2: pw.IntrinsicColumnWidth(), 3: pw.FlexColumnWidth(1) },
          children: [pw.TableRow(children: [
              _labelCell('重量(net)'), _valueCell(r.weightKg != null ? '${r.weightKg} kg' : ''),
              _labelCell('重量(gross)'), _valueCell(r.weightGrossKg != null ? '${r.weightGrossKg} kg' : ''),
          ])]
        ),
      ]
    );
  }

  pw.Widget _buildDrawings(FormRecord r, PdfFont font) {
    pw.Widget drawingBox(String title, DrawingData? drawingData) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey, width: 0.5)),
              child: (drawingData != null && drawingData.elements.isNotEmpty)
                  ? pw.CustomPaint(
                      painter: (canvas, size) {
                        _drawVectorGraphics(canvas, size, drawingData, font);
                      },
                    )
                  : pw.Center(child: pw.Text('図面なし', style: const pw.TextStyle(color: PdfColors.grey))),
            ),
          ),
        ],
      );
    }
    
    return pw.SizedBox(
      height: 300,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(flex: 2, child: drawingBox('腰下', r.yokoshitaDrawing)),
          pw.SizedBox(width: 8),
          pw.Expanded(flex: 2,
            child: pw.Column(children: [
                pw.Expanded(flex: 2, child: drawingBox('側ツマ', r.hiraichiDrawing)),
                pw.SizedBox(height: 8),
                pw.Expanded(flex: 1, child: drawingBox('滑材', r.subzaiDrawing)),
            ]),
          ),
        ],
      ),
    );
  }

  void _drawVectorGraphics(PdfGraphics canvas, PdfPoint size, DrawingData data, PdfFont font) {
    final elements = data.elements.map((e) => dc.DrawingElement.fromJson(e)).toList();
    final sourceSize = (data.sourceWidth != null && data.sourceHeight != null)
        ? PdfPoint(data.sourceWidth!, data.sourceHeight!)
        : const PdfPoint(1, 1);

    final double scaleX = size.x / sourceSize.x;
    final double scaleY = size.y / sourceSize.y;
    final double scale = math.min(scaleX, scaleY);
    final double offsetX = (size.x - sourceSize.x * scale) / 2;
    final double offsetY = (size.y - sourceSize.y * scale) / 2;

    double transformY(double y) => sourceSize.y - y;

    canvas.saveContext();
    // 👈【修正】setTransformにPdfMatrixオブジェクトを渡す
    canvas.setTransform(PdfMatrix(scale, 0, 0, -scale, offsetX, offsetY + size.y));

    for (final element in elements) {
      final color = PdfColor.fromInt(element.paint.color.value);
      canvas
        ..saveContext()
        ..setColor(color)
        ..setLineWidth(element.paint.strokeWidth);

      if (element is dc.DrawingPath) {
        if (element.points.isNotEmpty) {
          canvas.moveTo(element.points.first.dx, transformY(element.points.first.dy));
          for (var i = 1; i < element.points.length; i++) {
            canvas.lineTo(element.points[i].dx, transformY(element.points[i].dy));
          }
          canvas.strokePath();
        }
      } else if (element is dc.StraightLine) {
        canvas
          ..moveTo(element.start.dx, transformY(element.start.dy))
          ..lineTo(element.end.dx, transformY(element.end.dy))
          ..strokePath();
      } else if (element is dc.Rectangle) {
        canvas
          ..drawRect(element.rect.left, transformY(element.rect.top), element.rect.width, element.rect.height)
          ..strokePath();
      } else if (element is dc.DimensionLine) {
        final start = PdfPoint(element.start.dx, transformY(element.start.dy));
        final end = PdfPoint(element.end.dx, transformY(element.end.dy));
         canvas
          ..moveTo(start.x, start.y)
          ..lineTo(end.x, end.y)
          ..strokePath();
        _drawPdfArrow(canvas, end, start);
        _drawPdfArrow(canvas, start, end);
      } else if (element is dc.DrawingText) {
         canvas.drawString(
          font,
          16 / scale,
          element.text,
          element.position.dx,
          transformY(element.position.dy) - (16 / scale),
        );
      }
      canvas.restoreContext();
    }
    canvas.restoreContext();
  }
  
  void _drawPdfArrow(PdfGraphics canvas, PdfPoint p1, PdfPoint p2) {
    const arrowSize = 8.0;
    final angle = math.atan2(p1.y - p2.y, p1.x - p2.x);
    canvas
      ..moveTo(p1.x - arrowSize * math.cos(angle - math.pi / 6), p1.y - arrowSize * math.sin(angle - math.pi / 6))
      ..lineTo(p1.x, p1.y)
      ..lineTo(p1.x - arrowSize * math.cos(angle + math.pi / 6), p1.y - arrowSize * math.sin(angle + math.pi / 6))
      ..strokePath();
  }

  pw.Widget _buildComponentsTable(FormRecord r) {
    const headerStyle = pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    const cellStyle = pw.TextStyle(fontSize: 9);
    final List<List<String>> tableData = [];
    final components = {
      '滑材': r.subzai, getaOrSuriTypeLabel(r.getaOrSuri): r.getaOrSuriSpec, 'H': r.h, '負荷材1': r.fukazai1, '負荷材2': r.fukazai2,
      '根止め1': r.nedome1, '根止め2': r.nedome2, '根止め3': r.nedome3, '根止め4': r.nedome4,
      '押さえ': r.osae, '梁': r.ryo, '他1': r.other1, '他2': r.other2,
    };
    
    components.forEach((name, spec) {
      if ((spec.count != null && spec.count! > 0) || (spec.partName != null && spec.partName!.isNotEmpty)) {
        tableData.add([
          spec.partName?.isNotEmpty == true ? spec.partName! : name, spec.yobisun != null ? yobisunLabel(spec.yobisun!) : '-',
          spec.lengthMm?.toString() ?? '-', spec.count?.toString() ?? '-',
        ]);
      }
    });

    if (tableData.isEmpty) return pw.Container();
    
    return pw.Table.fromTextArray(
      headers: ['部材名', '呼び寸', '長さ (mm)', '本数'], data: tableData,
      headerStyle: headerStyle, cellStyle: cellStyle,
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
      cellAlignment: pw.Alignment.center, cellAlignments: {0: pw.Alignment.centerLeft},
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.black),
      columnWidths: const { 0: pw.FlexColumnWidth(2.5), 1: pw.FlexColumnWidth(1.5), 2: pw.FlexColumnWidth(1.5), 3: pw.FlexColumnWidth(1) },
    );
  }

  pw.Widget _labelCell(String text) => pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
    );

  pw.Widget _valueCell(String text) => pw.Container(
      width: 60,
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  
  pw.Widget _bigValueCell(String text) => pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      constraints: const pw.BoxConstraints(minHeight: 17),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
    );
}