import 'package:dirassty/core/models/homework_helper_result.dart';
import 'package:dirassty/core/models/open_exercise_body.dart';
import 'package:dirassty/core/models/open_exercise_correction.dart';
import 'package:dirassty/core/models/tutor_reply.dart';
import 'package:flutter_test/flutter_test.dart';

/// Parsing of the AI routes' JSON (apps/web/app/api/{tutor,
/// correct-open-exercise,homework-helper}) — fixtures, no network.
void main() {
  group('TutorReply', () {
    test('full solution with steps, formulas and budget left', () {
      final r = TutorReply.fromJson({
        'kind': 'solution',
        'reply': 'Méthode',
        'steps': [
          {'work': '2/4 + 1/4', 'why': 'même dénominateur'},
          {'work': '', 'why': 'ignored'},
        ],
        'formulas': ['a/c + b/c = (a+b)/c'],
        'final_answer': '3/4',
        'suggestions': ['Explique l’étape 1'],
        'ai_usage': {'pct_left': 72, 'tokens_left': 36000},
      });
      expect(r.kind, 'solution');
      expect(r.steps, hasLength(1));
      expect(r.finalAnswer, '3/4');
      expect(r.budgetLeftPct, 72);
    });

    test('hint and missing fields', () {
      final r = TutorReply.fromJson(
        {'kind': 'hint', 'reply': 'Pense au dénominateur.'},
      );
      expect(r.isHint, isTrue);
      expect(r.steps, isEmpty);
      expect(r.stepStatus, isNull);
      expect(r.budgetLeftPct, isNull);
    });

    test('history turns serialize role/kind for the server', () {
      expect(
        const TutorTurn(fromStudent: false, text: 'x', isHint: true).toJson(),
        {'role': 'tutor', 'text': 'x', 'kind': 'hint'},
      );
      expect(
        const TutorTurn(fromStudent: true, text: 'y').toJson(),
        {'role': 'student', 'text': 'y'},
      );
    });
  });

  group('OpenExerciseCorrection (answer / handwritten check)', () {
    test('arithmetic slip: reasoning right, calculation and final answer wrong',
        () {
      final c = OpenExerciseCorrection.fromJson({
        'overall': 'partially_correct',
        'score': 'partial',
        'reasoning_correct': true,
        'calculation_correct': false,
        'final_answer_correct': false,
        'method': 'official',
        'mistakes': [
          {
            'step': '2/4 + 1/4',
            'issue': '2 + 1 = 3, pas 4',
            'type': 'calculation',
          },
          {'issue': ''},
        ],
        'what_was_right': 'Bonne méthode',
        'what_was_wrong': 'Erreur de calcul',
        'correct_solution': '...',
        'encouragement': 'Presque !',
        'confidence': 0.85,
      });
      expect(c.score, CorrectionScore.partial);
      expect(c.reasoningCorrect, isTrue);
      expect(c.calculationCorrect, isFalse);
      expect(c.mistakes, hasLength(1));
      expect(c.mistakes.single.type, 'calculation');
    });

    test('unreadable photo → undetermined + retake', () {
      final c = OpenExerciseCorrection.fromJson({
        'overall': 'undetermined',
        'readability': 'unreadable',
        'image_issues': ['blurry', 'cropped'],
        'retake_photo': true,
        'confidence': 0.2,
      });
      expect(c.undetermined, isTrue);
      expect(c.retakePhoto, isTrue);
      expect(c.imageIssues, ['blurry', 'cropped']);
      expect(c.correctSolution, isEmpty);
    });

    test('alternative valid method', () {
      final c = OpenExerciseCorrection.fromJson(
        {
          'overall': 'correct',
          'method': 'alternative_valid',
          'confidence': 0.9,
        },
      );
      expect(c.score, CorrectionScore.correct);
      expect(c.method, 'alternative_valid');
    });

    test('legacy response (score only) still parses', () {
      final c = OpenExerciseCorrection.fromJson({
        'score': 'incorrect',
        'what_was_right': 'Essai',
        'what_was_wrong': 'Faux',
        'correct_solution': 'x = 3',
        'encouragement': 'Courage',
      });
      expect(c.score, CorrectionScore.incorrect);
      expect(c.reasoningCorrect, isNull);
      expect(c.retakePhoto, isFalse);
    });
  });

  group('HomeworkHelperResult', () {
    test('unreadable photo has no guessed answer', () {
      final r = HomeworkHelperResult.fromJson({
        'readable': false,
        'image_issues': ['dark'],
      });
      expect(r.readable, isFalse);
      expect(r.imageIssues, ['dark']);
      expect(r.steps, isNull);
    });

    test('readable defaults to true for older responses', () {
      final r = HomeworkHelperResult.fromJson({
        'kind': 'solve',
        'detected_subject': 'Maths',
        'detected_topic': 'Fractions',
        'steps': ['a'],
        'final_answer': '3/4',
      });
      expect(r.readable, isTrue);
      expect(r.isSolve, isTrue);
    });
  });

  test('AI follow-up exercise without its (server-side) solution parses', () {
    final b = OpenExerciseBody.fromJson({
      'question': 'Calcule 1/3 + 1/6',
      'topic': 'fractions',
      'difficulty': 'medium',
      'generated_token': 'iv.data.tag',
    });
    expect(b.question, 'Calcule 1/3 + 1/6');
    expect(b.solution, isEmpty);
  });
}
