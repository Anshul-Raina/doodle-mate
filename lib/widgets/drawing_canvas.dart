import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/drawing_stroke.dart';
import 'drawing_painter.dart';

class DrawingCanvas extends StatefulWidget {
  final List<DrawingStroke> strokes;
  final Function(DrawingStroke) onStrokeAdded;
  final Function() onUndo;
  final Function() onClear;
  final Color selectedColor;
  final double selectedWidth;
  final String userId;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.onStrokeAdded,
    required this.onUndo,
    required this.onClear,
    required this.selectedColor,
    required this.selectedWidth,
    required this.userId,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  DrawingStroke? _currentStroke;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: RepaintBoundary(
        key: widget.key,
        child: GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            painter: DrawingPainter(
              strokes: widget.strokes,
              currentStroke: _currentStroke,
            ),
            size: Size.infinite,
            child: Container(),
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final uuid = const Uuid();
    _currentStroke = DrawingStroke(
      id: uuid.v4(),
      userId: widget.userId,
      color: widget.selectedColor,
      width: widget.selectedWidth,
      points: [details.localPosition],
    );
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke != null) {
      _currentStroke = _currentStroke!.copyWith(
        points: [..._currentStroke!.points, details.localPosition],
      );
      setState(() {});
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentStroke != null) {
      widget.onStrokeAdded(_currentStroke!);
      _currentStroke = null;
      setState(() {});
    }
  }
}