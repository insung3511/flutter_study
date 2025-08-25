// ball_physics.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 공의 속도 상태를 명확하게 관리하기 위한 열거형(enum)
enum BallSpeed { slow, normal }

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

  // 내부 속도 상태와 각 상태에 대한 가속도 값 정의
  BallSpeed _currentSpeed = BallSpeed.normal;
  static const double _slowAccelFactor = 150.0;
  static const double _normalAccelFactor = 500.0;

  // 외부에서 현재 속도 상태를 읽을 수 있도록 getter 추가
  BallSpeed get currentSpeed => _currentSpeed;

  // 현재 속도 상태에 맞는 가속도 계수를 반환하는 내부 getter
  double get _accelFactor {
    return _currentSpeed == BallSpeed.normal ? _normalAccelFactor : _slowAccelFactor;
  }

  void toggleSpeed() {
    // 상태를 토글합니다.
    if (_currentSpeed == BallSpeed.normal) {
      _currentSpeed = BallSpeed.slow;
      debugPrint("Ball speed set to SLOW");
    } else {
      _currentSpeed = BallSpeed.normal;
      debugPrint("Ball speed set to NORMAL");
    }
    HapticFeedback.lightImpact(); // 탭에 대한 진동 피드백 추가
    notifyListeners(); // UI(토글 버튼 아이콘)가 즉시 업데이트되도록 알림
  }

  void updateFromTilt(double tiltX, double tiltY) {
    ax = tiltX * _accelFactor;
    ay = -tiltY * _accelFactor; // invert Y so it matches screen
  }

  void tick(double deltaTime) {
    // 가속도 적용
    // 틸트로 인한 가속도와 중력 가속도를 함께 적용합니다.
    vx += ax * deltaTime;
    // Y축 가속도 = 틸트 가속도 + 중력
    vy += (ay + gravity) * deltaTime;

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
      HapticFeedback.mediumImpact();
    }
    if (x > screenSize.width - radius) {
      x = screenSize.width - radius;
      vx = -vx * 0.5; // 튕김 효과
      HapticFeedback.mediumImpact();
    }
    if (y < radius) {
      y = radius;
      vy = -vy * 0.4; // 위쪽 벽에 튕기는 효과 추가
      HapticFeedback.lightImpact();
    }
    if (y > screenSize.height - radius) {
      y = screenSize.height - radius;
      vy = -vy * 0.4; // 아래쪽 벽에 튕기는 효과 추가
      HapticFeedback.lightImpact();
    }

    notifyListeners();
  }
}
