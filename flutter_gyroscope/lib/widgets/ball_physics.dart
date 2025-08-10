// ball_physics.dart
import 'package:flutter/material.dart';

class BallPhysics extends ChangeNotifier {
  double x;
  double y;
  final double radius;
  final Size screenSize;

  double vx = 0; // velocity X
  double vy = 0; // velocity Y

  double ax = 0; // acceleration X
  double ay = 0; // acceleration Y

  final double gravity = 9.81 * 100; // 중력 가속도 추가 (픽셀 단위로 스케일링)

  BallPhysics({
    required this.radius,
    required this.screenSize,
  })  : x = screenSize.width / 2,
        y = screenSize.height / 2;

  void updateFromTilt(double tiltX, double tiltY) {
    // Tilt is proportional to acceleration
    double accelFactor = 500; // adjust sensitivity
    ax = tiltX * accelFactor;
    ay = -tiltY * accelFactor; // invert Y so it matches screen
  }

  void tick(double deltaTime) {
    // 중력 가속도를 ay에 항상 더해줍니다.
    ay += gravity * deltaTime; // deltaTime을 곱하여 시간에 비례하게 적용

    // Apply acceleration
    vx += ax * deltaTime;
    vy += ay * deltaTime;

    // Apply damping (friction in liquid)
    // 댐핑 값을 0.98 정도로 조절하여 자연스러운 마찰 효과를 줍니다.
    double damping = 0.98;
    vx *= damping;
    vy *= damping;

    // Update position
    x += vx * deltaTime;
    y += vy * deltaTime;

    // Clamp so ball doesn't leave screen
    // 화면 경계에 부딪혔을 때 속도를 반전시켜 튕기는 효과를 줍니다.
    if (x < radius) {
      x = radius;
      vx = -vx * 0.5; // 튕김 효과 (0.5는 탄성 계수)
    }
    if (x > screenSize.width - radius) {
      x = screenSize.width - radius;
      vx = -vx * 0.5; // 튕김 효과
    }
    if (y < radius) {
      y = radius;
      vy = 0;
    }
    if (y > screenSize.height - radius) {
      y = screenSize.height - radius;
      vy = 0;
    }

    notifyListeners();
  }
}
