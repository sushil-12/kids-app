import 'package:brightmind_kids/src/features/adaptive/data/difficulty.dart';
import 'package:brightmind_kids/src/features/profile/data/child_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const DifficultyPolicy policy = DifficultyPolicy();

  group('updateSkill', () {
    test('a clean round raises skill, a struggle lowers it', () {
      expect(
        policy.updateSkill(0.5, struggled: false),
        closeTo(0.5 + DifficultyPolicy.cleanStep, 1e-9),
      );
      expect(
        policy.updateSkill(0.5, struggled: true),
        closeTo(0.5 - DifficultyPolicy.struggleStep, 1e-9),
      );
    });

    test('skill is clamped to the unit range', () {
      expect(policy.updateSkill(1.0, struggled: false), 1.0);
      expect(policy.updateSkill(0.0, struggled: true), 0.0);
    });

    test('clean steps outweigh struggle steps (difficulty trends up on success)',
        () {
      expect(DifficultyPolicy.cleanStep, greaterThan(DifficultyPolicy.struggleStep));
    });
  });

  group('levelFor', () {
    test('low skill is easy, mid is medium, high is hard (senior)', () {
      expect(policy.levelFor(0.0, AgeBand.senior), DifficultyLevel.easy);
      expect(policy.levelFor(0.5, AgeBand.senior), DifficultyLevel.medium);
      expect(policy.levelFor(1.0, AgeBand.senior), DifficultyLevel.hard);
    });

    test('the youngest (junior) never reach hard — it caps at medium', () {
      expect(policy.levelFor(1.0, AgeBand.junior), DifficultyLevel.medium);
      // Lower bands are untouched by the cap.
      expect(policy.levelFor(0.0, AgeBand.junior), DifficultyLevel.easy);
      expect(policy.levelFor(0.5, AgeBand.junior), DifficultyLevel.medium);
    });

    test('a few clean rounds carry a senior child from easy to hard', () {
      double skill = 0.0;
      expect(policy.levelFor(skill, AgeBand.senior), DifficultyLevel.easy);
      for (int i = 0; i < 4; i++) {
        skill = policy.updateSkill(skill, struggled: false);
      }
      expect(policy.levelFor(skill, AgeBand.senior), DifficultyLevel.hard);
    });
  });
}
