import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:dander/core/quiz/quiz_result.dart';
import 'package:dander/core/quiz/quiz_session.dart';
import 'package:dander/core/quiz/street_memory_record.dart';
import 'package:dander/core/streets/street.dart';

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

Street _street(String id, String name) => Street(
      id: id,
      name: name,
      nodes: const [LatLng(51.5, -0.1)],
      walkedAt: DateTime(2024, 1, 1),
    );

List<Street> _streets(int count) => List.generate(
      count,
      (i) => _street('way/$i', 'Street $i'),
    );

List<StreetMemoryRecord> _emptyRecords() => [];

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuizSession', () {
    group('QuizSession.create', () {
      test('creates a session with questions from walked streets', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        expect(session.questions, isNotEmpty);
      });

      test('creates at most one question per street', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        final ids = session.questions.map((q) => q.targetStreet.id).toSet();
        expect(ids.length, equals(session.questions.length));
      });

      test('each question has exactly 4 choices', () {
        final streets = _streets(8);
        final session = QuizSession.create(streets, _emptyRecords());
        for (final q in session.questions) {
          expect(q.choices, hasLength(4));
        }
      });

      test('target street is always one of the choices', () {
        final streets = _streets(8);
        final session = QuizSession.create(streets, _emptyRecords());
        for (final q in session.questions) {
          expect(q.choices.any((c) => c.id == q.targetStreet.id), isTrue);
        }
      });

      test('correctIndex points to target street in choices', () {
        final streets = _streets(8);
        final session = QuizSession.create(streets, _emptyRecords());
        for (final q in session.questions) {
          expect(q.choices[q.correctIndex].id, equals(q.targetStreet.id));
        }
      });

      test('starts at index 0', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        expect(session.currentIndex, equals(0));
      });

      test('starts with correctCount 0', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        expect(session.correctCount, equals(0));
      });

      test('isComplete is false when session just created', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        expect(session.isComplete, isFalse);
      });

      test('with fewer than 4 streets uses all as choices', () {
        final streets = _streets(3);
        final session = QuizSession.create(streets, _emptyRecords());
        for (final q in session.questions) {
          // choices may be <= 3 when fewer streets available
          expect(q.choices.length, lessThanOrEqualTo(4));
          expect(q.choices.any((c) => c.id == q.targetStreet.id), isTrue);
        }
      });
    });

    group('currentQuestion', () {
      test('returns first question at start', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        expect(session.currentQuestion, equals(session.questions.first));
      });
    });

    group('answerCurrent', () {
      test('advances currentIndex by 1', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        final updated = session.answerCurrent(QuizResult.correct);
        expect(updated.currentIndex, equals(1));
      });

      test('increments correctCount on correct answer', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        final updated = session.answerCurrent(QuizResult.correct);
        expect(updated.correctCount, equals(1));
      });

      test('does not increment correctCount on incorrect answer', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        final updated = session.answerCurrent(QuizResult.incorrect);
        expect(updated.correctCount, equals(0));
      });

      test('original session is unchanged after answerCurrent', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        session.answerCurrent(QuizResult.correct);
        expect(session.currentIndex, equals(0));
        expect(session.correctCount, equals(0));
      });

      test('isComplete becomes true after answering all questions', () {
        final streets = _streets(4);
        var session = QuizSession.create(streets, _emptyRecords());
        for (var i = 0; i < session.questions.length; i++) {
          session = session.answerCurrent(QuizResult.correct);
        }
        expect(session.isComplete, isTrue);
      });

      test('correctly tracks mixed correct and incorrect answers', () {
        final streets = _streets(6);
        var session = QuizSession.create(streets, _emptyRecords());
        session = session.answerCurrent(QuizResult.correct);
        session = session.answerCurrent(QuizResult.incorrect);
        session = session.answerCurrent(QuizResult.correct);
        expect(session.correctCount, equals(2));
        expect(session.currentIndex, equals(3));
      });
    });

    group('isComplete', () {
      test('returns false when questions remain', () {
        final streets = _streets(4);
        final session = QuizSession.create(streets, _emptyRecords());
        expect(session.isComplete, isFalse);
      });

      test('returns true when currentIndex equals question count', () {
        final streets = _streets(1);
        final session = QuizSession.create(streets, _emptyRecords());
        final completed = session.answerCurrent(QuizResult.correct);
        expect(completed.isComplete, isTrue);
      });
    });
  });
}
