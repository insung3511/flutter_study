// lib/widgets/liquid_glass_ball.dart
import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

class LiquidGlassBall extends StatelessWidget {
  final double x;
  final double y;
  final double radius;
  final LiquidGlassSettings settings;

  const LiquidGlassBall({
    super.key,
    required this.x,
    required this.y,
    required this.radius,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: x - radius,
      top: y - radius,
      width: radius * 2,
      height: radius * 2,
      child: LiquidGlass.inLayer(
        shape: LiquidRoundedSuperellipse(
          borderRadius: Radius.circular(radius * 2),
        ),
        child: Glassify(
          settings: settings.copyWith(
            blur: 1,
            thickness: 10,
            chromaticAberration: 0.9,
            glassColor: const Color(0x3FA9A4FC), // 공의 유리 색상
          ),
          child: Container(
            // ⭐ 이 줄을 제거하세요! 'color' 속성 직접 지정 제거
            // color: Colors.transparent,
            clipBehavior: Clip.antiAlias,
            decoration: ShapeDecoration(
              // ⭐ Container의 색상은 decoration 안에서 지정
              color: Colors.transparent, // 컨테이너 자체의 배경색은 투명하게 유지
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius * 2),
              ),
              shadows: const [
                BoxShadow(
                  color: Color(0x3F000000),
                  blurRadius: 18.50,
                  offset: Offset(0, 4),
                  spreadRadius: -4,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}