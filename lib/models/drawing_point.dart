import 'package:flutter/material.dart';
import 'dart:ui' show Paint, PaintingStyle, StrokeCap;
import 'drawing_tool.dart';

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

  factory DrawingPoint.fromJson(Map<String, dynamic> json) {
    return DrawingPoint(
      offset: Offset(
        json['offset']['dx'] as double,
        json['offset']['dy'] as double,
      ),
      startPoint: json['startPoint'] != null
          ? Offset(
              json['startPoint']['dx'] as double,
              json['startPoint']['dy'] as double,
            )
          : null,
      paint: Paint()
        ..color = Color(json['paint']['color'] as int)
        ..strokeWidth = json['paint']['strokeWidth'] as double
        ..strokeCap = StrokeCap.values[json['paint']['strokeCap'] as int]
        ..style = PaintingStyle.values[json['paint']['style'] as int],
      type: DrawingTool.values[json['type'] as int],
      text: json['text'] as String?,
    );
  }
} 