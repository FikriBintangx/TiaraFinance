import 'package:flutter/material.dart';

class WavyBottomBar extends StatefulWidget {
  final int selectedIndex;
  final List<IconData> items;
  final Function(int) onItemSelected;
  final Color backgroundColor;
  final Color activeColor;
  final Color inactiveColor;

  const WavyBottomBar({
    super.key,
    required this.selectedIndex,
    required this.items,
    required this.onItemSelected,
    this.backgroundColor = Colors.white,
    this.activeColor = const Color(0xFF004D40), // Dark green
    this.inactiveColor = Colors.grey,
  });

  @override
  State<WavyBottomBar> createState() => _WavyBottomBarState();
}

class _WavyBottomBarState extends State<WavyBottomBar> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width - 40; 
    final itemWidth = width / widget.items.length;

    return Container(
      height: 70,
      width: width,
      margin: const EdgeInsets.only(bottom: 10), // Lift up slightly
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.selectedIndex.toDouble()),
        duration: const Duration(milliseconds: 300),
        curve: Curves.fastOutSlowIn,
        builder: (context, animIndex, child) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // 1. Wavy Background Painter
              CustomPaint(
                size: Size(width, 70),
                painter: _WavyPainter(
                  animIndex: animIndex,
                  itemCount: widget.items.length,
                  color: widget.backgroundColor,
                ),
              ),
              
              // 2. Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: widget.items.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final icon = entry.value;
                  final isActive = idx == widget.selectedIndex;

                  return GestureDetector(
                    onTap: () => widget.onItemSelected(idx),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                       width: itemWidth,
                       height: 70,
                       child: Stack(
                         alignment: Alignment.center,
                         children: [
                           // Icon moves up when active
                           AnimatedAlign(
                             duration: const Duration(milliseconds: 300),
                             curve: Curves.easeOutBack,
                             alignment: isActive ? const Alignment(0, -0.5) : Alignment.center,
                             child: Container(
                               padding: const EdgeInsets.all(10),
                               decoration: BoxDecoration(
                                 color: isActive ? widget.activeColor : Colors.transparent,
                                 shape: BoxShape.circle,
                                 boxShadow: isActive ? [
                                    BoxShadow(color: widget.activeColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5)) 
                                 ] : null,
                               ),
                               child: Icon(
                                 icon,
                                 color: isActive ? Colors.white : widget.inactiveColor,
                                 size: 24,
                               ),
                             ),
                           ),
                         ],
                       ),
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  final double animIndex;
  final int itemCount;
  final Color color;

  _WavyPainter({
    required this.animIndex,
    required this.itemCount,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    final itemWidth = size.width / itemCount;
    final currentX = itemWidth * animIndex + itemWidth / 2;

    path.moveTo(0, 0);
    // Top line with Curve
    // We draw a curve around currentX.
    // The curve is a "dip" (concave up) because the button floats ABOVE it.
    
    final curveWidth = itemWidth * 0.8;
    final leftX = currentX - curveWidth / 2;
    final rightX = currentX + curveWidth / 2;
    
    path.lineTo(leftX - 15, 0);
    
    // Bezier curve for the dip
    path.cubicTo(
      leftX + 5, 0,    // Ctrl 1
      leftX + 5, 40,   // Ctrl 2 (Dip depth)
      currentX, 40,    // End point (Bottom of dip)
    );
    
    path.cubicTo(
      rightX - 5, 40,  // Ctrl 1
      rightX - 5, 0,   // Ctrl 2
      rightX + 15, 0,  // End point
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    // Clip rounded corners for the whole bar
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), const Radius.circular(35));
    
    // Instead of simple drawPath, we intersect or verify shape.
    // Effectively we want the "dip" on top edge, but rounded corners overall.
    // Simple way: Draw path, then intersect with RRect?
    // Or just path.addRRect? No.
    // Let's just draw the path on a canvas that is clipped to RRect.
    
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawPath(path, shadowPaint); // Shadow might need separate handling if clipped
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WavyPainter oldDelegate) {
    return oldDelegate.animIndex != animIndex;
  }
}
