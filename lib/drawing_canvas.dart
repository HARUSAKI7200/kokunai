// lib/drawing_canvas.dart

import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';

enum DrawingTool { pen, line, rectangle, eraser, dimension, text }

// DrawingElementクラス群
abstract class DrawingElement {
  final int id;
  Paint paint;
  DrawingElement({required this.id, required this.paint});
  void draw(Canvas canvas, Size size);
  DrawingElement clone();
  Map<String, dynamic> toJson();
  bool contains(Offset point);
  void move(Offset delta);
  factory DrawingElement.fromJson(Map<String, dynamic> json) {
    switch (json['type']) {
      case 'path':
        return DrawingPath.fromJson(json);
      case 'line':
        return StraightLine.fromJson(json);
      case 'rect':
        return Rectangle.fromJson(json);
      case 'dimension':
        return DimensionLine.fromJson(json);
      case 'text':
        return DrawingText.fromJson(json);
      default:
        throw Exception('Unknown DrawingElement type');
    }
  }
}

abstract class DrawingElementWithPoints extends DrawingElement {
  DrawingElementWithPoints({required super.id, required super.paint});
  bool updatePosition(Offset newPoint);
}

class DrawingPath extends DrawingElementWithPoints {
  List<Offset> points;
  DrawingPath({required super.id, required this.points, required super.paint});
  @override
  void draw(Canvas canvas, Size size) {
    final path = Path();
    if (points.isNotEmpty) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool updatePosition(Offset newPoint) {
    points.add(newPoint);
    return true;
  }

  @override
  DrawingPath clone() =>
      DrawingPath(id: id, points: List.from(points), paint: Paint.from(paint));
  @override
  Map<String, dynamic> toJson() => {
        'type': 'path',
        'id': id,
        'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
        'paint': {
          'color': paint.color.value,
          'strokeWidth': paint.strokeWidth,
          'blendMode': paint.blendMode.index
        },
      };
  factory DrawingPath.fromJson(Map<String, dynamic> json) {
    final paintData = json['paint'];
    return DrawingPath(
      id: json['id'],
      points: (json['points'] as List)
          .map((p) => Offset(p['dx'].toDouble(), p['dy'].toDouble()))
          .toList(),
      paint: Paint()
        ..color = Color(paintData['color'])
        ..strokeWidth = paintData['strokeWidth']
        ..blendMode = BlendMode.values[paintData['blendMode'] ?? 0]
        ..style = PaintingStyle.stroke,
    );
  }
  @override
  bool contains(Offset point) {
    return false;
  }

  @override
  void move(Offset delta) {
    points = points.map((p) => p + delta).toList();
  }
}

class StraightLine extends DrawingElementWithPoints {
  Offset start;
  Offset end;
  StraightLine(
      {required super.id,
      required this.start,
      required this.end,
      required super.paint});
  @override
  void draw(Canvas canvas, Size size) => canvas.drawLine(start, end, paint);
  @override
  bool updatePosition(Offset newPoint) {
    end = newPoint;
    return true;
  }

  @override
  StraightLine clone() =>
      StraightLine(id: id, start: start, end: end, paint: Paint.from(paint));
  @override
  Map<String, dynamic> toJson() => {
        'type': 'line',
        'id': id,
        'start': {'dx': start.dx, 'dy': start.dy},
        'end': {'dx': end.dx, 'dy': end.dy},
        'paint': {'color': paint.color.value, 'strokeWidth': paint.strokeWidth},
      };
  factory StraightLine.fromJson(Map<String, dynamic> json) => StraightLine(
        id: json['id'],
        start: Offset(
            json['start']['dx'].toDouble(), json['start']['dy'].toDouble()),
        end: Offset(json['end']['dx'].toDouble(), json['end']['dy'].toDouble()),
        paint: Paint()
          ..color = Color(json['paint']['color'])
          ..strokeWidth = json['paint']['strokeWidth'],
      );
  @override
  bool contains(Offset point) => false;
  @override
  void move(Offset delta) {
    start += delta;
    end += delta;
  }
}

class Rectangle extends DrawingElement {
  Offset start;
  Offset end;
  Rectangle(
      {required super.id,
      required this.start,
      required this.end,
      required super.paint});
  Rect get rect => Rect.fromPoints(start, end);
  @override
  void draw(Canvas canvas, Size canvasSize) {
    canvas.drawRect(rect, paint);
  }

  @override
  Rectangle clone() =>
      Rectangle(id: id, start: start, end: end, paint: Paint.from(paint));
  @override
  Map<String, dynamic> toJson() => {
        'type': 'rect',
        'id': id,
        'start': {'dx': start.dx, 'dy': start.dy},
        'end': {'dx': end.dx, 'dy': end.dy},
        'paint': {'color': paint.color.value, 'strokeWidth': paint.strokeWidth},
      };
  factory Rectangle.fromJson(Map<String, dynamic> json) => Rectangle(
        id: json['id'],
        start: Offset(
            json['start']['dx'].toDouble(), json['start']['dy'].toDouble()),
        end: Offset(json['end']['dx'].toDouble(), json['end']['dy'].toDouble()),
        paint: Paint()
          ..color = Color(json['paint']['color'])
          ..strokeWidth = json['paint']['strokeWidth']
          ..style = PaintingStyle.stroke,
      );
  @override
  bool contains(Offset point) => rect.contains(point);
  @override
  void move(Offset delta) {
    start += delta;
    end += delta;
  }
}

class DimensionLine extends DrawingElementWithPoints {
  Offset start;
  Offset end;
  DimensionLine(
      {required super.id,
      required this.start,
      required this.end,
      required super.paint});
  @override
  void draw(Canvas canvas, Size size) {
    canvas.drawLine(start, end, paint);
    _drawArrow(canvas, end, start, paint);
    _drawArrow(canvas, start, end, paint);
  }

  void _drawArrow(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final arrowSize = 8.0;
    final angle = math.atan2(p1.dy - p2.dy, p1.dx - p2.dx);
    final path = Path();
    path.moveTo(p1.dx - arrowSize * math.cos(angle - math.pi / 6),
        p1.dy - arrowSize * math.sin(angle - math.pi / 6));
    path.lineTo(p1.dx, p1.dy);
    path.lineTo(p1.dx - arrowSize * math.cos(angle + math.pi / 6),
        p1.dy - arrowSize * math.sin(angle + math.pi / 6));
    canvas.drawPath(path, paint..style = PaintingStyle.stroke);
  }

  @override
  bool updatePosition(Offset newPoint) {
    end = newPoint;
    return true;
  }

  @override
  DimensionLine clone() =>
      DimensionLine(id: id, start: start, end: end, paint: Paint.from(paint));
  @override
  Map<String, dynamic> toJson() => {
        'type': 'dimension',
        'id': id,
        'start': {'dx': start.dx, 'dy': start.dy},
        'end': {'dx': end.dx, 'dy': end.dy},
        'paint': {'color': paint.color.value, 'strokeWidth': paint.strokeWidth},
      };
  factory DimensionLine.fromJson(Map<String, dynamic> json) => DimensionLine(
        id: json['id'],
        start: Offset(
            json['start']['dx'].toDouble(), json['start']['dy'].toDouble()),
        end: Offset(json['end']['dx'].toDouble(), json['end']['dy'].toDouble()),
        paint: Paint()
          ..color = Color(json['paint']['color'])
          ..strokeWidth = json['paint']['strokeWidth'],
      );
  @override
  bool contains(Offset point) => false;
  @override
  void move(Offset delta) {
    start += delta;
    end += delta;
  }
}

class DrawingText extends DrawingElement {
  String text;
  Offset position;

  DrawingText(
      {required super.id,
      required this.text,
      required this.position,
      required super.paint});

  @override
  void draw(Canvas canvas, Size size) {
    final textSpan = TextSpan(
        text: text,
        style: TextStyle(
            color: paint.color, fontSize: 22, fontWeight: FontWeight.bold));
    final textPainter =
        TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr)
          ..layout(minWidth: 0, maxWidth: size.width);

    final adjustedPosition = Offset(
      position.dx.clamp(0.0, size.width - textPainter.width),
      position.dy.clamp(0.0, size.height - textPainter.height),
    );
    textPainter.paint(canvas, adjustedPosition);
  }

  @override
  DrawingText clone() =>
      DrawingText(id: id, text: text, position: position, paint: Paint.from(paint));

  @override
  Map<String, dynamic> toJson() => {
        'type': 'text',
        'id': id,
        'text': text,
        'position': {'dx': position.dx, 'dy': position.dy},
        'paint': {'color': paint.color.value},
      };

  factory DrawingText.fromJson(Map<String, dynamic> json) => DrawingText(
        id: json['id'],
        text: json['text'],
        position: Offset(
            json['position']['dx'].toDouble(), json['position']['dy'].toDouble()),
        paint: Paint()..color = Color(json['paint']['color']),
      );

  @override
  bool contains(Offset point) {
    final textSpan = TextSpan(
        text: text,
        style: TextStyle(
            color: paint.color, fontSize: 22, fontWeight: FontWeight.bold));
    final textPainter =
        TextPainter(text: textSpan, textDirection: ui.TextDirection.ltr)
          ..layout();

    final rect =
        Rect.fromLTWH(position.dx, position.dy, textPainter.width, textPainter.height);

    return rect.contains(point);
  }

  @override
  void move(Offset delta) {
    position += delta;
  }
}

class DrawingCanvas extends StatelessWidget {
  final ValueNotifier<List<DrawingElement>> elementsNotifier;
  final ValueNotifier<DrawingElement?> previewElementNotifier;

  final DrawingTool selectedTool;
  final Function(DragDownDetails) onPanDown;
  final Function(DragStartDetails) onPanStart;
  final Function(DragUpdateDetails) onPanUpdate;
  final Function(DragEndDetails) onPanEnd;
  final Function(TapUpDetails) onTap;

  const DrawingCanvas({
    super.key,
    required this.elementsNotifier,
    required this.previewElementNotifier,
    required this.selectedTool,
    required this.onPanDown,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: onPanDown,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onTapUp: onTap,
      child: CustomPaint(
        painter: _DrawingPainter(
          elementsNotifier: elementsNotifier,
          previewElementNotifier: previewElementNotifier,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final ValueNotifier<List<DrawingElement>> elementsNotifier;
  final ValueNotifier<DrawingElement?> previewElementNotifier;

  _DrawingPainter({
    required this.elementsNotifier,
    required this.previewElementNotifier,
  }) : super(repaint: Listenable.merge([elementsNotifier, previewElementNotifier]));

  @override
  void paint(Canvas canvas, Size size) {
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    for (final element in elementsNotifier.value) {
      element.draw(canvas, size);
    }

    previewElementNotifier.value?.draw(canvas, size);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}