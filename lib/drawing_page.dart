// lib/drawing_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:collection/collection.dart';
import 'dart:typed_data';

import 'models.dart';
import 'drawing_canvas.dart';

class DrawingPage extends StatefulWidget {
  // 👈 【変更】initialDataではなくinitialImageを受け取る
  final Uint8List? initialImage;
  final String backgroundImage;

  const DrawingPage({
    super.key,
    this.initialImage,
    required this.backgroundImage,
  });

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  // 👈 【変更】初期画像から描画要素を復元するロジックは削除
  late final ValueNotifier<List<DrawingElement>> _elementsNotifier;
  late final ValueNotifier<DrawingElement?> _previewElementNotifier;

  DrawingTool _selectedTool = DrawingTool.pen;
  final GlobalKey _canvasKey = GlobalKey();

  DrawingElement? _movingElement;
  Offset _panStartOffset = Offset.zero;

  // ▼▼▼ 【修正】四角形と四角形バツのサイズを分離 ▼▼▼
  static const double _rectangleWidth = 56.0;
  static const double _rectangleHeight = 20.0;
  static const double _crossedRectangleWidth = 56.0;
  static const double _crossedRectangleHeight = 56.0;

  Rect? _imageBounds;
  late Image _backgroundImage;
  double _imageAspectRatio = 4 / 3;

  @override
  void initState() {
    super.initState();
    // 👈 【変更】initialImageがnullでない場合は表示用の_elementsNotifierを空に
    final initialElements = (widget.initialImage == null && widget.initialData != null)
            ? widget.initialData!.elements.map((json) => DrawingElement.fromJson(json)).toList()
            : [];
    _elementsNotifier = ValueNotifier(initialElements.map((e) => e.clone()).toList());
    _previewElementNotifier = ValueNotifier(null);

    _backgroundImage = Image.asset(widget.backgroundImage);
    _resolveImageAspectRatio();
  }

  @override
  void dispose() {
    _elementsNotifier.dispose();
    _previewElementNotifier.dispose();
    super.dispose();
  }

  void _resolveImageAspectRatio() {
    final imageProvider = _backgroundImage.image;
    final stream = imageProvider.resolve(const ImageConfiguration());
    stream.addListener(ImageStreamListener((info, _) {
      if (mounted) {
        setState(() {
          _imageAspectRatio = info.image.width / info.image.height;
        });
      }
    }));
  }

  Offset _clampPosition(Offset position) {
    if (_imageBounds == null) return position;
    return Offset(
      position.dx.clamp(_imageBounds!.left, _imageBounds!.right),
      position.dy.clamp(_imageBounds!.top, _imageBounds!.bottom),
    );
  }

  void _onPanDown(DragDownDetails details) {
    if (_imageBounds == null || !_imageBounds!.contains(details.localPosition)) {
      return;
    }
    final pos = _clampPosition(details.localPosition);

    final currentElements = List<DrawingElement>.from(_elementsNotifier.value);
    switch (_selectedTool) {
      case DrawingTool.pen:
      case DrawingTool.eraser:
        currentElements.add(DrawingPath(
            id: DateTime.now().millisecondsSinceEpoch,
            points: [pos, pos],
            paint: _createPaintForTool()));
        break;
      case DrawingTool.line:
        currentElements.add(StraightLine(
            id: DateTime.now().millisecondsSinceEpoch,
            start: pos,
            end: pos,
            paint: _createPaintForTool()));
        break;
      case DrawingTool.dimension:
        currentElements.add(DimensionLine(
            id: DateTime.now().millisecondsSinceEpoch,
            start: pos,
            end: pos,
            paint: _createPaintForTool()));
        break;
      case DrawingTool.rectangle:
        _previewElementNotifier.value = Rectangle(
          id: 0,
          start: Offset(pos.dx - _rectangleWidth, pos.dy),
          end: Offset(pos.dx, pos.dy + _rectangleHeight),
          paint: Paint()
            ..color = Colors.blue.withOpacity(0.5)
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
        return;
      case DrawingTool.crossedRectangle:
        _previewElementNotifier.value = CrossedRectangle(
          id: 0,
          start: Offset(pos.dx - _crossedRectangleWidth, pos.dy),
          end: Offset(pos.dx, pos.dy + _crossedRectangleHeight),
          paint: Paint()
            ..color = Colors.blue.withOpacity(0.5)
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
        return;
      case DrawingTool.text:
        return;
    }
    _elementsNotifier.value = currentElements;
  }

  void _onPanStart(DragStartDetails details) {
    if (_selectedTool != DrawingTool.text) {
      return;
    }
    if (_imageBounds == null || !_imageBounds!.contains(details.localPosition)) {
      return;
    }

    final pos = _clampPosition(details.localPosition);

    final hittableElement = _elementsNotifier.value
        .lastWhereOrNull((e) => e is DrawingText && e.contains(pos));

    if (hittableElement != null) {
      _movingElement = hittableElement;
      _panStartOffset = pos - (hittableElement as DrawingText).position;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_imageBounds == null ||
        !_imageBounds!.contains(details.localPosition)) {
      return;
    }
    final pos = _clampPosition(details.localPosition);

    if (_movingElement != null && _movingElement is DrawingText) {
      final newPosition = pos - _panStartOffset;
      (_movingElement as DrawingText).position = newPosition;
      _elementsNotifier.value = List.from(_elementsNotifier.value);
      return;
    }

    if (_selectedTool == DrawingTool.text) {
      return;
    }

    if (_selectedTool == DrawingTool.rectangle) {
      final currentPreview = _previewElementNotifier.value;
      if (currentPreview is Rectangle) {
        currentPreview.start = Offset(pos.dx - _rectangleWidth, pos.dy);
        currentPreview.end = Offset(pos.dx, pos.dy + _rectangleHeight);
        _previewElementNotifier.value = currentPreview.clone();
      }
      return;
    }
    
    if (_selectedTool == DrawingTool.crossedRectangle) {
      final currentPreview = _previewElementNotifier.value;
      if (currentPreview is CrossedRectangle) {
        currentPreview.start = Offset(pos.dx - _crossedRectangleWidth, pos.dy);
        currentPreview.end = Offset(pos.dx, pos.dy + _crossedRectangleHeight);
        _previewElementNotifier.value = currentPreview.clone();
      }
      return;
    }

    final currentElements = _elementsNotifier.value;
    if (currentElements.isNotEmpty &&
        currentElements.last is DrawingElementWithPoints) {
      final currentElement = currentElements.last as DrawingElementWithPoints;
      if (currentElement.updatePosition(pos)) {
        _elementsNotifier.value = List<DrawingElement>.from(currentElements);
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_movingElement != null) {
      _movingElement = null;
      _panStartOffset = Offset.zero;
      return;
    }

    if (_selectedTool == DrawingTool.rectangle) {
      final currentPreview = _previewElementNotifier.value;
      if (currentPreview is Rectangle) {
        final finalRect = Rectangle(
          id: DateTime.now().millisecondsSinceEpoch,
          start: currentPreview.start,
          end: currentPreview.end,
          paint: _createPaintForTool(),
        );
        _elementsNotifier.value = [..._elementsNotifier.value, finalRect];
        _previewElementNotifier.value = null;
      }
      return;
    }

    if (_selectedTool == DrawingTool.crossedRectangle) {
      final currentPreview = _previewElementNotifier.value;
      if (currentPreview is CrossedRectangle) {
        final finalRect = CrossedRectangle(
          id: DateTime.now().millisecondsSinceEpoch,
          start: currentPreview.start,
          end: currentPreview.end,
          paint: _createPaintForTool(),
        );
        _elementsNotifier.value = [..._elementsNotifier.value, finalRect];
        _previewElementNotifier.value = null;
      }
      return;
    }
  }

  void _onTapCanvas(TapUpDetails details) {
    if (_imageBounds == null || !_imageBounds!.contains(details.localPosition)) {
      return;
    }

    final tappedPoint = _clampPosition(details.localPosition);

    if (_selectedTool == DrawingTool.rectangle || _selectedTool == DrawingTool.crossedRectangle) return;

    if (_selectedTool == DrawingTool.text) {
      _addNewText(tappedPoint);
    }
  }

  Paint _createPaintForTool() {
    switch (_selectedTool) {
      case DrawingTool.pen:
        return Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = ui.StrokeCap.round;
      case DrawingTool.eraser:
        return Paint()
          ..color = Colors.transparent
          ..strokeWidth = 12.0
          ..blendMode = BlendMode.clear
          ..style = PaintingStyle.stroke
          ..strokeCap = ui.StrokeCap.round;
      case DrawingTool.line:
        return Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0;
      case DrawingTool.rectangle:
      case DrawingTool.crossedRectangle:
        return Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
      case DrawingTool.dimension:
        return Paint()
          ..color = Colors.black
          ..strokeWidth = 1.5;
      case DrawingTool.text:
        return Paint()..color = Colors.black;
    }
  }

  void _addNewText(Offset position) {
    final textController = TextEditingController();
    showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text('テキストを追加'),
              content: TextField(
                  controller: textController,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: '注釈や数値を入力...')),
              actions: [
                TextButton(
                    child: const Text('キャンセル'),
                    onPressed: () => Navigator.of(context).pop()),
                TextButton(
                    child: const Text('OK'),
                    onPressed: () =>
                        Navigator.of(context).pop(textController.text)),
              ],
            )).then((result) {
      if (result != null && result.isNotEmpty) {
        final newText = DrawingText(
            id: DateTime.now().millisecondsSinceEpoch,
            text: result,
            position: position,
            paint: _createPaintForTool());
        _elementsNotifier.value = [..._elementsNotifier.value, newText];
      }
    });
  }

  // 👈 【修正】_saveDrawing メソッドを更新して画像をキャプチャ
  Future<void> _saveDrawing() async {
    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      if (mounted) {
        Navigator.of(context).pop(null);
      }
      return;
    }
    
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final uint8List = byteData!.buffer.asUint8List();

    if (mounted) {
      Navigator.of(context).pop(uint8List);
    }
  }


  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
        if(didPop) return;
        Navigator.of(context).pop(null);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('図面描画'),
          actions: [
            IconButton(
                icon: const Icon(Icons.undo),
                onPressed: () {
                  if (_elementsNotifier.value.isNotEmpty) {
                    final currentElements =
                        List<DrawingElement>.from(_elementsNotifier.value);
                    currentElements.removeLast();
                    _elementsNotifier.value = currentElements;
                  }
                }),
            IconButton(icon: const Icon(Icons.save), onPressed: _saveDrawing),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60.0),
            child: Container(
              color: Colors.grey[200],
              // ▼▼▼ 【修正】ツールボタンを均等割り付けに変更 ▼▼▼
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildToolButton(DrawingTool.pen, Icons.edit, '自由線'),
                  _buildToolButton(DrawingTool.line, Icons.show_chart, '直線'),
                  _buildToolButton(DrawingTool.rectangle, Icons.crop_square, '四角'),
                  _buildToolButton(DrawingTool.crossedRectangle, Icons.close, '四角バツ'),
                  _buildToolButton(DrawingTool.dimension, Icons.straighten, '寸法線'),
                  _buildToolButton(DrawingTool.text, Icons.text_fields, 'テキスト'),
                  _buildToolButton(
                      DrawingTool.eraser, Icons.cleaning_services, '消しゴム'),
                ],
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final layoutAspectRatio =
                  constraints.maxWidth / constraints.maxHeight;
              double imageWidth;
              double imageHeight;
              if (layoutAspectRatio > _imageAspectRatio) {
                imageHeight = constraints.maxHeight;
                imageWidth = imageHeight * _imageAspectRatio;
              } else {
                imageWidth = constraints.maxWidth;
                imageHeight = imageWidth / _imageAspectRatio;
              }
              final offsetX = (constraints.maxWidth - imageWidth) / 2;
              const offsetY = 0.0;
              _imageBounds =
                  Rect.fromLTWH(offsetX, offsetY, imageWidth, imageHeight);

              return RepaintBoundary(
                key: _canvasKey,
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    Positioned.fromRect(
                      rect: _imageBounds!,
                      // 👈 【変更】initialImageがあればそれを表示
                      child: widget.initialImage != null
                          ? Image.memory(widget.initialImage!, fit: BoxFit.contain)
                          : _backgroundImage,
                    ),
                    DrawingCanvas(
                      elementsNotifier: _elementsNotifier,
                      previewElementNotifier: _previewElementNotifier,
                      selectedTool: _selectedTool,
                      onPanDown: _onPanDown,
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      onTap: _onTapCanvas,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton(DrawingTool tool, IconData icon, String label) {
    final isSelected = _selectedTool == tool;
    // ▼▼▼ 【修正】Expandedでラップして均等割りを実現 ▼▼▼
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedTool = tool;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          color:
              isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.blue : Colors.grey[700]),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                    color: isSelected ? Colors.blue : Colors.grey[700],
                    fontSize: 10),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}