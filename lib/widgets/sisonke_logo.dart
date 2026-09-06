import 'package:flutter/material.dart';
import '../core/brand.dart';

class SisonkeLogo extends StatelessWidget {
  final double size;
  final bool showWordmark;
  const SisonkeLogo({super.key, this.size = 52, this.showWordmark = true});

  @override
  Widget build(BuildContext context) {
    final mark = SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
    if (!showWordmark) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        const SizedBox(width: 10),
        Text(
          'Sisonke',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: size * .48,
                letterSpacing: -.7,
              ),
        ),
      ],
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paints = [
      Paint()..color = SisonkeColors.green,
      Paint()..color = SisonkeColors.gold,
      Paint()..color = SisonkeColors.red,
      Paint()..color = SisonkeColors.blue,
      Paint()..color = SisonkeColors.black,
    ];

    final paths = <Path>[
      Path()
        ..moveTo(w*.10,h*.84)..lineTo(w*.30,h*.28)..lineTo(w*.42,h*.84)..close(),
      Path()
        ..moveTo(w*.26,h*.84)..lineTo(w*.43,h*.12)..lineTo(w*.56,h*.84)..close(),
      Path()
        ..moveTo(w*.43,h*.84)..lineTo(w*.58,h*.22)..lineTo(w*.70,h*.84)..close(),
      Path()
        ..moveTo(w*.58,h*.84)..lineTo(w*.74,h*.34)..lineTo(w*.90,h*.84)..close(),
      Path()
        ..moveTo(w*.36,h*.92)..lineTo(w*.50,h*.50)..lineTo(w*.64,h*.92)..close(),
    ];
    for (var i=0; i<paths.length; i++) {
      canvas.drawPath(paths[i], paints[i]);
    }
    canvas.drawCircle(Offset(w*.5,h*.16), w*.08, Paint()..color=SisonkeColors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
