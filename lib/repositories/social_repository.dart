import '../data/demo_social.dart';
import '../models/agreement.dart';
import '../models/check_in_record.dart';
import '../models/context_note.dart';
import '../models/visibility.dart';

/// Abstract repository managing family notes, agreements, visibility sharing
/// levels, and weekly check-ins.
abstract interface class SocialRepository {
  Future<SocialSeed> loadInitialData();
  Future<void> addNote(ContextNote note);
  Future<void> deleteNote(String noteId);
  Future<void> saveAgreement(Agreement agreement);
  Future<void> setVisibility(String childId, VisibilityLevel level);
  Future<void> saveCheckIn(CheckInRecord record);
}

/// In-memory demo implementation of [SocialRepository].
class DemoSocialRepository implements SocialRepository {
  DemoSocialRepository({SocialSeed? seed}) : _seed = seed ?? DemoSocial.build();

  final SocialSeed _seed;

  @override
  Future<SocialSeed> loadInitialData() async => _seed;

  @override
  Future<void> addNote(ContextNote note) async {}

  @override
  Future<void> deleteNote(String noteId) async {}

  @override
  Future<void> saveAgreement(Agreement agreement) async {}

  @override
  Future<void> setVisibility(String childId, VisibilityLevel level) async {}

  @override
  Future<void> saveCheckIn(CheckInRecord record) async {}
}
