// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'roadmap_dao.dart';

// ignore_for_file: type=lint
mixin _$RoadmapDaoMixin on DatabaseAccessor<AppDatabase> {
  $LevelsTable get levels => attachedDatabase.levels;
  $LessonsTable get lessons => attachedDatabase.lessons;
  $PracticeSessionsTable get practiceSessions =>
      attachedDatabase.practiceSessions;
  $MistakesTable get mistakes => attachedDatabase.mistakes;
  $VocabItemsTable get vocabItems => attachedDatabase.vocabItems;
  $AppSettingsTable get appSettings => attachedDatabase.appSettings;
  RoadmapDaoManager get managers => RoadmapDaoManager(this);
}

class RoadmapDaoManager {
  final _$RoadmapDaoMixin _db;
  RoadmapDaoManager(this._db);
  $$LevelsTableTableManager get levels =>
      $$LevelsTableTableManager(_db.attachedDatabase, _db.levels);
  $$LessonsTableTableManager get lessons =>
      $$LessonsTableTableManager(_db.attachedDatabase, _db.lessons);
  $$PracticeSessionsTableTableManager get practiceSessions =>
      $$PracticeSessionsTableTableManager(
        _db.attachedDatabase,
        _db.practiceSessions,
      );
  $$MistakesTableTableManager get mistakes =>
      $$MistakesTableTableManager(_db.attachedDatabase, _db.mistakes);
  $$VocabItemsTableTableManager get vocabItems =>
      $$VocabItemsTableTableManager(_db.attachedDatabase, _db.vocabItems);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db.attachedDatabase, _db.appSettings);
}
