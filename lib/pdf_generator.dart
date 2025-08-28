// lib/pdf_generator.dart
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pw;
import 'models.dart';
// 描画モデルクラスをインポート
import 'drawing_canvas.dart' as dc;

class PdfGenerator {
  Future<List<int>> buildPdf(List<FormRecord> records) async {
    final doc = pw.Document();

    // フォントデータを読み込む
    final fontData =
        await rootBundle.load("assets/fonts/NotoSansJP-Regular.ttf");
    final ttf = pw.Font.ttf(fontData);

    // 背景画像を事前に読み込む
    final yokoshitaImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/国内工注票腰下図面.jpg'))
          .buffer
          .asUint8List(),
    );
    final hiraichiImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/国内工注票平打ち.jpg'))
          .buffer
          .asUint8List(),
    );
    final subzaiImage = pw.MemoryImage(
      (await rootBundle.load('assets/images/国内工注票滑材.jpg'))
          .buffer
          .asUint8List(),
    );

    final theme = pw.ThemeData.withFont(base: ttf, bold: ttf);

    for (final record in records) {
      doc.addPage(
        pw.Page(
          theme: theme,
          pageFormat: pdf.PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(28),
          build: (ctx) {
            // 読み込んだ画像をビルドメソッドに渡す
            return _buildPageContent(ctx, record, ttf,
                yokoshitaImage, hiraichiImage, subzaiImage);
          },
        ),
      );
    }
    return await doc.save();
  }

  // 引数に各画像オブジェクトを追加
  pw.Widget _buildPageContent(
      pw.Context ctx,
      FormRecord r,
      pw.Font font,
      pw.MemoryImage yokoshitaImage,
      pw.MemoryImage hiraichiImage,
      pw.MemoryImage subzaiImage) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _buildHeader(r),
        pw.SizedBox(height: 12),
        // 描画メソッドに画像オブジェクトを渡す
        _buildDrawings(ctx, r, font, yokoshitaImage, hiraichiImage, subzaiImage),
        pw.SizedBox(height: 12),
        // 部材情報と備考欄を左右に分割するレイアウトに変更
        pw.Expanded(
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 左側：部材情報
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text('部材情報',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    _buildComponentsTable(r),
                  ],
                ),
              ),
              pw.SizedBox(width: 12),
              // 右側：備考欄
              pw.Expanded(
                flex: 1,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text('備考',
                        style: pw.TextStyle(
                            fontSize: 12, fontWeight: pw.FontWeight.bold)),
                    pw.SizedBox(height: 4),
                    pw.Expanded(
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(
                              color: pdf.PdfColors.grey, width: 0.5),
                        ),
                        child: pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(r.remarks ?? ''),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildHeader(FormRecord r) {
    final shipDateFormat = DateFormat('MM/dd');
    final insideDim = [r.insideLength, r.insideWidth, r.insideHeight]
        .where((s) => s != null && s.isNotEmpty)
        .join(' x ');
    final outsideDim = [r.outsideLength, r.outsideWidth, r.outsideHeight]
        .where((s) => s != null && s.isNotEmpty)
        .join(' x ');
    
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.SizedBox(
            height: 40,
            child: pw.Stack(alignment: pw.Alignment.center, children: [
              pw.Text('工　注　票',
                  style: pw.TextStyle(
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                      decoration: pw.TextDecoration.underline)),
              pw.Positioned(
                left: 0,
                top: 0,
                child: pw.Table(
                    border: pw.TableBorder.all(width: 0.6),
                    columnWidths: const {
                      0: pw.IntrinsicColumnWidth(),
                      1: pw.IntrinsicColumnWidth(),
                      2: pw.IntrinsicColumnWidth(),
                    },
                    children: [
                      pw.TableRow(children: [
                        _labelCell('出荷日'),
                        _labelCell('作業場所'),
                        _labelCell('指示者')
                      ]),
                      pw.TableRow(children: [
                        _valueCell(shipDateFormat.format(r.shipDate)),
                        _valueCell(r.workPlace),
                        _valueCell(r.instructor)
                      ])
                    ]),
              ),
            ]),
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
                pw.TableRow(children: [
                  _labelCell('製番'), _valueCell(r.productNo),
                  _labelCell('品名'), _valueCell(r.productName),
                  _labelCell('荷姿'), _valueCell(packageStyleLabel(r.packageStyle)),
                  _labelCell('材質'), _valueCell(productMaterialTypeLabel(r.materialType)),
                ]),
              ]),
          pw.Table(
            border: pw.TableBorder.all(width: 0.6),
            defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
            columnWidths: const {
              0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth(2.5),
              2: pw.IntrinsicColumnWidth(), 3: pw.FlexColumnWidth(2.5),
              4: pw.IntrinsicColumnWidth(), 5: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(children: [
                _labelCell('内寸'), _bigValueCell(insideDim),
                _labelCell('外寸'), _bigValueCell(outsideDim),
                _labelCell('数量'), _valueCell(r.quantity != null ? '${r.quantity} C/S' : ''),
              ])
            ]
          ),
          pw.Table(
              border: pw.TableBorder.all(width: 0.6),
              defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
              columnWidths: const {
                0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth(1),
                2: pw.IntrinsicColumnWidth(), 3: pw.FlexColumnWidth(1)
              },
              children: [
                pw.TableRow(children: [
                  _labelCell('重量(net)'),
                  _valueCell(r.weightKg != null ? '${r.weightKg} kg' : ''),
                  _labelCell('重量(gross)'),
                  _valueCell(r.weightGrossKg != null ? '${r.weightGrossKg} kg' : ''),
                ])
              ]),
        ]);
  }

  pw.Widget _buildDrawings(
      pw.Context ctx,
      FormRecord r,
      pw.Font font,
      pw.MemoryImage yokoshitaImage,
      pw.MemoryImage hiraichiImage,
      pw.MemoryImage subzaiImage) {
    pw.Widget drawingBox(
        String title, DrawingData? drawingData, pw.MemoryImage image) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(title,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 2),
          pw.Expanded(
            child: pw.Container(
              width: double.infinity,
              decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: pdf.PdfColors.grey, width: 0.5)),
              child: pw.CustomPaint(
                child: pw.Image(image, fit: pw.BoxFit.contain),
                painter: (canvas, size) {
                  if (drawingData != null && drawingData.elements.isNotEmpty) {
                    final pdfFont =
                        (font as pw.TtfFont).buildFont(ctx.document);
                    _drawVectorGraphics(canvas, size, drawingData, pdfFont);
                  }
                },
              ),
            ),
          ),
        ],
      );
    }

    return pw.SizedBox(
      height: 280,
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Expanded(
              flex: 2, child: drawingBox('腰下', r.yokoshitaDrawing, yokoshitaImage)),
          pw.SizedBox(width: 8),
          pw.Expanded(
            flex: 2,
            child: pw.Column(children: [
              pw.Expanded(
                  flex: 3,
                  child: drawingBox('側ツマ', r.hiraichiDrawing, hiraichiImage)),
              pw.SizedBox(height: 8),
              pw.Expanded(
                  flex: 2,
                  child: drawingBox('滑材', r.subzaiDrawing, subzaiImage)),
            ]),
          ),
        ],
      ),
    );
  }

  void _drawVectorGraphics(pdf.PdfGraphics canvas, pdf.PdfPoint size,
      DrawingData data, pdf.PdfFont font) {
    final elements =
        data.elements.map((e) => dc.DrawingElement.fromJson(e)).toList();
    final sourceSize = (data.sourceWidth != null && data.sourceHeight != null)
        ? pdf.PdfPoint(data.sourceWidth!, data.sourceHeight!)
        : const pdf.PdfPoint(1, 1);

    final double scaleX = size.x / sourceSize.x;
    final double scaleY = size.y / sourceSize.y;
    final double scale = math.min(scaleX, scaleY);
    final double offsetX = (size.x - sourceSize.x * scale) / 2;
    final double offsetY = (size.y - sourceSize.y * scale) / 2;

    pdf.PdfPoint transform(double x, double y) {
      final newX = x * scale + offsetX;
      final newY = size.y - (y * scale + offsetY);
      return pdf.PdfPoint(newX, newY);
    }

    for (final element in elements) {
      final color = pdf.PdfColor.fromInt(element.paint.color.value);
      canvas
        ..saveContext()
        ..setColor(color)
        ..setLineWidth(element.paint.strokeWidth * scale);

      if (element is dc.DrawingPath) {
        if (element.points.isNotEmpty) {
          final firstPoint =
              transform(element.points.first.dx, element.points.first.dy);
          canvas.moveTo(firstPoint.x, firstPoint.y);
          for (var i = 1; i < element.points.length; i++) {
            final p = transform(element.points[i].dx, element.points[i].dy);
            canvas.lineTo(p.x, p.y);
          }
          canvas.strokePath();
        }
      } else if (element is dc.StraightLine) {
        final p1 = transform(element.start.dx, element.start.dy);
        final p2 = transform(element.end.dx, element.end.dy);
        canvas
          ..moveTo(p1.x, p1.y)
          ..lineTo(p2.x, p2.y)
          ..strokePath();
      } else if (element is dc.Rectangle) {
        final p1 = transform(element.rect.left, element.rect.top);
        final p2 = transform(element.rect.right, element.rect.bottom);
        final rect = pdf.PdfRect.fromPoints(p1, p2);
        canvas
          ..drawRect(rect.x, rect.y, rect.width, rect.height)
          ..strokePath();
      // ▼▼▼ 【修正】CrossedRectangleの描画処理を修正 ▼▼▼
      } else if (element is dc.CrossedRectangle) {
        final topLeft = transform(element.rect.topLeft.dx, element.rect.topLeft.dy);
        final topRight = transform(element.rect.topRight.dx, element.rect.topRight.dy);
        final bottomLeft = transform(element.rect.bottomLeft.dx, element.rect.bottomLeft.dy);
        final bottomRight = transform(element.rect.bottomRight.dx, element.rect.bottomRight.dy);

        canvas
          ..moveTo(topLeft.x, topLeft.y)
          ..lineTo(topRight.x, topRight.y)
          ..lineTo(bottomRight.x, bottomRight.y)
          ..lineTo(bottomLeft.x, bottomLeft.y)
          ..closePath() // 四角形を閉じる
          ..moveTo(topLeft.x, topLeft.y)
          ..lineTo(bottomRight.x, bottomRight.y)
          ..moveTo(topRight.x, topRight.y)
          ..lineTo(bottomLeft.x, bottomLeft.y)
          ..strokePath();
      } else if (element is dc.DimensionLine) {
        final p1 = transform(element.start.dx, element.start.dy);
        final p2 = transform(element.end.dx, element.end.dy);
        canvas
          ..moveTo(p1.x, p1.y)
          ..lineTo(p2.x, p2.y)
          ..strokePath();
        _drawPdfArrow(canvas, p2, p1);
        _drawPdfArrow(canvas, p1, p2);
      } else if (element is dc.DrawingText) {
        final p = transform(element.position.dx, element.position.dy);
        final scaledFontSize = 16 * scale;
        canvas.drawString(
          font,
          scaledFontSize,
          element.text,
          p.x,
          p.y - scaledFontSize,
        );
      }
      canvas.restoreContext();
    }
  }

  void _drawPdfArrow(pdf.PdfGraphics canvas, pdf.PdfPoint p1, pdf.PdfPoint p2) {
    const arrowSize = 8.0;
    final angle = math.atan2(p1.y - p2.y, p1.x - p2.x);
    canvas
      ..moveTo(p1.x - arrowSize * math.cos(angle - math.pi / 6),
          p1.y - arrowSize * math.sin(angle - math.pi / 6))
      ..lineTo(p1.x, p1.y)
      ..lineTo(p1.x - arrowSize * math.cos(angle + math.pi / 6),
          p1.y - arrowSize * math.sin(angle + math.pi / 6))
      ..strokePath();
  }

  pw.Widget _buildComponentsTable(FormRecord r) {
    const headerStyle =
        pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold);
    const cellStyle = pw.TextStyle(fontSize: 9);

    final insideL = double.tryParse(r.insideLength ?? '');
    final insideW = double.tryParse(r.insideWidth ?? '');

    String getCalculatedLength(String partName, ComponentSpec spec) {
      if (spec.lengthMm != null) return spec.lengthMm!.toInt().toString();

      double? calculatedValue;

      switch (r.packageStyle) {
        case PackageStyle.sukashi:
        case PackageStyle.mekura:
          if (r.materialType == ProductMaterialType.domestic) {
            if (partName == '滑材' && insideL != null) calculatedValue = insideL + 30;
            if (partName == 'ゲタ' && insideL != null) calculatedValue = insideL + 60;
            if (['H', '負荷材1', '負荷材2', '押さえ', '梁'].contains(partName)) return r.insideLength ?? '-';
          } else {
            if (partName == '滑材' && insideL != null) calculatedValue = insideL + 50;
            if (partName == 'ゲタ' && insideL != null) calculatedValue = insideL + 100;
            if (['H', '負荷材1', '負荷材2', '押さえ', '梁'].contains(partName)) return r.insideWidth ?? '-';
          }
          break;
        case PackageStyle.yokoshita:
          if (partName == '滑材') return r.insideLength ?? '-';
          if (['ゲタ', 'H', '負荷材1', '負荷材2'].contains(partName)) return r.insideWidth ?? '-';
          break;
        default:
          break;
      }

      if (calculatedValue != null) {
        return calculatedValue.toInt().toString();
      }
      return '-';
    }

    final List<List<String>> tableData = [];
    final components = {
      '滑材': r.subzai,
      'ゲタ': r.getaOrSuriSpec,
      'H': r.h,
      '負荷材1': r.fukazai1,
      '負荷材2': r.fukazai2,
      '根止め1': r.nedome1,
      '根止め2': r.nedome2,
      '根止め3': r.nedome3,
      '根止め4': r.nedome4,
      '押さえ': r.osae,
      '梁': r.ryo,
      '他1': r.other1,
      '他2': r.other2,
    };

    components.forEach((name, spec) {
      if ((spec.count != null && spec.count! > 0) ||
          (spec.partName != null && spec.partName!.isNotEmpty)) {
        
        String displayName = (spec.partName?.isNotEmpty == true) ? spec.partName! : name;
        if (name == 'ゲタ') {
          displayName = getaOrSuriTypeLabel(r.getaOrSuri);
        }
        
        tableData.add([
          displayName,
          spec.yobisun != null ? yobisunLabel(spec.yobisun!) : '-',
          getCalculatedLength(name, spec),
          spec.count?.toString() ?? '-',
        ]);
      }
    });

    if (tableData.isEmpty) return pw.Container();

    return pw.Table.fromTextArray(
      headers: ['部材名', '呼び寸', '長さ (mm)', '本数'],
      data: tableData,
      headerStyle: headerStyle,
      cellStyle: cellStyle,
      headerDecoration: const pw.BoxDecoration(color: pdf.PdfColors.grey300),
      cellAlignment: pw.Alignment.center,
      cellAlignments: {0: pw.Alignment.centerLeft},
      border: pw.TableBorder.all(width: 0.5, color: pdf.PdfColors.black),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.5),
        1: pw.FlexColumnWidth(1.5),
        2: pw.FlexColumnWidth(1.5),
        3: pw.FlexColumnWidth(1)
      },
    );
  }

  pw.Widget _labelCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
      );

  pw.Widget _valueCell(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      );
  
  pw.Widget _bigValueCell(String text) => pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        constraints: const pw.BoxConstraints(minHeight: 17),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 12)),
      );
}