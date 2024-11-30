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
  static const double mosaicSize = 12;             // 马赛克块基础大小
  TextEditingController textController = TextEditingController();  // 文本输入控制器

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // 处理点击事件 - 主要用于文本输入
      onTapDown: (details) {
        if (widget.selectedTool == DrawingTool.text) {
          _showTextDialog(details.localPosition);
        }
      },
      // 处理拖动开始事件
      onPanStart: (details) {
        if (widget.selectedTool == DrawingTool.mosaic) {
          _drawMosaic(details.localPosition);
        } else if (widget.selectedTool == DrawingTool.arrow || 
            widget.selectedTool == DrawingTool.rectangle ||
            widget.selectedTool == DrawingTool.oval) {
          startPoint = details.localPosition;
        } else {
          _handlePenDraw(details.localPosition);
        }
      },
      // 处理拖动更新事件
      onPanUpdate: (details) {
        if (widget.selectedTool == DrawingTool.mosaic) {
          _drawMosaic(details.localPosition);
        } else if (widget.selectedTool == DrawingTool.arrow) {
          if (startPoint != null) {
            _handleArrowDraw(details.localPosition);
          }
        } else if (widget.selectedTool == DrawingTool.rectangle) {
          if (startPoint != null) {
            _handleShapeDraw(details.localPosition);
          }
        } else if (widget.selectedTool == DrawingTool.oval) {
          if (startPoint != null) {
            _handleShapeDraw(details.localPosition);
          }
        } else {
          _handlePenDraw(details.localPosition);
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
      },
      child: CustomPaint(
        painter: DrawingPainter(drawingPoints: widget.drawingPoints),
        size: Size.infinite,
      ),
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

  // 显示文本输入对话框的方法
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
}

// 自定义画布绘制器 - 负责实际的绘制操作
class DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> drawingPoints;

  DrawingPainter({required this.drawingPoints});

  @override
  void paint(Canvas canvas, Size size) {
    // 按顺序绘制所有内容
    for (var point in drawingPoints) {
      if (point == null) continue;  // 跳过空值

      switch (point.type) {
        case DrawingTool.pen:
          // 画笔需要特殊处理连续的点
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
                fontSize: 20,
              ),
            );
            final textPainter = TextPainter(
              text: textSpan,
              textDirection: TextDirection.ltr,
            );
            textPainter.layout();
            textPainter.paint(canvas, point.offset);
          }
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
    path.moveTo(end.dx, end.dy);  // 箭头尖端

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

// 绘图点数据类 - 支持 JSON 序列化
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