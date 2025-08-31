// lib/drawing_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:collection/collection.dart';
import 'dart:typed_data';

import 'models.dart';
import 'drawing_canvas.dart';

class DrawingPage extends StatefulWidget {
  final Uint8List? initialImage;
  final String backgroundImage;
  final String drawingType;
  final List<double>? snapLinesY;
  final List<double>? clampXRange;

  const DrawingPage({
    super.key,
    this.initialImage,
    required this.backgroundImage,
    this.drawingType = 'default',
    this.snapLinesY,
    this.clampXRange,
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

  double _rectangleWidth = 56.0;
  double _rectangleHeight = 20.0;
  double _crossedRectangleWidth = 56.0;
  double _crossedRectangleHeight = 56.0;
  double _slashedRectangleWidth = 56.0;
  double _slashedRectangleHeight = 56.0;

  Rect? _imageBounds;
  Rect? _drawingAreaBounds;
  late Image _displayImage;
  double _imageAspectRatio = 4 / 3;

  static const double _snapThreshold = 10.0;

  @override
  void initState() {
    super.initState();
    _elementsNotifier = ValueNotifier([]);
    _previewElementNotifier = ValueNotifier(null);

    if (widget.drawingType == 'koshishita') {
      _rectangleWidth = 30.0;
      _rectangleHeight = 15.0;
      _crossedRectangleWidth = 30.0;
      _crossedRectangleHeight = 30.0;
      _slashedRectangleWidth = 30.0;
      _slashedRectangleHeight = 30.0;
    }

    _displayImage = widget.initialImage != null
        ? Image.memory(widget.initialImage!)
        : Image.asset(widget.backgroundImage);

    _resolveImageAspectRatio();
  }

  @override
  void dispose() {
    _elementsNotifier.dispose();
    _previewElementNotifier.dispose();
    super.dispose();
  }

  void _resolveImageAspectRatio() {
    final imageProvider = _displayImage.image;
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
    Rect? bounds;
    if (_isShapeToolSelected) {
      bounds = _drawingAreaBounds ?? _imageBounds;
    } else {
      bounds = _imageBounds;
    }
    
    if (bounds == null) return position;

    return Offset(
      position.dx.clamp(bounds.left, bounds.right),
      position.dy.clamp(bounds.top, bounds.bottom),
    );
  }

  // ▼▼▼ 【変更】 滑材描画画面のスナップを、四角形の上辺と下辺両対応に修正 ▼▼▼
  Offset _snapToLines(Offset originalPoint) {
    if (_imageBounds == null) {
      return originalPoint;
    }

    // --- 滑材描画画面 (default) の横線スナップ ---
    if (widget.drawingType == 'default') {
      const double imageOriginalWidth = 1500.0;
      const double imageOriginalHeight = 775.0;
      const double snapYAbsolute = 410.0;
      const double clampXStartAbsolute = 250.0;
      const double clampXEndAbsolute = 1221.0;

      final double snapYOnCanvas = _imageBounds!.top + (_imageBounds!.height * (snapYAbsolute / imageOriginalHeight));
      final double startXOnCanvas = _imageBounds!.left + (_imageBounds!.width * (clampXStartAbsolute / imageOriginalWidth));
      final double endXOnCanvas = _imageBounds!.left + (_imageBounds!.width * (clampXEndAbsolute / imageOriginalWidth));
      
      // X軸が指定範囲外ならスナップしない
      if (originalPoint.dx < startXOnCanvas || originalPoint.dx > endXOnCanvas) {
        return originalPoint;
      }

      // 四角形ツールの場合、上辺と下辺をチェック
      if (_isRectangleToolSelected) {
        final rectHeight = _getRectangleHeight(_selectedTool);
        final topY = originalPoint.dy - rectHeight;
        final bottomY = originalPoint.dy;

        final distanceToTop = (topY - snapYOnCanvas).abs();
        final distanceToBottom = (bottomY - snapYOnCanvas).abs();

        // より近い辺をスナップ対象とする
        if (distanceToTop < _snapThreshold && distanceToTop < distanceToBottom) {
          // 上辺をスナップ線に合わせる
          return Offset(originalPoint.dx, snapYOnCanvas + rectHeight);
        }
        if (distanceToBottom < _snapThreshold) {
          // 下辺をスナップ線に合わせる
          return Offset(originalPoint.dx, snapYOnCanvas);
        }
      } else { // 四角形ツール以外（直線など）は、カーソル位置のみチェック
        final distance = (originalPoint.dy - snapYOnCanvas).abs();
        if (distance < _snapThreshold) {
          return Offset(originalPoint.dx, snapYOnCanvas);
        }
      }

      return originalPoint;
    }

    // --- 腰下描画画面など、他の画面のスナップ ---
    if (widget.snapLinesY != null) {
      double bestSnapY = originalPoint.dy;
      double minDistance = double.infinity;

      for (final relativeY in widget.snapLinesY!) {
        final absoluteY = _imageBounds!.top + (_imageBounds!.height * relativeY);
        final distance = (originalPoint.dy - absoluteY).abs();

        if (distance < _snapThreshold && distance < minDistance) {
          minDistance = distance;
          bestSnapY = absoluteY;
        }
      }
      return Offset(originalPoint.dx, bestSnapY);
    }
    
    return originalPoint;
  }
  // ▲▲▲

  Offset _snapToOtherRectangles(Offset pos) {
    if (!_isRectangleToolSelected) return pos;

    final tool = _selectedTool;
    final previewWidth = _getRectangleWidth(tool);
    final previewHeight = _getRectangleHeight(tool);

    final previewRect = Rect.fromLTRB(
      pos.dx - previewWidth, 
      pos.dy - previewHeight, 
      pos.dx, 
      pos.dy
    );

    double bestSnapDx = pos.dx;
    double bestSnapDy = pos.dy;
    double minHDistance = _snapThreshold;
    double minVDistance = _snapThreshold;

    for (final element in _elementsNotifier.value) {
      Rect? existingRect;
      if (element is Rectangle) existingRect = element.rect;
      if (element is CrossedRectangle) existingRect = element.rect;
      if (element is SlashedRectangle) existingRect = element.rect;

      if (existingRect == null) continue;

      final isVerticallyOverlapping = (previewRect.top < existingRect.bottom && previewRect.bottom > existingRect.top);
      if (isVerticallyOverlapping) {
        final hCandidates = {
          existingRect.left: (previewRect.right - existingRect.left).abs(),
          existingRect.right: (previewRect.right - existingRect.right).abs(),
          existingRect.left + previewWidth: (previewRect.left - existingRect.left).abs(),
          existingRect.right + previewWidth: (previewRect.left - existingRect.right).abs()
        };

        hCandidates.forEach((candidateDx, distance) {
          if (distance < minHDistance) {
            minHDistance = distance;
            bestSnapDx = candidateDx;
          }
        });
      }

      final isHorizontallyOverlapping = (previewRect.left < existingRect.right && previewRect.right > existingRect.left);
      if (isHorizontallyOverlapping) {
        final vCandidates = {
          existingRect.top: (previewRect.bottom - existingRect.top).abs(),
          existingRect.bottom: (previewRect.bottom - existingRect.bottom).abs(),
          existingRect.top + previewHeight: (previewRect.top - existingRect.top).abs(),
          existingRect.bottom + previewHeight: (previewRect.top - existingRect.bottom).abs()
        };
        
        vCandidates.forEach((candidateDy, distance) {
          if (distance < minVDistance) {
            minVDistance = distance;
            bestSnapDy = candidateDy;
          }
        });
      }
    }

    return Offset(bestSnapDx, bestSnapDy);
  }

  bool get _isRectangleToolSelected {
    return _selectedTool == DrawingTool.rectangle ||
        _selectedTool == DrawingTool.crossedRectangle ||
        _selectedTool == DrawingTool.slashedRectangle;
  }
  
  bool get _isShapeToolSelected {
    return _isRectangleToolSelected ||
        _selectedTool == DrawingTool.line ||
        _selectedTool == DrawingTool.dimension;
  }
  
  double _getRectangleWidth(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.rectangle:
        return _rectangleWidth;
      case DrawingTool.crossedRectangle:
        return _crossedRectangleWidth;
      case DrawingTool.slashedRectangle:
        return _slashedRectangleWidth;
      default:
        return 0;
    }
  }

  double _getRectangleHeight(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.rectangle:
        return _rectangleHeight;
      case DrawingTool.crossedRectangle:
        return _crossedRectangleHeight;
      case DrawingTool.slashedRectangle:
        return _slashedRectangleHeight;
      default:
        return 0;
    }
  }

  void _onPanDown(DragDownDetails details) {
    if (_imageBounds == null || !_imageBounds!.contains(details.localPosition)) {
      return;
    }
    
    var pos = _clampPosition(details.localPosition);
    if (_isShapeToolSelected) {
      if (_isRectangleToolSelected) {
        pos = _snapToOtherRectangles(pos);
      }
      pos = _snapToLines(pos);
    }

    final currentElements = List<DrawingElement>.from(_elementsNotifier.value);
    switch (_selectedTool) {
      case DrawingTool.pen:
        currentElements.add(DrawingPath(
            id: DateTime.now().millisecondsSinceEpoch,
            points: [pos, pos],
            paint: _createPaintForTool()));
        break;
      case DrawingTool.eraser:
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
          start: Offset(pos.dx - _rectangleWidth, pos.dy - _rectangleHeight),
          end: pos,
          paint: Paint()
            ..color = Colors.blue.withOpacity(0.5)
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
        return;
      case DrawingTool.crossedRectangle:
        _previewElementNotifier.value = CrossedRectangle(
          id: 0,
          start: Offset(pos.dx - _crossedRectangleWidth, pos.dy - _crossedRectangleHeight),
          end: pos,
          paint: Paint()
            ..color = Colors.blue.withOpacity(0.5)
            ..strokeWidth = 2.0
            ..style = PaintingStyle.stroke,
        );
        return;
      case DrawingTool.slashedRectangle:
        _previewElementNotifier.value = SlashedRectangle(
          id: 0,
          start: Offset(pos.dx - _slashedRectangleWidth, pos.dy - _slashedRectangleHeight),
          end: pos,
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
    if (_imageBounds == null || !_imageBounds!.contains(details.localPosition)) {
      return;
    }

    if (_selectedTool == DrawingTool.eraser) {
      final currentElements = List<DrawingElement>.from(_elementsNotifier.value);
      final elementsToRemove = <DrawingElement>{};
      
      for (final element in currentElements) {
        if (element.contains(details.localPosition)) {
           elementsToRemove.add(element);
        }
      }

      if (elementsToRemove.isNotEmpty) {
        currentElements.removeWhere((e) => elementsToRemove.contains(e));
        _elementsNotifier.value = currentElements;
      }
      return;
    }

    if (_movingElement != null && _movingElement is DrawingText) {
      final newPosition = details.localPosition - _panStartOffset;
      (_movingElement as DrawingText).position = _clampPosition(newPosition);
      _elementsNotifier.value = List.from(_elementsNotifier.value);
      return;
    }

    var pos = _clampPosition(details.localPosition);
    if (_isShapeToolSelected) {
      if (_isRectangleToolSelected) {
        pos = _snapToOtherRectangles(pos);
      }
      pos = _snapToLines(pos);
    }

    if (_selectedTool == DrawingTool.text) {
      return;
    }
    
    if (_selectedTool == DrawingTool.rectangle) {
      final currentPreview = _previewElementNotifier.value;
      if (currentPreview is Rectangle) {
        currentPreview.start = Offset(pos.dx - _rectangleWidth, pos.dy - _rectangleHeight);
        currentPreview.end = pos;
        _previewElementNotifier.value = currentPreview.clone();
      }
      return;
    }
    
    if (_selectedTool == DrawingTool.crossedRectangle) {
      final currentPreview = _previewElementNotifier.value;
      if (currentPreview is CrossedRectangle) {
        currentPreview.start = Offset(pos.dx - _crossedRectangleWidth, pos.dy - _crossedRectangleHeight);
        currentPreview.end = pos;
        _previewElementNotifier.value = currentPreview.clone();
      }
      return;
    }

    if (_selectedTool == DrawingTool.slashedRectangle) {
      final currentPreview = _previewElementNotifier.value;
      if (currentPreview is SlashedRectangle) {
        currentPreview.start = Offset(pos.dx - _slashedRectangleWidth, pos.dy - _slashedRectangleHeight);
        currentPreview.end = pos;
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
    if (_selectedTool == DrawingTool.eraser) {
      return;
    }

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

    if (_selectedTool == DrawingTool.slashedRectangle) {
      final currentPreview = _previewElementNotifier.value;
      if (currentPreview is SlashedRectangle) {
        final finalRect = SlashedRectangle(
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

    if (_isShapeToolSelected) return;

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
         return Paint();
      case DrawingTool.line:
        return Paint()
          ..color = Colors.black
          ..strokeWidth = 2.0;
      case DrawingTool.rectangle:
      case DrawingTool.crossedRectangle:
      case DrawingTool.slashedRectangle:
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

  Future<void> _saveDrawing() async {
    final imageProvider = _displayImage.image;
    final completer = Completer<ui.Image>();
    imageProvider.resolve(const ImageConfiguration()).addListener(
        ImageStreamListener((info, _) => completer.complete(info.image)));
    final backgroundImage = await completer.future;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = Size(backgroundImage.width.toDouble(), backgroundImage.height.toDouble());

    canvas.drawImage(backgroundImage, Offset.zero, Paint());

    if (_imageBounds != null) {
      final scaleX = size.width / _imageBounds!.width;
      final scaleY = size.height / _imageBounds!.height;
      
      canvas.save();
      canvas.translate(-_imageBounds!.left * scaleX, -_imageBounds!.top * scaleY);
      canvas.scale(scaleX, scaleY);

      for (final element in _elementsNotifier.value) {
        element.draw(canvas, _imageBounds!.size);
      }
      canvas.restore();
    }
    
    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData == null) {
       if (mounted) Navigator.of(context).pop(null);
       return;
    }
    final uint8List = byteData.buffer.asUint8List();

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: widget.drawingType == 'koshishita'
                  ? [
                      _buildToolButton(DrawingTool.pen, Icons.edit, '自由線'),
                      _buildToolButton(DrawingTool.line, Icons.show_chart, '直線'),
                      _buildToolButton(DrawingTool.rectangle, Icons.crop_square, '四角'),
                      _buildToolButton(DrawingTool.crossedRectangle, Icons.close, '四角バツ'),
                      _buildToolButton(DrawingTool.slashedRectangle, Icons.format_strikethrough, '四角斜線'),
                      _buildToolButton(DrawingTool.dimension, Icons.straighten, '寸法線'),
                      _buildToolButton(DrawingTool.text, Icons.text_fields, 'テキスト'),
                      _buildToolButton(DrawingTool.eraser, Icons.cleaning_services, '消しゴム'),
                    ]
                  : [
                      _buildToolButton(DrawingTool.pen, Icons.edit, '自由線'),
                      _buildToolButton(DrawingTool.line, Icons.show_chart, '直線'),
                      _buildToolButton(DrawingTool.rectangle, Icons.crop_square, '四角'),
                      _buildToolButton(DrawingTool.crossedRectangle, Icons.close, '四角バツ'),
                      _buildToolButton(DrawingTool.dimension, Icons.straighten, '寸法線'),
                      _buildToolButton(DrawingTool.text, Icons.text_fields, 'テキスト'),
                      _buildToolButton(DrawingTool.eraser, Icons.cleaning_services, '消しゴム'),
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
              
              if (widget.clampXRange != null &&
                  widget.clampXRange!.length == 2) {
                final startX = _imageBounds!.left +
                    (_imageBounds!.width * widget.clampXRange![0]);
                final endX = _imageBounds!.left +
                    (_imageBounds!.width * widget.clampXRange![1]);
                _drawingAreaBounds = Rect.fromLTRB(
                    startX, _imageBounds!.top, endX, _imageBounds!.bottom);
              } else {
                _drawingAreaBounds = _imageBounds;
              }

              return RepaintBoundary(
                key: _canvasKey,
                child: Stack(
                  alignment: Alignment.topLeft,
                  children: [
                    Positioned.fromRect(
                      rect: _imageBounds!,
                      child: _displayImage,
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