import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/drawing_tool.dart';

// 画布组件 - 处理所有绘图操作
class DrawingCanvas extends StatefulWidget {
  final List<DrawingPoint?> drawingPoints;         // 绘图点列表
  final Color selectedColor;                       // 选中的颜色
  final DrawingTool selectedTool;                  // 选中的工具
  final double selectedSize;                       // 选中的大小
  final Function(List<DrawingPoint?>) onDrawingPointsChanged;  // 绘图点变化回调

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
  Offset? startPoint;                              // 绘制起始点
  DrawingPoint? selectedPoint;  // 当前选中的绘制点
  Offset? lastPosition;        // 上一次的位置
  static const double mosaicSize = 12;             // 马赛克块基础大小
  TextEditingController textController = TextEditingController();  // 文本输入控制器

  // 添加坐标转换方法
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

  // 删除选中的连续点
  void _deleteSelectedPoints() {
    if (selectedPoint == null) return;

    final index = widget.drawingPoints.indexOf(selectedPoint);
    if (index == -1) return;

    // 只处理画笔和马赛克的连续删除，其他工具单独处理
    if (selectedPoint!.type == DrawingTool.pen || 
        selectedPoint!.type == DrawingTool.mosaic) {
      // 找到相邻的所有点和它们的索引
      int startIndex = index;
      int endIndex = index;

      // 向前查找直到遇到 null 或不同类型的点
      while (startIndex >= 0 && 
             (widget.drawingPoints[startIndex] == null || 
              widget.drawingPoints[startIndex]?.type == selectedPoint!.type)) {
        if (widget.drawingPoints[startIndex] == null) {
          break;  // 遇到 null 就停止，这表示一次绘制的结束
        }
        startIndex--;
      }
      startIndex++;

      // 向后查找直到遇到 null 或不同类型的点
      while (endIndex < widget.drawingPoints.length && 
             widget.drawingPoints[endIndex]?.type == selectedPoint!.type) {
        endIndex++;
      }
      if (endIndex < widget.drawingPoints.length && 
          widget.drawingPoints[endIndex] == null) {
        endIndex++;
      }

      // 更新绘图点列表，移除选中的点
      widget.onDrawingPointsChanged([
        ...widget.drawingPoints.sublist(0, startIndex),
        ...widget.drawingPoints.sublist(endIndex),
      ]);
    } else {
      // 其他工具（箭头、矩形、椭圆、文字）只删除单个点
      widget.onDrawingPointsChanged([
        ...widget.drawingPoints.sublist(0, index),
        ...widget.drawingPoints.sublist(index + 1),
      ]);
    }
    
    selectedPoint = null;
    lastPosition = null;
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
            // 添加双击事件处理
            onDoubleTap: () {
              if (widget.selectedTool == DrawingTool.move) {
                _deleteSelectedPoints();
              }
            },
            // 处理点击事件 - 主要用于文本输入
            onTapDown: (details) {
              final canvasPoint = _convertToCanvasPoint(details.localPosition, constraints);
              if (widget.selectedTool == DrawingTool.text) {
                _showTextDialog(canvasPoint);
              } else if (widget.selectedTool == DrawingTool.move) {
                _selectPoint(canvasPoint);
              }
            },
            // 处理拖动开始事件
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
            // 处理拖动更新事件
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
            // 处理拖动结束事件
            onPanEnd: (_) {
              if (widget.selectedTool != DrawingTool.arrow) {
                widget.onDrawingPointsChanged([
                  ...widget.drawingPoints,
                  null,
                ]);
              }
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

  // 绘制马赛克的方法
  void _drawMosaic(Offset position) {
    // 将位置对齐到网格
    final gridX = (position.dx / mosaicSize).floor() * mosaicSize;
    final gridY = (position.dy / mosaicSize).floor() * mosaicSize;

    widget.onDrawingPointsChanged([
      ...widget.drawingPoints,
      DrawingPoint(
        offset: Offset(gridX, gridY),
        paint: Paint()
          ..color = Colors.black.withOpacity(0.2)  // 使用20%透明度的黑色
          ..strokeWidth = mosaicSize * (widget.selectedSize / 2)
          ..strokeCap = StrokeCap.square,
        type: DrawingTool.mosaic,
      ),
    ]);
  }

  // 示文本输入对话框的方法
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
                    text: textController.text,  // 添加文本内容
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

  @override
  void dispose() {
    textController.dispose();                      // 释放文本控制器
    super.dispose();
  }

  // 画笔工具
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

  // 箭头工具
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

  // 矩形和椭圆工具
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

  // 选择要移动的点
  void _selectPoint(Offset position) {
    // 从后往前查找，这样可以选择最上层的内容
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

  // 检查点击位置是否在绘制内容内部
  bool _isPointInside(Offset position, DrawingPoint point) {
    const hitTestSize = 20.0;  // 点击检测范围

    switch (point.type) {
      case DrawingTool.pen:
      case DrawingTool.mosaic:  // 马赛克和画笔一样使用距离检测
        return (position - point.offset).distance < hitTestSize;
        
      case DrawingTool.arrow:
      case DrawingTool.rectangle:
      case DrawingTool.oval:
        if (point.startPoint == null) return false;
        final rect = Rect.fromPoints(point.startPoint!, point.offset).inflate(hitTestSize);
        return rect.contains(position);
        
      case DrawingTool.text:
        if (point.text != null) {
          // 计算文字的实际大小
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
          
          // 使用实际文字大小创建点击区域
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

  // 移动选中的内容
  void _movePoint(Offset position) {
    if (selectedPoint == null || lastPosition == null) return;

    final delta = position - lastPosition!;
    final index = widget.drawingPoints.indexOf(selectedPoint);
    if (index == -1) return;

    // 处理连续的点（画笔和马赛克）
    if (selectedPoint!.type == DrawingTool.pen || 
        selectedPoint!.type == DrawingTool.mosaic) {
      // 找到相邻的所有点和它们的索引
      final points = <DrawingPoint>[];
      final nullPoints = <int>[];  // 保存 null 点的位置
      int startIndex = index;

      // 向前查找直到遇到 null 或不同类型的点
      while (startIndex >= 0 && 
             (widget.drawingPoints[startIndex] == null || 
              widget.drawingPoints[startIndex]?.type == selectedPoint!.type)) {
        if (widget.drawingPoints[startIndex] == null) {
          nullPoints.add(startIndex);
          break;  // 遇到 null 就停止，这表示一次绘制的结束
        } else {
          points.insert(0, widget.drawingPoints[startIndex]!);
        }
        startIndex--;
      }
      startIndex++;

      // 向后查找直到遇到 null 或不同类型的点
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

      // 移动所有相关点
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

      // 更新绘图点列表
      widget.onDrawingPointsChanged([
        ...widget.drawingPoints.sublist(0, startIndex),
        ...newPoints,
        ...widget.drawingPoints.sublist(endIndex),
      ]);
    } else {
      // 处理单个点（其他工具）
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
}

// 自定义画布绘制器 - 负责实际的绘制操作
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;
  final Size canvasSize;

  DrawingPainter({
    required this.drawingPoints,
    required this.canvasSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 计算缩放比例
    final scaleX = size.width / 1000;
    final scaleY = size.height / 1000;
    final scale = math.min(scaleX, scaleY);

    // 计算居中偏移
    final dx = (size.width - 1000 * scale) / 2;
    final dy = (size.height - 1000 * scale) / 2;

    // 先平移到中心位置，再应用缩放
    canvas.translate(dx, dy);
    canvas.scale(scale);

    // 按顺序绘制所有内容
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
                fontSize: point.paint.strokeWidth * 8,  // 增大文字大小倍数
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

  // 绘制箭头的方法
  void drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    // 计算线条长度
    double length = (end - start).distance;
    
    // 计算单位向量
    double dx = (end.dx - start.dx) / length;
    double dy = (end.dy - start.dy) / length;

    // 计算箭头终点（比实际终点稍短）
    Offset arrowEnd = Offset(
      end.dx - dx * paint.strokeWidth * 2,  // 根据线条粗细调整箭头长度
      end.dy - dy * paint.strokeWidth * 2,
    );

    // 绘制主线
    canvas.drawLine(start, arrowEnd, paint);

    // 绘制箭头头部（一个三角形）
    Path path = Path();
    path.moveTo(end.dx, end.dy);  // 箭尖端

    // 计算箭头底部两个点
    double arrowWidth = paint.strokeWidth * 3;  // 箭头宽度是线条粗细的3倍
    double arrowLength = paint.strokeWidth * 5;  // 箭头长度是线条粗细的5倍

    // 计算垂直于线条方向的单位向量
    double perpDx = -dy;
    double perpDy = dx;

    // 计算箭头底部两个点
    Offset baseLeft = Offset(
      end.dx - dx * arrowLength - perpDx * arrowWidth,
      end.dy - dy * arrowLength - perpDy * arrowWidth,
    );
    Offset baseRight = Offset(
      end.dx - dx * arrowLength + perpDx * arrowWidth,
      end.dy - dy * arrowLength + perpDy * arrowWidth,
    );

    // 绘制箭头
    path.lineTo(baseLeft.dx, baseLeft.dy);
    path.lineTo(baseRight.dx, baseRight.dy);
    path.close();

    // 填充箭头
    paint.style = PaintingStyle.fill;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 绘图点数据类 - 支持 JSON 序列
class DrawingPoint {
  final Offset offset;
  final Offset? startPoint;
  final Paint paint;
  final DrawingTool type;
  final String? text;

  DrawingPoint({
    required this.offset,
    this.startPoint,
    required this.paint,
    required this.type,
    this.text,
  });

  // 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'offset': {'dx': offset.dx, 'dy': offset.dy},
      'startPoint': startPoint != null 
          ? {'dx': startPoint!.dx, 'dy': startPoint!.dy}
          : null,
      'paint': {
        'color': paint.color.value,
        'strokeWidth': paint.strokeWidth,
        'strokeCap': paint.strokeCap.index,
        'style': paint.style.index,
      },
      'type': type.index,
      'text': text,
    };
  }

  // 从 JSON 创建实例
  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      offset: Offset(
        json['offset']['dx'],
        json['offset']['dy'],
      ),
      startPoint: json['startPoint'] != null
          ? Offset(
              json['startPoint']['dx'],
              json['startPoint']['dy'],
            )
          : null,
      paint: Paint()
        ..color = Color(json['paint']['color'])
        ..strokeWidth = json['paint']['strokeWidth']
        ..strokeCap = StrokeCap.values[json['paint']['strokeCap']]
        ..style = PaintingStyle.values[json['paint']['style']],
      type: DrawingTool.values[json['type']],
      text: json['text'],
    );
  }
} 