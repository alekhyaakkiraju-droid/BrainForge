import '../../data/models/mood_entry_model.dart';

abstract interface class MoodEntryRepository {
  Future<MoodEntryModel?> getById(String id);
  Future<List<MoodEntryModel>> getByProfileId(
    String profileId, {
    int limit = 30,
  });
  Future<void> save(MoodEntryModel entry);
  Future<void> delete(String id);
}
