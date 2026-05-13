import 'package:brainforge/domain/entities/child_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = ChildProfile(
    id: 'child-1',
    displayName: 'Alex',
    ageRange: AgeRange.ages9to11,
    activeMode: AppMode.school,
    totalXp: 120,
  );

  group('ChildProfile', () {
    test('copyWith preserves unchanged fields', () {
      final updated = profile.copyWith(totalXp: 200);
      expect(updated.id, profile.id);
      expect(updated.displayName, profile.displayName);
      expect(updated.totalXp, 200);
    });

    test('copyWith can switch activeMode', () {
      final summer = profile.copyWith(activeMode: AppMode.summer);
      expect(summer.activeMode, AppMode.summer);
      expect(summer.id, profile.id);
    });

    test('equality holds for identical values', () {
      const duplicate = ChildProfile(
        id: 'child-1',
        displayName: 'Alex',
        ageRange: AgeRange.ages9to11,
        activeMode: AppMode.school,
        totalXp: 120,
      );
      expect(profile, equals(duplicate));
    });

    test('equality fails when xp differs', () {
      final different = profile.copyWith(totalXp: 999);
      expect(profile, isNot(equals(different)));
    });

    test('avatarAssetPath defaults to null', () {
      expect(profile.avatarAssetPath, isNull);
    });
  });
}
