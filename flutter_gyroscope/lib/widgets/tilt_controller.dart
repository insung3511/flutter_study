// lib/widgets/tilt_controller.dart
import 'dart:async'; // StreamSubscription 사용
import 'package:sensors_plus/sensors_plus.dart'; // 자이로 센서 데이터 스트림

typedef OnTiltCallback = void Function(double tiltX, double tiltY);

class TiltController {
  final OnTiltCallback onTilt;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  TiltController({required this.onTilt});

  void start() {
    // 가속도계 데이터 스트림 구독
    _accelerometerSubscription = accelerometerEventStream(samplingPeriod: SensorInterval.uiInterval)
        .listen((AccelerometerEvent event) {
      // x, y 축 기울기 값 (중력 가속도 영향 포함)
      // 디바이스를 기울일 때 값을 onTilt 콜백으로 전달
      onTilt(event.x, event.y);
    });
  }

  void stop() {
    // 스트림 구독 해제 (리소스 정리)
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }
}