import 'package:flutter/widgets.dart';

class BSIcon extends StatelessWidget {
  final String name;
  final double size;
  final double stroke;
  final Color color;

  const BSIcon(
    this.name, {
    super.key,
    this.size = 22,
    this.stroke = 1.7,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BSIconPainter(name: name, stroke: stroke, color: color),
    );
  }
}

class _IconDef {
  final List<String> paths;
  final List<List<double>> circles;
  const _IconDef(this.paths, [this.circles = const []]);
}

const Map<String, _IconDef> _icons = {
  'today': _IconDef(['M3.4 5.6h17.2v15H3.4zM3.4 10.2h17.2M8 14.6h3.4v3.2H8z']),
  'food': _IconDef([
    'M6.5 3v6.4a2.8 2.8 0 0 0 5.6 0V3M9.3 12.2V21M17 3c1.9 0 2.9 2 2.9 5s-1.2 3.8-1.2 5.2V21'
  ]),
  'body': _IconDef([
    'M12 8.2v6.2M8.2 10.6h7.6M9.6 21l2.4-6.4 2.4 6.4'
  ], [
    [12, 5.4, 2.4]
  ]),
  'workout': _IconDef(['M2.6 9.6h3.4v4.8H2.6zM18 9.6h3.4v4.8H18zM6 12h12']),
  'plus': _IconDef(['M12 5v14M5 12h14']),
  'minus': _IconDef(['M5 12h14']),
  'chevronRight': _IconDef(['M9.5 6.5l5.5 5.5-5.5 5.5']),
  'chevronLeft': _IconDef(['M14.5 6.5L9 12l5.5 5.5']),
  'chevronDown': _IconDef(['M6.5 9.5l5.5 5.5 5.5-5.5']),
  'close': _IconDef(['M6.5 6.5l11 11M17.5 6.5l-11 11']),
  'search': _IconDef([
    'M16.2 16.2l4.3 4.3'
  ], [
    [11, 11, 6.6]
  ]),
  'bell': _IconDef([
    'M12 3.4a5.4 5.4 0 0 0-5.4 5.4c0 4.4-1.6 5.8-1.6 5.8h14s-1.6-1.4-1.6-5.8A5.4 5.4 0 0 0 12 3.4zM10.2 18.2a2 2 0 0 0 3.6 0'
  ]),
  'settings': _IconDef([
    'M4 8h16M4 16h16'
  ], [
    [10, 8, 2.2],
    [15, 16, 2.2]
  ]),
  'calendar': _IconDef(['M3.4 5.6h17.2v15H3.4zM3.4 10.2h17.2M8 3v4M16 3v4']),
  'check': _IconDef(['M5 12.6l4.6 4.4L19 7.4']),
  'trash': _IconDef(['M4.2 7h15.6M9 7V4.6h6V7M6.6 7l1 13.4h8.8L17.4 7']),
  'edit': _IconDef(['M4 20h4L19 9l-4-4L4 16z']),
  'undo': _IconDef(['M4.2 5v5.4h5.4M4.6 10.4A8 8 0 1 1 6 17.6']),
  'clock': _IconDef([
    'M12 7.4V12l3.2 2.1'
  ], [
    [12, 12, 8.6]
  ]),
  'target': _IconDef([
    'M12 8.4V5.8M12 18.2v-2.6M8.4 12H5.8M18.2 12h-2.6'
  ], [
    [12, 12, 6.4],
    [12, 12, 1.6]
  ]),
  'ruler': _IconDef(
      ['M3.5 9.2l5.7-5.7 11.3 11.3-5.7 5.7zM8 8.6l1.8 1.8M11.4 12l1.8 1.8']),
  'scale':
      _IconDef(['M4.6 20.4h14.8V9.6H4.6zM9 6.2h6M12 6.2V3.4M9.4 14.6h5.2']),
  'flag': _IconDef(['M6 21V4h11l-1.6 4L17 12H6']),
  'info': _IconDef([
    'M12 11v5.4M12 7.6v.4'
  ], [
    [12, 12, 8.6]
  ]),
  'backspace':
      _IconDef(['M9 5.5h11v13H9L3.5 12z', 'M11.5 9.5l5 5M16.5 9.5l-5 5']),
};

class _BSIconPainter extends CustomPainter {
  final String name;
  final double stroke;
  final Color color;

  _BSIconPainter(
      {required this.name, required this.stroke, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final def = _icons[name];
    if (def == null) return;
    final scale = size.width / 24;
    canvas.scale(scale);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = color;
    for (final d in def.paths) {
      canvas.drawPath(_parseSvgPath(d), paint);
    }
    for (final c in def.circles) {
      canvas.drawCircle(Offset(c[0], c[1]), c[2], paint);
    }
  }

  @override
  bool shouldRepaint(_BSIconPainter old) =>
      old.name != name || old.stroke != stroke || old.color != color;
}

Path _parseSvgPath(String d) {
  final path = Path();
  final re = RegExp(r'([MmLlHhVvCcSsAaZz])|(-?\d*\.?\d+)');
  final tokens = re.allMatches(d).toList();
  int i = 0;
  String cmd = '';
  double cx = 0, cy = 0;
  double sx = 0, sy = 0;
  double pcx = 0, pcy = 0;
  bool prevCubic = false;

  double next() => double.parse(tokens[i++].group(2)!);

  while (i < tokens.length) {
    final t = tokens[i];
    if (t.group(1) != null) {
      cmd = t.group(1)!;
      i++;
      if (cmd == 'Z' || cmd == 'z') {
        path.close();
        cx = sx;
        cy = sy;
        prevCubic = false;
        continue;
      }
    } else if (cmd == 'M') {
      cmd = 'L';
    } else if (cmd == 'm') {
      cmd = 'l';
    }

    switch (cmd) {
      case 'M':
        cx = next();
        cy = next();
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        prevCubic = false;
        break;
      case 'm':
        cx += next();
        cy += next();
        path.moveTo(cx, cy);
        sx = cx;
        sy = cy;
        prevCubic = false;
        break;
      case 'L':
        cx = next();
        cy = next();
        path.lineTo(cx, cy);
        prevCubic = false;
        break;
      case 'l':
        cx += next();
        cy += next();
        path.lineTo(cx, cy);
        prevCubic = false;
        break;
      case 'H':
        cx = next();
        path.lineTo(cx, cy);
        prevCubic = false;
        break;
      case 'h':
        cx += next();
        path.lineTo(cx, cy);
        prevCubic = false;
        break;
      case 'V':
        cy = next();
        path.lineTo(cx, cy);
        prevCubic = false;
        break;
      case 'v':
        cy += next();
        path.lineTo(cx, cy);
        prevCubic = false;
        break;
      case 'C':
      case 'c':
        final rel = cmd == 'c';
        final x1 = (rel ? cx : 0) + next();
        final y1 = (rel ? cy : 0) + next();
        final x2 = (rel ? cx : 0) + next();
        final y2 = (rel ? cy : 0) + next();
        final x = (rel ? cx : 0) + next();
        final y = (rel ? cy : 0) + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        pcx = x2;
        pcy = y2;
        cx = x;
        cy = y;
        prevCubic = true;
        break;
      case 'S':
      case 's':
        final rel = cmd == 's';
        final x1 = prevCubic ? 2 * cx - pcx : cx;
        final y1 = prevCubic ? 2 * cy - pcy : cy;
        final x2 = (rel ? cx : 0) + next();
        final y2 = (rel ? cy : 0) + next();
        final x = (rel ? cx : 0) + next();
        final y = (rel ? cy : 0) + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        pcx = x2;
        pcy = y2;
        cx = x;
        cy = y;
        prevCubic = true;
        break;
      case 'A':
      case 'a':
        final rel = cmd == 'a';
        final rx = next();
        final ry = next();
        final rot = next();
        final largeArc = next() != 0;
        final sweep = next() != 0;
        final x = (rel ? cx : 0) + next();
        final y = (rel ? cy : 0) + next();
        path.arcToPoint(
          Offset(x, y),
          radius: Radius.elliptical(rx, ry),
          rotation: rot,
          largeArc: largeArc,
          clockwise: sweep,
        );
        cx = x;
        cy = y;
        prevCubic = false;
        break;
      default:
        i++;
    }
  }
  return path;
}
