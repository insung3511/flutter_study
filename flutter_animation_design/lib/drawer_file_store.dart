import 'dart:math';
import 'package:flutter/material.dart';

class DrawerFileStore {
  static List<Map<String, dynamic>> generateFileData(int count) {
    final random = Random();
    return List.generate(count, (index) {
      final label = String.fromCharCode(65 + index % 26);
      final color = Color.fromRGBO(
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
        1,
      );
      return {
        'label': label,
        'color': color,
      };
    });
  }
}
