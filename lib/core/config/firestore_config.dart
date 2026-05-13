import 'package:cloud_firestore/cloud_firestore.dart';

const _kCacheSizeBytes = 100 * 1024 * 1024; // 100 MB

/// Must be called once before any Firestore reads or writes.
///
/// Enables offline persistence so quests, progress, and session data
/// remain accessible without a network connection.
Future<void> configureFirestore() async {
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: _kCacheSizeBytes,
  );
}
