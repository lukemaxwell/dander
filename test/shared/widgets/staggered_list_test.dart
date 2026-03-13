import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dander/shared/widgets/staggered_list.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('StaggeredList — rendering', () {
    testWidgets('renders without throwing with empty list', (tester) async {
      await tester.pumpWidget(_wrap(
        const StaggeredList(children: []),
      ));
      expect(find.byType(StaggeredList), findsOneWidget);
    });

    testWidgets('renders all children', (tester) async {
      await tester.pumpWidget(_wrap(
        const StaggeredList(children: [
          Text('item1'),
          Text('item2'),
          Text('item3'),
        ]),
      ));
      expect(find.text('item1'), findsOneWidget);
      expect(find.text('item2'), findsOneWidget);
      expect(find.text('item3'), findsOneWidget);
    });

    testWidgets('wraps children in FadeTransition for animation', (tester) async {
      await tester.pumpWidget(_wrap(
        const StaggeredList(children: [
          SizedBox(),
          SizedBox(),
        ]),
      ));
      expect(find.byType(FadeTransition), findsAtLeastNWidgets(2));
    });

    testWidgets('wraps children in SlideTransition', (tester) async {
      await tester.pumpWidget(_wrap(
        const StaggeredList(children: [
          SizedBox(),
        ]),
      ));
      expect(find.byType(SlideTransition), findsAtLeastNWidgets(1));
    });
  });

  group('StaggeredList — animation', () {
    testWidgets('children are fully visible after animation completes',
        (tester) async {
      await tester.pumpWidget(_wrap(
        const StaggeredList(children: [
          Text('a'),
          Text('b'),
        ]),
      ));
      await tester.pumpAndSettle();
      expect(find.text('a'), findsOneWidget);
      expect(find.text('b'), findsOneWidget);
    });

    testWidgets('accepts custom stagger delay', (tester) async {
      await tester.pumpWidget(_wrap(
        const StaggeredList(
          staggerDelay: Duration(milliseconds: 50),
          children: [Text('x'), Text('y')],
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('x'), findsOneWidget);
    });
  });
}
