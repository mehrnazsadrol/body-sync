import 'package:flutter/material.dart';

class CustomGridBackground extends StatelessWidget {
  final double width;
  final double height;
  final List<Color> colors;
  final int gridSize;

  const CustomGridBackground({
    Key? key,
    required this.width,
    required this.height,
    required this.colors,
    this.gridSize = 20, // Default size of each grid square
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: GridPainter(gridSize: gridSize, colors: colors),
    );
  }
}

class GridPainter extends CustomPainter {
  final int gridSize;
  final List<Color> colors;

  GridPainter({required this.gridSize, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    int numberOfColors = colors.length;
    double sectionHeight = size.height / (numberOfColors - 1);

    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        final color = _getShade(y, sectionHeight);

        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(x, y, gridSize.toDouble(), gridSize.toDouble()),
          paint,
        );

        // Draw white vertical lines on the borders
        final borderPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

        canvas.drawLine(Offset(x, y), Offset(x, y + gridSize), borderPaint);
        canvas.drawLine(Offset(x + gridSize, y), Offset(x + gridSize, y + gridSize), borderPaint);

        // Draw horizontal lines with shadow effect
        final shadowPaint = Paint()
          ..color = _getDarkerShade(color, 4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2); // Shadow effect

        canvas.drawLine(Offset(x, y), Offset(x + gridSize, y), shadowPaint);
        canvas.drawLine(Offset(x, y + gridSize), Offset(x + gridSize, y + gridSize), shadowPaint);
      }
    }
  }

  Color _getShade(double y, double sectionHeight) {
    int sectionIndex = (y / sectionHeight).floor();
    double sectionFactor = (y % sectionHeight) / sectionHeight;

    if (sectionIndex >= colors.length - 1) {
      return colors.last;
    } else {
      return Color.lerp(colors[sectionIndex], colors[sectionIndex + 1], sectionFactor)!;
    }
  }

  Color _getDarkerShade(Color color, int degrees) {
    final hslColor = HSLColor.fromColor(color);
    final darkerHslColor = hslColor.withLightness(
      (hslColor.lightness - (degrees / 100)).clamp(0.0, 1.0),
    );
    return darkerHslColor.toColor();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
