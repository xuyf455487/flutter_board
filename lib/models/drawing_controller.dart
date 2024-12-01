import 'package:flutter/material.dart';
import 'drawing_tool.dart';
import 'drawing_point.dart';

class DrawingController extends ChangeNotifier {
  List<DrawingPoint?> _points = [];
  List<List<DrawingPoint?>> _undoHistory = [];
  List<List<DrawingPoint?>> _redoHistory = [];
  Color _selectedColor = Colors.red;
  DrawingTool _selectedTool = DrawingTool.pen;
  double _selectedSize = 2.0;

  List<DrawingPoint?> get points => _points;
  Color get selectedColor => _selectedColor;
  DrawingTool get selectedTool => _selectedTool;
  double get selectedSize => _selectedSize;
  bool get canUndo => _points.isNotEmpty;
  bool get canRedo => _redoHistory.isNotEmpty;

  set points(List<DrawingPoint?> newPoints) {
    if (newPoints.length > _points.length) {  // 新增绘制
      // 如果最后一个点是 null，说明是一次完整的绘制
      if (newPoints.isNotEmpty && newPoints.last == null) {
        _undoHistory.add(List.from(_points));
      }
    }
    _points = newPoints;
    notifyListeners();
  }

  void setColor(Color color) {
    _selectedColor = color;
    notifyListeners();
  }

  void setTool(DrawingTool tool) {
    _selectedTool = tool;
    notifyListeners();
  }

  void setSize(double size) {
    _selectedSize = size;
    notifyListeners();
  }

  void clear() {
    _undoHistory.add(List.from(_points));
    _points.clear();
    _redoHistory.clear();
    notifyListeners();
  }

  void undo() {
    if (_points.isEmpty) return;

    // 从后往前找到最后一次绘制的内容（直到遇到 null）
    int endIndex = _points.length;
    int startIndex = endIndex - 1;

    // 如果最后一个点是 null，跳过它
    if (startIndex >= 0 && _points[startIndex] == null) {
      startIndex--;
    }

    // 继续向前查找，直到遇到 null 或到达列表开头
    while (startIndex >= 0 && _points[startIndex] != null) {
      startIndex--;
    }
    startIndex++; // 回到第一个非 null 点

    // 保存要撤销的内容
    List<DrawingPoint?> removedPoints = _points.sublist(startIndex, endIndex);
    _redoHistory.add(removedPoints);

    // 更新当前点列表
    _points = _points.sublist(0, startIndex);
    notifyListeners();
  }

  void redo() {
    if (_redoHistory.isEmpty) return;
    List<DrawingPoint?> pointsToRestore = _redoHistory.removeLast();
    _points = [..._points, ...pointsToRestore];
    notifyListeners();
  }

  Map<String, dynamic> toJson() {
    return {
      'points': _points.map((p) => p?.toJson()).toList(),
      'selectedColor': _selectedColor.value,
      'selectedTool': _selectedTool.index,
      'selectedSize': _selectedSize,
    };
  }

  void fromJson(Map<String, dynamic> json) {
    _points = (json['points'] as List)
        .map((p) => p == null ? null : DrawingPoint.fromJson(p))
        .toList();
    _selectedColor = Color(json['selectedColor'] as int);
    _selectedTool = DrawingTool.values[json['selectedTool'] as int];
    _selectedSize = json['selectedSize'] as double;
    _undoHistory.clear();
    _redoHistory.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _points.clear();
    _undoHistory.clear();
    _redoHistory.clear();
    super.dispose();
  }
} 