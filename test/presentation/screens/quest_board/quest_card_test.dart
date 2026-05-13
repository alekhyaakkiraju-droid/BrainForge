import 'package:brainforge/data/models/quest_model.dart';
import 'package:brainforge/domain/auth/auth_state.dart';
import 'package:brainforge/presentation/screens/quest_board/quest_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

QuestModel _quest({
  String id = 'q-1',
  String status = 'active',
  String subject = 'math',
  int xpReward = 50,
}) =>
    QuestModel(
      id: id,
      assignedToProfileId: 'child-1',
      title: 'Solve equations',
      description: 'Algebra practice',
      subject: subject,
      durationMinutes: 10,
      xpReward: xpReward,
      status: status,
      timeOfDay: 'morning',
      createdAt: DateTime(2026),
    );

AuthStateNotifier _stubAuth(Ref ref) {
  final auth = MockFirebaseAuth();
  final firestore = MockFirebaseFirestore();
  // ignore: unnecessary_lambdas
  when(() => auth.authStateChanges()).thenAnswer((_) => const Stream.empty());
  final notifier = AuthStateNotifier(auth, firestore);
  notifier.state = const AuthState(
    status: AuthStatus.authenticated,
    role: UserRole.student,
    uid: 'child-1',
  );
  return notifier;
}

Widget _wrap(Widget child) => ProviderScope(
      overrides: [authStateProvider.overrideWith(_stubAuth)],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  testWidgets('active quest renders title and XP badge', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      _wrap(
        QuestCard(quest: _quest(), onTap: () => tapped = true),
      ),
    );
    expect(find.text('Solve equations'), findsOneWidget);
    expect(find.textContaining('+50'), findsOneWidget);
  });

  testWidgets('active quest is tappable', (tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      _wrap(QuestCard(quest: _quest(), onTap: () => tapped = true)),
    );
    await tester.tap(find.byType(QuestCard));
    expect(tapped, isTrue);
  });

  testWidgets('completed quest shows check icon', (tester) async {
    await tester.pumpWidget(
      _wrap(
        QuestCard(
          quest: _quest(status: 'completed'),
          onTap: () {},
        ),
      ),
    );
    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
  });

  testWidgets('pending quest is wrapped in Opacity', (tester) async {
    await tester.pumpWidget(
      _wrap(
        QuestCard(quest: _quest(status: 'pending'), onTap: null),
      ),
    );
    final opacity = tester.widget<Opacity>(find.byType(Opacity).first);
    expect(opacity.opacity, lessThan(1.0));
  });

  testWidgets('touch target is at least 48dp tall', (tester) async {
    await tester.pumpWidget(
      _wrap(QuestCard(quest: _quest(), onTap: () {})),
    );
    final box = tester.renderObject<RenderBox>(find.byType(QuestCard));
    expect(box.size.height, greaterThanOrEqualTo(48));
  });
}
