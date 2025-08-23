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
    final theme = pw.ThemeData.withFont(base: font, bold: boldFont);

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

  // --- ヘルパー関数群 ---

  // 部材情報のテキストを生成
  String _specText(ComponentSpec c, {bool showLength = false, String name = ''}) {
    final yobisun = c.yobisun != null ? yobisunLabel(c.yobisun!) : null;
    final length = (showLength && c.lengthMm != null) ? '${c.lengthMm}mm' : null;
    final count = c.count != null ? '${c.count}本' : null;
    
    final parts = [name, yobisun, length, count].where((s) => s != null && s.isNotEmpty).toList();
    if (parts.isEmpty) return '';
    return parts.join(' ');
  }

  // 「他」部材のテキストを生成
  String _otherSpecText(ComponentSpec c) {
    return _specText(c, showLength: true, name: c.partName ?? '');
  }

  // pw.Table用のテキストセル
  pw.Widget _tableCell(String text, {pw.TextStyle? style, pw.Alignment align = pw.Alignment.center}) {
    return pw.Container(
      alignment: align,
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(text, style: style),
    );
  }

  // セクションヘッダー
  pw.Widget _sectionHeader(String title, {pw.EdgeInsets padding = const pw.EdgeInsets.only(top: 4, bottom: 2)}) {
    return pw.Padding(
      padding: padding,
      child: pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
    );
  }

  // 情報表示用の小さなWidget
  pw.Widget _infoItem(String label, String value, {pw.TextStyle? style}) {
    if (value.isEmpty) return pw.SizedBox.shrink();
    return pw.RichText(
      text: pw.TextSpan(
        style: style ?? const pw.TextStyle(fontSize: 8.5),
        children: [
          pw.TextSpan(text: '$label: ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: value),
        ],
      ),
    );
  }

  // 図面表示Widget
  pw.Widget _drawingBox(DrawingData? drawing, String imagePath, String title, double height, pw.Context context) {
    pw.Widget imageWidget;
    if (drawing?.previewBytes != null) {
      imageWidget = pw.Image(pw.MemoryImage(drawing!.previewBytes!), fit: pw.BoxFit.contain);
    } else {
      // フォールバックとしてアセット画像を表示 (PDF内では直接アセットは読めないので注意)
      // ここではプレースホルダーとしての役割
      imageWidget = pw.Center(child: pw.Text(title, style: const pw.TextStyle(color: PdfColors.grey, fontSize: 10)));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionHeader(title, padding: const pw.EdgeInsets.only(bottom: 2)),
        pw.Container(
          height: height,
          width: double.infinity,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey600, width: 0.5)),
          child: imageWidget,
        ),
      ],
    );
  }


  // --- A5フォーム本体 ---
  pw.Widget _a5Form(FormRecord r, pw.Context ctx, {required double height}) {
    final df = DateFormat('yyyy/MM/dd');
    final smallStyle = const pw.TextStyle(fontSize: 8.5);
    final boldStyle = pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8.5);
    
    final nedome1 = _specText(r.nedome1, showLength: true);
    final nedome2 = _specText(r.nedome2, showLength: true);
    final nedome3 = _specText(r.nedome3, showLength: true);
    final nedome4 = _specText(r.nedome4, showLength: true);
    final nedomeText = [nedome1, nedome2, nedome3, nedome4].where((s) => s.isNotEmpty).join('\n');

    return pw.Container(
      height: height,
      decoration: pw.BoxDecoration(border: pw.Border.all(width: 0.8)),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          // 1. ヘッダー
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                   _infoItem('出荷日', df.format(r.shipDate), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                   _infoItem('作業場所', r.workPlace),
                   _infoItem('指示者', r.instructor),
                ]
              ),
              pw.Text('工 注 票', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _infoItem('製番', r.productNo),
                  _infoItem('伝票No', r.slipNo),
                ]
              )
            ]
          ),
          pw.Divider(thickness: 1, height: 8),

          // 2. 品名・重量・荷姿
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(flex: 5, child: _infoItem('品名', r.productName)),
              pw.Expanded(flex: 2, child: _infoItem('重量', r.weightKg != null ? '${r.weightKg} kg' : '')),
              pw.Expanded(flex: 2, child: _infoItem('荷姿', packageStyleLabel(r.packageStyle))),
            ]
          ),
          pw.SizedBox(height: 4),

          // 3. 本体
          pw.Expanded(
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // 3.1. 左列
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      _sectionHeader('寸法 (mm)'),
                      pw.Table(
                        border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
                        columnWidths: const { 0: pw.IntrinsicColumnWidth(), 1: pw.FlexColumnWidth(), 2: pw.FlexColumnWidth(), 3: pw.FlexColumnWidth()},
                        children: [
                          pw.TableRow(children: [
                            _tableCell('', align: pw.Alignment.centerLeft),
                            _tableCell('長', style: smallStyle),
                            _tableCell('幅', style: smallStyle),
                            _tableCell('高', style: smallStyle),
                          ]),
                          pw.TableRow(children: [
                            _tableCell('内寸', style: boldStyle, align: pw.Alignment.centerLeft),
                            _tableCell(r.insideLength ?? '', style: smallStyle),
                            _tableCell(r.insideWidth ?? '', style: smallStyle),
                            _tableCell(r.insideHeight ?? '', style: smallStyle),
                          ]),
                           pw.TableRow(children: [
                            _tableCell('外寸', style: boldStyle, align: pw.Alignment.centerLeft),
                            _tableCell(r.outsideLength ?? '', style: smallStyle),
                            _tableCell(r.outsideWidth ?? '', style: smallStyle),
                            _tableCell(r.outsideHeight ?? '', style: smallStyle),
                          ]),
                        ]
                      ),
                      pw.SizedBox(height: 4),
                      _infoItem('材質', productMaterialTypeLabel(r.materialType)),
                      _infoItem('床板', floorPlateTypeLabel(r.floorPlate)),
                      pw.Expanded(child: _drawingBox(r.yokoshitaDrawing, 'assets/images/国内工注票腰下図面.jpg', '腰下図面', 50, ctx)),
                    ]
                  )
                ),
                pw.SizedBox(width: 8),

                // 3.2. 右列
                pw.Expanded(
                  child: pw.Column(
                     crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                     children: [
                        _sectionHeader('部材情報'),
                        pw.Table(
                           border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
                           children: [
                              pw.TableRow(children: [
                                _tableCell('滑材', style: boldStyle),
                                _tableCell(_specText(r.subzai), style: smallStyle),
                              ]),
                              pw.TableRow(children: [
                                _tableCell(getaOrSuriTypeLabel(r.getaOrSuri), style: boldStyle),
                                _tableCell(_specText(r.getaOrSuriSpec), style: smallStyle),
                              ]),
                               pw.TableRow(children: [
                                _tableCell('H', style: boldStyle),
                                _tableCell(_specText(r.h), style: smallStyle),
                              ]),
                              pw.TableRow(children: [
                                _tableCell('梁', style: boldStyle),
                                _tableCell(_specText(r.ryo), style: smallStyle),
                              ]),
                               pw.TableRow(children: [
                                _tableCell('押さえ', style: boldStyle),
                                _tableCell(_specText(r.osae), style: smallStyle),
                              ]),
                               pw.TableRow(children: [
                                _tableCell('根止め', style: boldStyle),
                                _tableCell(nedomeText, style: smallStyle, align: pw.Alignment.centerLeft),
                              ]),
                           ]
                        ),
                        pw.SizedBox(height: 4),
                        _sectionHeader('その他'),
                         pw.Table(
                           border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
                           children: [
                              pw.TableRow(children: [
                                _tableCell('負荷材1', style: boldStyle),
                                _tableCell(_specText(r.fukazai1), style: smallStyle),
                              ]),
                              pw.TableRow(children: [
                                _tableCell('負荷材2', style: boldStyle),
                                _tableCell(_specText(r.fukazai2), style: smallStyle),
                              ]),
                               pw.TableRow(children: [
                                _tableCell('他1', style: boldStyle),
                                _tableCell(_otherSpecText(r.other1), style: smallStyle),
                              ]),
                               pw.TableRow(children: [
                                _tableCell('他2', style: boldStyle),
                                _tableCell(_otherSpecText(r.other2), style: smallStyle),
                              ]),
                           ]
                        ),
                        pw.Row(
                          children: [
                             pw.Expanded(child: _drawingBox(r.subzaiDrawing, 'assets/images/国内工注票滑材.jpg', '滑材', 25, ctx)),
                             pw.SizedBox(width: 4),
                             pw.Expanded(child: _drawingBox(r.hiraichiDrawing, 'assets/images/国内工注票平打ち.jpg', '側・妻', 25, ctx)),
                          ]
                        )
                     ]
                  )
                ),
              ]
            )
          )
        ],
      ),
    );
  }
}