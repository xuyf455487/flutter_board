import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_board/test_json.dart';
import '../widgets/drawing_canvas.dart';
import '../models/drawing_tool.dart';
import '../models/drawing_controller.dart';

// 绘图页面组件
class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

// 绘图页面状态类
class _DrawingPageState extends State<DrawingPage> {
  final DrawingController _controller = DrawingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // 将绘画内容转换为 JSON 字符串
  String exportToJson() {
    return jsonEncode(_controller.toJson());
  }

  // 从 JSON 字符串还原绘画内容
  void importFromJson(String jsonString) {
    final json = jsonDecode(jsonString);
    _controller.fromJson(json);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Board'),
        actions: [
          // 添加撤销按钮
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: '撤销 (Ctrl+Z)',
            onPressed: _controller.canUndo ? () {
              setState(() {
                _controller.undo();
              });
            } : null,
          ),
          // 添加恢复按钮
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: '恢复 (Ctrl+Y)',
            onPressed: _controller.canRedo ? () {
              setState(() {
                _controller.redo();
              });
            } : null,
          ),
          // 添加导出按钮
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: '导出',
            onPressed: () {
              final jsonString = exportToJson();
              TestJson.testJson = jsonString;
            },
          ),
          // 添加导入按钮
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: '导入',
            onPressed: () {
              importFromJson(TestJson.testJson);
            },
          ),
        ],
      ),
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (HardwareKeyboard.instance.isControlPressed) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.keyZ) {
                if (_controller.canUndo) {
                  setState(() {
                    _controller.undo();
                  });
                }
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.keyY) {
                if (_controller.canRedo) {
                  setState(() {
                    _controller.redo();
                  });
                }
                return KeyEventResult.handled;
              }
            }
          }
          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            // 绘图画布
            DrawingCanvas(
              drawingPoints: _controller.points,
              selectedColor: _controller.selectedColor,
              selectedTool: _controller.selectedTool,
              selectedSize: _controller.selectedSize,
              onDrawingPointsChanged: (points) {
                setState(() {
                  _controller.points = points;
                });
              },
            ),
            // 底部工具栏
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  // 工具按钮行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildToolButton(
                        icon: Icons.edit,
                        tool: DrawingTool.pen,
                        tooltip: '画笔',
                      ),
                      _buildToolButton(
                        icon: Icons.arrow_forward,
                        tool: DrawingTool.arrow,
                        tooltip: '箭头',
                      ),
                      _buildToolButton(
                        icon: Icons.rectangle_outlined,
                        tool: DrawingTool.rectangle,
                        tooltip: '矩形',
                      ),
                      _buildToolButton(
                        icon: Icons.circle_outlined,
                        tool: DrawingTool.oval,
                        tooltip: '椭圆',
                      ),
                      _buildToolButton(
                        icon: Icons.grid_4x4,
                        tool: DrawingTool.mosaic,
                        tooltip: '马赛克',
                      ),
                      _buildToolButton(
                        icon: Icons.text_fields,
                        tool: DrawingTool.text,
                        tooltip: '文字',
                      ),
                      _buildToolButton(
                        icon: Icons.pan_tool,
                        tool: DrawingTool.move,
                        tooltip: '移动',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 颜色选择行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildColorButton(Colors.red),
                      _buildColorButton(Colors.blue),
                      _buildColorButton(Colors.green),
                      _buildColorButton(Colors.black),
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _controller.clear();
                          });
                        },
                      ),
                    ],
                  ),
                  // 大小选择行
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildSizeButton('小', 2.0),
                      _buildSizeButton('中', 5.0),
                      _buildSizeButton('大', 10.0),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建工具按钮的方法
  Widget _buildToolButton({
    required IconData icon,
    required DrawingTool tool,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        icon: Icon(
          icon,
          color: _controller.selectedTool == tool ? Colors.blue : Colors.grey,
        ),
        onPressed: () {
          setState(() {
            _controller.setTool(tool);
          });
        },
      ),
    );
  }

  // 构建颜色按钮的方法
  Widget _buildColorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.setColor(color);
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _controller.selectedColor == color ? Colors.white : Colors.grey,
            width: 2,
          ),
        ),
      ),
    );
  }

  // 构建大小按钮的方法
  Widget _buildSizeButton(String label, double size) {
    return TextButton(
      onPressed: () {
        setState(() {
          _controller.setSize(size);
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: _controller.selectedSize == size ? Colors.blue : Colors.grey[300],
        foregroundColor: _controller.selectedSize == size ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }
} 