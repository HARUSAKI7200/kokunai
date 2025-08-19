import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:collection/collection.dart';

import 'models.dart';
import 'drawing_canvas.dart';

class DrawingPage extends StatefulWidget {
  final DrawingData? initialData;
  final String backgroundImage;

  const DrawingPage({
    super.key,
    this.initialData,
    required this.backgroundImage,
  });

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  late final ValueNotifier<List<DrawingElement>> _elementsNotifier;
  late final ValueNotifier<DrawingElement?> _previewElementNotifier;

  DrawingTool _selectedTool = DrawingTool.pen;
  final GlobalKey _canvasKey = GlobalKey();

  DrawingElement? _movingElement;
  Offset _panStartOffset = Offset.zero;

  static const double _rectangleWidth = 30.0;
  static const double _rectangleHeight = 30.0;

  Rect? _imageBounds;
  late Image _backgroundImage;
  double _imageAspectRatio = 4 / 3;

  @override
  void initState() {
    super.initState();
    final initialElements = widget.initialData?.elements
            .map((json) => DrawingElement.fromJson(json))
            .toList() ??
        [];
    _elementsNotifier =
        ValueNotifier(initialElements.map((e) => e.clone()).toList());
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
  }

  void _onTapCanvas(TapUpDetails details) {
    if (_imageBounds == null || !_imageBounds!.contains(details.localPosition)) {
      return;
    }

    final tappedPoint = _clampPosition(details.localPosition);

    if (_selectedTool == DrawingTool.rectangle) return;

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

  void _saveDrawing() {
    final elementsAsJson =
        _elementsNotifier.value.map((e) => e.toJson()).toList();
    final drawingData =
        DrawingData(elementsAsJson, imageKey: widget.backgroundImage);
    Navigator.of(context).pop(drawingData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildToolButton(DrawingTool.pen, Icons.edit, '自由線'),
                _buildToolButton(DrawingTool.line, Icons.show_chart, '直線'),
                _buildToolButton(DrawingTool.rectangle, Icons.crop_square, '四角'),
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
                    child: _backgroundImage,
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
    );
  }

  Widget _buildToolButton(DrawingTool tool, IconData icon, String label) {
    final isSelected = _selectedTool == tool;
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