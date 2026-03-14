import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dander/core/motion/dander_motion.dart';

Widget _withMotion(Widget child, {required bool reduced}) {
  return MaterialApp(
    home: Scaffold(
      body: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: child,
      ),
    ),
  );
}

void main() {
  group('DanderMotion.isReduced', () {
    testWidgets('returns false when disableAnimations is false', (tester) async {
      late bool result;
      await tester.pumpWidget(_withMotion(
        Builder(builder: (context) {
          result = DanderMotion.isReduced(context);
          return const SizedBox();
        }),
        reduced: false,
      ));
      expect(result, isFalse);
    });

    testWidgets('returns true when disableAnimations is true', (tester) async {
      late bool result;
      await tester.pumpWidget(_withMotion(
        Builder(builder: (context) {
          result = DanderMotion.isReduced(context);
          return const SizedBox();
        }),
        reduced: true,
      ));
      expect(result, isTrue);
    });

    testWidgets('reads from nearest MediaQuery ancestor', (tester) async {
      // Outer MediaQuery says reduced=false, inner says reduced=true
      late bool result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(disableAnimations: false),
            child: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Builder(builder: (context) {
                result = DanderMotion.isReduced(context);
                return const SizedBox();
              }),
            ),
          ),
        ),
      ));
      expect(result, isTrue);
    });
  });
}
