import 'package:flutter/material.dart';

class HexagonAvatar extends StatelessWidget {
  final String avatarUrl;
  final double size;
  final Color borderColor;
  final double borderWidth;
  final bool isOnline;
  final bool isVerified;
  final double? verifiedSize;
  final String? profileBadgeColor;

  const HexagonAvatar({
    super.key,
    required this.avatarUrl,
    this.size = 40.0,
    this.borderColor = const Color(0xFF615DFA),
    this.borderWidth = 2.0,
    this.isOnline = false,
    this.isVerified = false,
    this.verifiedSize,
    this.profileBadgeColor,
  });

  Color _parseHexColor(String hexStr, Color fallback) {
    if (hexStr.isEmpty) return fallback;
    try {
      final buffer = StringBuffer();
      if (hexStr.length == 6 || hexStr.length == 7) buffer.write('ff');
      buffer.write(hexStr.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = size;
    final h = size * 1.08;
    
    final borderCol = (profileBadgeColor != null && profileBadgeColor!.isNotEmpty)
        ? _parseHexColor(profileBadgeColor!, borderColor)
        : borderColor;

    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Hexagon Border
          CustomPaint(
            size: Size(w, h),
            painter: HexagonBorderPainter(
              color: borderCol,
              strokeWidth: borderWidth,
            ),
          ),
          
          // Hexagon Image
          ClipPath(
            clipper: HexagonClipper(),
            child: Container(
              width: w - (borderWidth * 2),
              height: h - (borderWidth * 2),
              color: Colors.grey[800],
              child: avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.white),
                    )
                  : const Icon(Icons.person, color: Colors.white),
            ),
          ),

          // Online status dot
          if (isOnline)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: size * 0.16,
                height: size * 0.16,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
            ),

          // Verified Badge
          if (isVerified)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(1.5),
                decoration: const BoxDecoration(
                  color: Color(0xFF00B2FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: verifiedSize ?? (size * 0.2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w / 2, 0);
    path.lineTo(w, h / 4);
    path.lineTo(w, 3 * h / 4);
    path.lineTo(w / 2, h);
    path.lineTo(0, 3 * h / 4);
    path.lineTo(0, h / 4);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class HexagonBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  HexagonBorderPainter({required this.color, this.strokeWidth = 2.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final w = size.width;
    final h = size.height;
    path.moveTo(w / 2, 0);
    path.lineTo(w, h / 4);
    path.lineTo(w, 3 * h / 4);
    path.lineTo(w / 2, h);
    path.lineTo(0, 3 * h / 4);
    path.lineTo(0, h / 4);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
