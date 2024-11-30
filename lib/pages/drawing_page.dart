import 'package:flutter/material.dart';
import '../widgets/drawing_canvas.dart';
import '../models/drawing_tool.dart';

// 绘图页面组件
class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

// 绘图页面状态类
class _DrawingPageState extends State<DrawingPage> {
  Color selectedColor = Colors.red;                 // 当前选中的颜色
  List<DrawingPoint?> drawingPoints = [];          // 绘图点列表
  DrawingTool selectedTool = DrawingTool.pen;      // 当前选中的工具
  double selectedSize = 2.0;                       // 当前选中的画笔大小

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawing Board'),        // 页面标题
      ),
      body: Stack(
        children: [
          // 绘图画布
          DrawingCanvas(
            drawingPoints: drawingPoints,          // 传递绘图点数据
            selectedColor: selectedColor,          // 传递选中的颜色
            selectedTool: selectedTool,            // 传递选中的工具
            selectedSize: selectedSize,            // 传递选中的大小
            onDrawingPointsChanged: (points) {     // 绘图点变化回调
              setState(() {
                drawingPoints = points;
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
                          drawingPoints.clear();
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
          color: selectedTool == tool ? Colors.blue : Colors.grey,  // 选中状态显示蓝色
        ),
        onPressed: () {
          setState(() {
            selectedTool = tool;                   // 更新选中的工具
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
          selectedColor = color;                   // 更新选中的颜色
        });
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color ? Colors.white : Colors.grey,  // 选中状态显示白色边框
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
          selectedSize = size;                     // 更新选中的大小
        });
      },
      style: TextButton.styleFrom(
        backgroundColor: selectedSize == size ? Colors.blue : Colors.grey[300],
        foregroundColor: selectedSize == size ? Colors.white : Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(label),
    );
  }
} 