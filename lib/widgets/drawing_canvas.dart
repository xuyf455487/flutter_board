import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/drawing_tool.dart';
import '../models/drawing_point.dart';

// 画布组件 - 处理所有绘图操作
class DrawingCanvas extends StatefulWidget {
  final List<DrawingPoint?> drawingPoints;
  final Color selectedColor;
  final DrawingTool selectedTool;
  final double selectedSize;
  final Function(List<DrawingPoint?>) onDrawingPointsChanged;

  const DrawingCanvas({
    super.key,
    required this.drawingPoints,
    required this.selectedColor,
    required this.selectedTool,
    required this.selectedSize,
    required this.onDrawingPointsChanged,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  Offset? startPoint;
  DrawingPoint? selectedPoint;
  Offset? lastPosition;
  static const double mosaicSize = 12;
  TextEditingController textController = TextEditingController();

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          color: Colors.white,
          child: GestureDetector(
            onDoubleTap: () {
              if (widget.selectedTool == DrawingTool.move) {
                _deleteSelectedPoints();
              }
            },
            onTapDown: (details) {
              final canvasPoint = _convertToCanvasPoint(details.localPosition, constraints);
              if (widget.selectedTool == DrawingTool.text) {
                _showTextDialog(canvasPoint);
              } else if (widget.selectedTool == DrawingTool.move) {
                _selectPoint(canvasPoint);
              }
            },
            onPanStart: (details) {
              final canvasPoint = _convertToCanvasPoint(details.localPosition, constraints);
              if (widget.selectedTool == DrawingTool.mosaic) {
                _drawMosaic(canvasPoint);
              } else if (widget.selectedTool == DrawingTool.arrow || 
                  widget.selectedTool == DrawingTool.rectangle ||
                  widget.selectedTool == DrawingTool.oval) {
                startPoint = canvasPoint;
              } else if (widget.selectedTool == DrawingTool.move) {
                lastPosition = canvasPoint;
                if (selectedPoint == null) {
                  _selectPoint(canvasPoint);
                }
              } else {
                _handlePenDraw(canvasPoint);
              }
            },
            onPanUpdate: (details) {
              final canvasPoint = _convertToCanvasPoint(details.localPosition, constraints);
              if (widget.selectedTool == DrawingTool.mosaic) {
                _drawMosaic(canvasPoint);
              } else if (widget.selectedTool == DrawingTool.arrow) {
                if (startPoint != null) {
                  _handleArrowDraw(canvasPoint);
                }
              } else if (widget.selectedTool == DrawingTool.rectangle) {
                if (startPoint != null) {
                  _handleShapeDraw(canvasPoint);
                }
              } else if (widget.selectedTool == DrawingTool.oval) {
                if (startPoint != null) {
                  _handleShapeDraw(canvasPoint);
                }
              } else if (widget.selectedTool == DrawingTool.move && selectedPoint != null) {
                _movePoint(canvasPoint);
              } else {
                _handlePenDraw(canvasPoint);
              }
            },
            onPanEnd: (_) {
              widget.onDrawingPointsChanged([
                ...widget.drawingPoints,
                null,
              ]);
              startPoint = null;
              if (widget.selectedTool == DrawingTool.move) {
                selectedPoint = null;
                lastPosition = null;
              }
            },
            child: CustomPaint(
              painter: DrawingPainter(
                drawingPoints: widget.drawingPoints,
                canvasSize: Size(constraints.maxWidth, constraints.maxHeight),
              ),
              size: Size(constraints.maxWidth, constraints.maxHeight),
            ),
          ),
        );
      },
    );
  }

  Offset _convertToCanvasPoint(Offset point, BoxConstraints constraints) {
    final scaleX = constraints.maxWidth / 1000;
    final scaleY = constraints.maxHeight / 1000;
    final scale = math.min(scaleX, scaleY);
    
    final dx = (constraints.maxWidth - 1000 * scale) / 2;
    final dy = (constraints.maxHeight - 1000 * scale) / 2;

    return Offset(
      (point.dx - dx) / scale,
      (point.dy - dy) / scale,
    );
  }

  void _drawMosaic(Offset position) {
    final gridX = (position.dx / mosaicSize).floor() * mosaicSize;
    final gridY = (position.dy / mosaicSize).floor() * mosaicSize;

    widget.onDrawingPointsChanged([
      ...widget.drawingPoints,
      DrawingPoint(
        offset: Offset(gridX, gridY),
        paint: Paint()
          ..color = Colors.black.withOpacity(0.2)
          ..strokeWidth = mosaicSize * (widget.selectedSize / 2)
          ..strokeCap = StrokeCap.square,
        type: DrawingTool.mosaic,
      ),
    ]);
  }

  void _handlePenDraw(Offset position) {
    widget.onDrawingPointsChanged([
      ...widget.drawingPoints,
      DrawingPoint(
        offset: position,
        paint: Paint()
          ..color = widget.selectedColor
          ..strokeWidth = widget.selectedSize
          ..strokeCap = StrokeCap.round,
        type: widget.selectedTool,
      ),
    ]);
  }

  void _handleArrowDraw(Offset position) {
    widget.onDrawingPointsChanged([
      ...widget.drawingPoints.where((point) => 
        point?.type != DrawingTool.arrow || 
        point?.startPoint != startPoint).toList(),
      DrawingPoint(
        offset: position,
        startPoint: startPoint,
        paint: Paint()
          ..color = widget.selectedColor
          ..strokeWidth = widget.selectedSize
          ..strokeCap = StrokeCap.round,
        type: DrawingTool.arrow,
      ),
    ]);
  }

  void _handleShapeDraw(Offset position) {
    widget.onDrawingPointsChanged([
      ...widget.drawingPoints.where((point) => 
        point?.type != widget.selectedTool || 
        point?.startPoint != startPoint).toList(),
      DrawingPoint(
        offset: position,
        startPoint: startPoint,
        paint: Paint()
          ..color = widget.selectedColor
          ..strokeWidth = widget.selectedSize
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke,
        type: widget.selectedTool,
      ),
    ]);
  }

  void _showTextDialog(Offset position) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('输入文字'),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '请输入文字',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                widget.onDrawingPointsChanged([
                  ...widget.drawingPoints,
                  DrawingPoint(
                    offset: position,
                    paint: Paint()
                      ..color = widget.selectedColor
                      ..strokeWidth = widget.selectedSize
                      ..strokeCap = StrokeCap.round,
                    type: DrawingTool.text,
                    text: textController.text,
                  ),
                ]);
              }
              textController.clear();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _selectPoint(Offset position) {
    for (int i = widget.drawingPoints.length - 1; i >= 0; i--) {
      final point = widget.drawingPoints[i];
      if (point == null) continue;

      if (_isPointInside(position, point)) {
        setState(() {
          selectedPoint = point;
        });
        break;
      }
    }
  }

  bool _isPointInside(Offset position, DrawingPoint point) {
    const hitTestSize = 20.0;

    switch (point.type) {
      case DrawingTool.pen:
      case DrawingTool.mosaic:
        return (position - point.offset).distance < hitTestSize;
        
      case DrawingTool.arrow:
      case DrawingTool.rectangle:
      case DrawingTool.oval:
        if (point.startPoint == null) return false;
        final rect = Rect.fromPoints(point.startPoint!, point.offset).inflate(hitTestSize);
        return rect.contains(position);
        
      case DrawingTool.text:
        if (point.text != null) {
          final textSpan = TextSpan(
            text: point.text,
            style: TextStyle(
              color: point.paint.color,
              fontSize: point.paint.strokeWidth * 8,
            ),
          );
          final textPainter = TextPainter(
            text: textSpan,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          
          final rect = Rect.fromCenter(
            center: point.offset,
            width: textPainter.width,
            height: textPainter.height,
          );
          return rect.contains(position);
        }
        return false;
        
      default:
        return false;
    }
  }

  void _movePoint(Offset position) {
    if (selectedPoint == null || lastPosition == null) return;

    final delta = position - lastPosition!;
    final index = widget.drawingPoints.indexOf(selectedPoint);
    if (index == -1) return;

    if (selectedPoint!.type == DrawingTool.pen || 
        selectedPoint!.type == DrawingTool.mosaic) {
      final points = <DrawingPoint>[];
      final nullPoints = <int>[];
      int startIndex = index;

      while (startIndex >= 0 && 
             (widget.drawingPoints[startIndex] == null || 
              widget.drawingPoints[startIndex]?.type == selectedPoint!.type)) {
        if (widget.drawingPoints[startIndex] == null) {
          nullPoints.add(startIndex);
          break;
        } else {
          points.insert(0, widget.drawingPoints[startIndex]!);
        }
        startIndex--;
      }
      startIndex++;

      int endIndex = index + 1;
      while (endIndex < widget.drawingPoints.length && 
             widget.drawingPoints[endIndex]?.type == selectedPoint!.type) {
        points.add(widget.drawingPoints[endIndex]!);
        endIndex++;
      }
      if (endIndex < widget.drawingPoints.length && 
          widget.drawingPoints[endIndex] == null) {
        nullPoints.add(endIndex);
        endIndex++;
      }

      final newPoints = List<DrawingPoint?>.filled(endIndex - startIndex, null);
      var pointIndex = 0;
      for (int i = 0; i < newPoints.length; i++) {
        if (nullPoints.contains(i + startIndex)) {
          newPoints[i] = null;
        } else {
          newPoints[i] = DrawingPoint(
            offset: points[pointIndex].offset + delta,
            paint: points[pointIndex].paint,
            type: points[pointIndex].type,
          );
          if (points[pointIndex] == selectedPoint) {
            selectedPoint = newPoints[i];
          }
          pointIndex++;
        }
      }

      widget.onDrawingPointsChanged([
        ...widget.drawingPoints.sublist(0, startIndex),
        ...newPoints,
        ...widget.drawingPoints.sublist(endIndex),
      ]);
    } else {
      final newPoint = DrawingPoint(
        offset: selectedPoint!.offset + delta,
        startPoint: selectedPoint!.startPoint != null 
            ? selectedPoint!.startPoint! + delta 
            : null,
        paint: selectedPoint!.paint,
        type: selectedPoint!.type,
        text: selectedPoint!.text,
      );

      widget.onDrawingPointsChanged([
        ...widget.drawingPoints.sublist(0, index),
        newPoint,
        ...widget.drawingPoints.sublist(index + 1),
      ]);
      selectedPoint = newPoint;
    }
    
    lastPosition = position;
  }

  void _deleteSelectedPoints() {
    if (selectedPoint == null) return;

    final index = widget.drawingPoints.indexOf(selectedPoint);
    if (index == -1) return;

    if (selectedPoint!.type == DrawingTool.pen || 
        selectedPoint!.type == DrawingTool.mosaic) {
      int startIndex = index;
      int endIndex = index;

      while (startIndex >= 0 && 
             (widget.drawingPoints[startIndex] == null || 
              widget.drawingPoints[startIndex]?.type == selectedPoint!.type)) {
        if (widget.drawingPoints[startIndex] == null) {
          break;
        }
        startIndex--;
      }
      startIndex++;

      while (endIndex < widget.drawingPoints.length && 
             widget.drawingPoints[endIndex]?.type == selectedPoint!.type) {
        endIndex++;
      }
      if (endIndex < widget.drawingPoints.length && 
          widget.drawingPoints[endIndex] == null) {
        endIndex++;
      }

      widget.onDrawingPointsChanged([
        ...widget.drawingPoints.sublist(0, startIndex),
        ...widget.drawingPoints.sublist(endIndex),
      ]);
    } else {
      widget.onDrawingPointsChanged([
        ...widget.drawingPoints.sublist(0, index),
        ...widget.drawingPoints.sublist(index + 1),
      ]);
    }
    
    selectedPoint = null;
    lastPosition = null;
  }
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;
  final Size canvasSize;

  DrawingPainter({
    required this.drawingPoints,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 1000;
    final scaleY = size.height / 1000;
    final scale = math.min(scaleX, scaleY);

    final dx = (size.width - 1000 * scale) / 2;
    final dy = (size.height - 1000 * scale) / 2;

    canvas.translate(dx, dy);
    canvas.scale(scale);

    for (var point in drawingPoints) {
      if (point == null) continue;

      switch (point.type) {
        case DrawingTool.pen:
          final nextIndex = drawingPoints.indexOf(point) + 1;
          if (nextIndex < drawingPoints.length && drawingPoints[nextIndex] != null) {
            canvas.drawLine(
              point.offset,
              drawingPoints[nextIndex]!.offset,
              point.paint,
            );
          }
          break;
          
        case DrawingTool.arrow:
          if (point.startPoint != null) {
            drawArrow(canvas, point.startPoint!, point.offset, point.paint);
          }
          break;
          
        case DrawingTool.rectangle:
          if (point.startPoint != null) {
            final rect = Rect.fromPoints(point.startPoint!, point.offset);
            canvas.drawRect(rect, point.paint);
          }
          break;
          
        case DrawingTool.oval:
          if (point.startPoint != null) {
            final rect = Rect.fromPoints(point.startPoint!, point.offset);
            canvas.drawOval(rect, point.paint);
          }
          break;
          
        case DrawingTool.mosaic:
          canvas.drawRect(
            Rect.fromCenter(
              center: point.offset,
              width: point.paint.strokeWidth,
              height: point.paint.strokeWidth,
            ),
            point.paint,
          );
          break;
          
        case DrawingTool.text:
          if (point.text != null) {
            final textSpan = TextSpan(
              text: point.text,
              style: TextStyle(
                color: point.paint.color,
                fontSize: point.paint.strokeWidth * 8,
              ),
            );
            final textPainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            final offset = Offset(
              point.offset.dx - textPainter.width / 2,
              point.offset.dy - textPainter.height / 2,
            );
            textPainter.paint(canvas, offset);
          }
          break;
          
        case DrawingTool.move:
          break;
      }
    }
  }

  void drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    double length = (end - start).distance;
    double dx = (end.dx - start.dx) / length;
    double dy = (end.dy - start.dy) / length;

    Offset arrowEnd = Offset(
      end.dx - dx * paint.strokeWidth * 2,
      end.dy - dy * paint.strokeWidth * 2,
    );

    canvas.drawLine(start, arrowEnd, paint);

    Path path = Path();
    path.moveTo(end.dx, end.dy);

    double arrowWidth = paint.strokeWidth * 3;
    double arrowLength = paint.strokeWidth * 5;

    double perpDx = -dy;
    double perpDy = dx;

    Offset baseLeft = Offset(
      end.dx - dx * arrowLength - perpDx * arrowWidth,
      end.dy - dy * arrowLength - perpDy * arrowWidth,
    );
    Offset baseRight = Offset(
      end.dx - dx * arrowLength + perpDx * arrowWidth,
      end.dy - dy * arrowLength + perpDy * arrowWidth,
    );

    path.lineTo(baseLeft.dx, baseLeft.dy);
    path.lineTo(baseRight.dx, baseRight.dy);
    path.close();

    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 