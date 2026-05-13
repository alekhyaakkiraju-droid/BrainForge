import 'package:brainforge/data/services/audit_logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ignore: avoid_implementing_value_types
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

void main() {
  late MockFirebaseFirestore mockFirestore;
  late MockCollectionReference mockCollection;
  late MockDocumentReference mockDoc;
  late AuditLogger logger;

  setUp(() {
    mockFirestore = MockFirebaseFirestore();
    mockCollection = MockCollectionReference();
    mockDoc = MockDocumentReference();

    when(() => mockFirestore.collection('auditLogs'))
        .thenReturn(mockCollection);
    when(() => mockCollection.doc()).thenReturn(mockDoc);
    when(() => mockDoc.id).thenReturn('test-log-id');
    // ignore: unnecessary_lambdas
    when(
      () => mockDoc.set(
        any(),
      ),
    ).thenAnswer((_) async {});

    logger = AuditLogger(mockFirestore);
  });

  test('log() writes to auditLogs collection', () async {
    await logger.log(
      actor: 'user-1',
      resource: 'users/user-1',
      operation: AuditOperation.login,
    );

    verify(() => mockFirestore.collection('auditLogs')).called(1);
    verify(() => mockCollection.doc()).called(1);
    verify(() => mockDoc.set(any())).called(1);
  });

  test('log() includes required fields in the document', () async {
    Map<String, dynamic>? written;
    when(() => mockDoc.set(any())).thenAnswer((invocation) async {
      written = invocation.positionalArguments.first as Map<String, dynamic>;
    });

    await logger.log(
      actor: 'parent-uid',
      resource: 'users/child-uid',
      operation: AuditOperation.childDataDeleted,
      details: {'requestId': 'req-1'},
    );

    expect(written, isNotNull);
    expect(written!['actor'], 'parent-uid');
    expect(written!['resource'], 'users/child-uid');
    expect(written!['operation'], 'childDataDeleted');
    expect(written!['details'], {'requestId': 'req-1'});
    // timestamp is a FieldValue.serverTimestamp() — just verify key present.
    expect(written!.containsKey('timestamp'), isTrue);
  });

  test('log() defaults details to empty map when not provided', () async {
    Map<String, dynamic>? written;
    when(() => mockDoc.set(any())).thenAnswer((invocation) async {
      written = invocation.positionalArguments.first as Map<String, dynamic>;
    });

    await logger.log(
      actor: 'user-1',
      resource: 'users/user-1',
      operation: AuditOperation.create,
    );

    expect(written!['details'], isEmpty);
  });

  test('log() returns the generated document ID', () async {
    final id = await logger.log(
      actor: 'user-1',
      resource: 'users/user-1',
      operation: AuditOperation.logout,
    );
    expect(id, 'test-log-id');
  });
}
