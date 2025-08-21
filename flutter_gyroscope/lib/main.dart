// lib/main.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

import 'widgets/ball_physics.dart';
import 'widgets/liquid_glass_ball.dart';
import 'widgets/tilt_controller.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: BallGameScreen(),
    );
  }
}

class BallGameScreen extends StatefulWidget {
  const BallGameScreen({super.key});

  @override
  State<BallGameScreen> createState() => _BallGameScreenState();
}

class _BallGameScreenState extends State<BallGameScreen> with SingleTickerProviderStateMixin {
  late BallPhysics physics;
  late TiltController tilt;
  late Ticker ticker;
  late double lastTime;

  LiquidGlassSettings currentBallSettings = LiquidGlassSettings(
    thickness: 10,
    blur: 5,
    chromaticAberration: 0.5,
    glassColor: const Color(0x3FA9A4FC),
    lightAngle: 0.5 * pi,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final screenSize = MediaQuery.of(context).size;
    physics = BallPhysics(radius: 60, screenSize: screenSize);

    tilt = TiltController(onTilt: (tx, ty) {
      physics.updateFromTilt(tx, ty);
    });
    tilt.start();

    lastTime = 0;
    ticker = createTicker((elapsed) {
      double currentTime = elapsed.inMilliseconds / 1000;
      double deltaTime = currentTime - lastTime;
      lastTime = currentTime;
      physics.tick(deltaTime);

      setState(() {
        currentBallSettings = currentBallSettings.copyWith(
          lightAngle: (currentTime * 0.1) % (2 * pi),
        );
      });
    })..start();
  }

  @override
  void dispose() {
    ticker.dispose();
    tilt.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String longLoremIpsum = """
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

    Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo. Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet, consectetur, adipisci velit, sed quia non numquam eius modi tempora incidunt ut labore et dolore magnam aliquam quaerat voluptatem. Ut enim ad minima veniam, quis nostrum exercitationem ullam corporis suscipit laboriosam, nisi ut aliquid ex ea commodi consequatur? Quis autem vel eum iure reprehenderit qui in ea voluptate velit esse quam nihil molestiae consequatur, vel illum qui dolorem eum fugiat quo voluptas nulla pariatur?

    At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident, similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus, omnis voluptas assumenda est, omnis dolor repellendus. Temporibus autem quibusdam et aut officiis debitis aut rerum necessitatibus saepe eveniet ut et voluptates repudiandae sint et molestiae non recusandae. Itaque earum rerum hic tenetur a sapiente delectus, ut aut reiciendis voluptatibus maiores alias consequatur aut perferendis doloribus asperiores repellat.
    """;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. SingleChildScrollView를 사용하여 텍스트 내용을 스크롤 가능하게 만듭니다.
          // 이 부분이 LiquidGlassLayer의 "배경"이 됩니다.
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 50.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ⭐⭐⭐ 기존 "LASSO" 텍스트 부분을 제거합니다. ⭐⭐⭐
                  /*
                  Text(
                    "LASSO",
                    style: GoogleFonts.lexendDeca(
                      textStyle: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  */
                  Text(
                    longLoremIpsum,
                    style: GoogleFonts.lato(
                      textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 18,
                        color: Colors.white.withOpacity(0.6),
                        height: 1.5,
                      ),
                    ),
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
          // 2. LiquidGlassLayer: 화면 전체를 덮고, 스크롤되는 텍스트를 배경으로 캡처합니다.
          SizedBox.expand(
            child: LiquidGlassLayer(
              settings: currentBallSettings,
              child: Stack(
                children: [
                  AnimatedBuilder(
                    animation: physics,
                    builder: (_, __) {
                      return LiquidGlassBall(
                        x: physics.x,
                        y: physics.y,
                        radius: physics.radius,
                        settings: currentBallSettings,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}