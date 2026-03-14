import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';
import 'package:eirafocus/features/meditation/domain/meditation_journey.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('eirafocus.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 10,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE custom_methods (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          inhale INTEGER NOT NULL,
          hold_after_inhale INTEGER NOT NULL,
          exhale INTEGER NOT NULL,
          hold_after_exhale INTEGER NOT NULL
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE sessions ADD COLUMN journal TEXT');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE favorites (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          method_name TEXT NOT NULL UNIQUE
        )
      ''');
      await db.execute('''
        CREATE TABLE goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          weekly_minutes INTEGER NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE custom_journeys (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          duration_minutes INTEGER NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE custom_journey_prompts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          journey_id INTEGER NOT NULL,
          timestamp_seconds INTEGER NOT NULL,
          text TEXT NOT NULL,
          FOREIGN KEY (journey_id) REFERENCES custom_journeys(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE sessions ADD COLUMN tags TEXT');
    }
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE challenges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          type TEXT NOT NULL,
          target_value INTEGER NOT NULL,
          start_date TEXT NOT NULL,
          end_date TEXT NOT NULL,
          completed INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('ALTER TABLE sessions ADD COLUMN mood_before INTEGER');
      await db.execute('ALTER TABLE sessions ADD COLUMN mood_after INTEGER');
    }
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE session_presets (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type TEXT NOT NULL,
          method TEXT NOT NULL,
          duration_minutes INTEGER,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE streak_freezes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          freeze_date TEXT NOT NULL UNIQUE
        )
      ''');
    }
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        method TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        journal TEXT,
        tags TEXT,
        mood_before INTEGER,
        mood_after INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE streaks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_session_date TEXT NOT NULL,
        current_streak INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_methods (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        inhale INTEGER NOT NULL,
        hold_after_inhale INTEGER NOT NULL,
        exhale INTEGER NOT NULL,
        hold_after_exhale INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        method_name TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        weekly_minutes INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_journeys (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        duration_minutes INTEGER NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE custom_journey_prompts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        journey_id INTEGER NOT NULL,
        timestamp_seconds INTEGER NOT NULL,
        text TEXT NOT NULL,
        FOREIGN KEY (journey_id) REFERENCES custom_journeys(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE session_presets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        method TEXT NOT NULL,
        duration_minutes INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        type TEXT NOT NULL,
        target_value INTEGER NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        completed INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE streak_freezes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        freeze_date TEXT NOT NULL UNIQUE
      )
    ''');
  }

  // ─── Custom Methods ──────────────────────────────────────────
  Future<void> insertCustomMethod(Map<String, dynamic> method) async {
    final db = await instance.database;
    await db.insert('custom_methods', method);
  }

  Future<List<Map<String, dynamic>>> getCustomMethods() async {
    final db = await instance.database;
    return await db.query('custom_methods');
  }

  Future<void> deleteCustomMethod(int id) async {
    final db = await instance.database;
    await db.delete('custom_methods', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Sessions ────────────────────────────────────────────────
  Future<void> insertSession(MeditationSession session) async {
    final db = await instance.database;
    await db.insert('sessions', session.toMap());
    await _updateStreak(session.timestamp);
  }

  Future<List<MeditationSession>> getSessions() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('sessions', orderBy: 'timestamp DESC');
    return List.generate(maps.length, (i) => MeditationSession.fromMap(maps[i]));
  }

  // ─── Streaks ─────────────────────────────────────────────────
  Future<void> _updateStreak(DateTime timestamp) async {
    final db = await instance.database;
    final today = DateTime(timestamp.year, timestamp.month, timestamp.day).toIso8601String().split('T')[0];

    final List<Map<String, dynamic>> result = await db.query('streaks', limit: 1);

    if (result.isEmpty) {
      await db.insert('streaks', {
        'last_session_date': today,
        'current_streak': 1,
      });
    } else {
      final lastDate = result.first['last_session_date'] as String;
      final currentStreak = result.first['current_streak'] as int;

      if (lastDate == today) return;

      final lastDateTime = DateTime.parse(lastDate);
      final todayDateTime = DateTime.parse(today);
      final difference = todayDateTime.difference(lastDateTime).inDays;

      if (difference == 1) {
        final newStreak = currentStreak + 1;
        await db.update('streaks', {
          'last_session_date': today,
          'current_streak': newStreak,
        });
        // Award a freeze token on every 7-day milestone (max 2)
        if (newStreak % 7 == 0) {
          final prefs = await SharedPreferences.getInstance();
          final tokens = prefs.getInt('streak_freeze_tokens') ?? 1;
          if (tokens < 2) {
            await prefs.setInt('streak_freeze_tokens', tokens + 1);
          }
        }
      } else if (difference > 1) {
        await db.update('streaks', {
          'last_session_date': today,
          'current_streak': 1,
        });
      }
    }
  }

  Future<int> getCurrentStreak() async {
    final db = await instance.database;
    final result = await db.query('streaks', limit: 1);
    if (result.isEmpty) return 0;

    final lastDate = result.first['last_session_date'] as String;
    final lastDateTime = DateTime.parse(lastDate);
    final today = DateTime.now();
    final difference = DateTime(today.year, today.month, today.day).difference(lastDateTime).inDays;

    if (difference <= 1) return result.first['current_streak'] as int;

    if (difference == 2) {
      // Check if the missed day has a freeze applied
      final missedDate = lastDateTime.add(const Duration(days: 1));
      final missedDateStr = _isoDate(missedDate);
      final freeze = await db.query('streak_freezes',
          where: 'freeze_date = ?', whereArgs: [missedDateStr]);
      if (freeze.isNotEmpty) return result.first['current_streak'] as int;
    }

    return 0;
  }

  // ─── Streak Freeze ────────────────────────────────────────────
  Future<int> getFreezesAvailable() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('streak_freeze_tokens') ?? 1;
  }

  /// Returns the saved streak value and whether a freeze can restore it.
  Future<({int streak, bool canFreeze, int freezeTokens})> getStreakStatus() async {
    final db = await instance.database;
    final result = await db.query('streaks', limit: 1);
    final tokens = await getFreezesAvailable();

    if (result.isEmpty) return (streak: 0, canFreeze: false, freezeTokens: tokens);

    final lastDate = result.first['last_session_date'] as String;
    final lastDateTime = DateTime.parse(lastDate);
    final today = DateTime.now();
    final difference =
        DateTime(today.year, today.month, today.day).difference(lastDateTime).inDays;
    final savedStreak = result.first['current_streak'] as int;

    if (difference <= 1) {
      return (streak: savedStreak, canFreeze: false, freezeTokens: tokens);
    }

    if (difference == 2 && tokens > 0) {
      // Check if already frozen
      final missedDate = lastDateTime.add(const Duration(days: 1));
      final freeze = await db.query('streak_freezes',
          where: 'freeze_date = ?', whereArgs: [_isoDate(missedDate)]);
      if (freeze.isNotEmpty) {
        return (streak: savedStreak, canFreeze: false, freezeTokens: tokens);
      }
      return (streak: 0, canFreeze: true, freezeTokens: tokens);
    }

    return (streak: 0, canFreeze: false, freezeTokens: tokens);
  }

  Future<bool> applyStreakFreeze() async {
    final db = await instance.database;
    final result = await db.query('streaks', limit: 1);
    if (result.isEmpty) return false;

    final lastDate = result.first['last_session_date'] as String;
    final lastDateTime = DateTime.parse(lastDate);
    final today = DateTime.now();
    final difference =
        DateTime(today.year, today.month, today.day).difference(lastDateTime).inDays;

    if (difference != 2) return false;

    final prefs = await SharedPreferences.getInstance();
    final tokens = prefs.getInt('streak_freeze_tokens') ?? 1;
    if (tokens <= 0) return false;

    final missedDate = lastDateTime.add(const Duration(days: 1));
    await db.insert('streak_freezes', {'freeze_date': _isoDate(missedDate)},
        conflictAlgorithm: ConflictAlgorithm.ignore);
    await prefs.setInt('streak_freeze_tokens', tokens - 1);
    return true;
  }

  static String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Debug only: shifts last_session_date back 2 days to simulate a missed day.
  Future<void> debugSimulateMissedDay() async {
    final db = await instance.database;
    final result = await db.query('streaks', limit: 1);
    if (result.isEmpty) return;
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    await db.update('streaks', {'last_session_date': _isoDate(twoDaysAgo)});
  }

  // ─── Favorites ───────────────────────────────────────────────
  Future<void> insertFavorite(String methodName) async {
    final db = await instance.database;
    await db.insert('favorites', {'method_name': methodName},
        conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> removeFavorite(String methodName) async {
    final db = await instance.database;
    await db.delete('favorites', where: 'method_name = ?', whereArgs: [methodName]);
  }

  Future<List<String>> getFavorites() async {
    final db = await instance.database;
    final results = await db.query('favorites');
    return results.map((r) => r['method_name'] as String).toList();
  }

  // ─── Goals ───────────────────────────────────────────────────
  Future<void> setWeeklyGoal(int minutes) async {
    final db = await instance.database;
    await db.delete('goals');
    await db.insert('goals', {
      'weekly_minutes': minutes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<int?> getWeeklyGoal() async {
    final db = await instance.database;
    final result = await db.query('goals', limit: 1);
    if (result.isEmpty) return null;
    return result.first['weekly_minutes'] as int;
  }

  Future<int> getWeeklyMinutes() async {
    final db = await instance.database;
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);
    final results = await db.query(
      'sessions',
      where: 'timestamp >= ?',
      whereArgs: [weekStartDate.toIso8601String()],
    );
    int totalSeconds = 0;
    for (final r in results) {
      totalSeconds += r['duration_seconds'] as int;
    }
    return totalSeconds ~/ 60;
  }

  // ─── Custom Journeys ──────────────────────────────────────────
  Future<int> insertCustomJourney(String name, String description, int durationMinutes, List<GuidedPrompt> prompts) async {
    final db = await instance.database;
    final journeyId = await db.insert('custom_journeys', {
      'name': name,
      'description': description,
      'duration_minutes': durationMinutes,
    });
    for (final p in prompts) {
      await db.insert('custom_journey_prompts', {
        'journey_id': journeyId,
        'timestamp_seconds': p.timestamp.inSeconds,
        'text': p.text,
      });
    }
    return journeyId;
  }

  Future<List<MeditationJourney>> getCustomJourneys() async {
    final db = await instance.database;
    final journeys = await db.query('custom_journeys', orderBy: 'id DESC');
    final result = <MeditationJourney>[];
    for (final j in journeys) {
      final prompts = await db.query(
        'custom_journey_prompts',
        where: 'journey_id = ?',
        whereArgs: [j['id']],
        orderBy: 'timestamp_seconds ASC',
      );
      result.add(MeditationJourney(
        name: j['name'] as String,
        description: j['description'] as String,
        totalDuration: Duration(minutes: j['duration_minutes'] as int),
        prompts: prompts
            .map((p) => GuidedPrompt(
                  timestamp: Duration(seconds: p['timestamp_seconds'] as int),
                  text: p['text'] as String,
                ))
            .toList(),
        id: j['id'] as int,
      ));
    }
    return result;
  }

  Future<void> deleteCustomJourney(int id) async {
    final db = await instance.database;
    await db.delete('custom_journey_prompts', where: 'journey_id = ?', whereArgs: [id]);
    await db.delete('custom_journeys', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Challenges ─────────────────────────────────────────────────
  Future<int> insertChallenge(Map<String, dynamic> challenge) async {
    final db = await instance.database;
    return await db.insert('challenges', challenge);
  }

  Future<List<Map<String, dynamic>>> getActiveChallenges() async {
    final db = await instance.database;
    final now = DateTime.now().toIso8601String().split('T')[0];
    return await db.query('challenges',
        where: 'end_date >= ? AND completed = 0',
        whereArgs: [now],
        orderBy: 'end_date ASC');
  }

  Future<List<Map<String, dynamic>>> getCompletedChallenges() async {
    final db = await instance.database;
    return await db.query('challenges',
        where: 'completed = 1',
        orderBy: 'end_date DESC',
        limit: 10);
  }

  Future<void> completeChallenge(int id) async {
    final db = await instance.database;
    await db.update('challenges', {'completed': 1}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteChallenge(int id) async {
    final db = await instance.database;
    await db.delete('challenges', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getSessionCountBetween(DateTime start, DateTime end) async {
    final db = await instance.database;
    final results = await db.query('sessions',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()]);
    return results.length;
  }

  Future<int> getTotalMinutesBetween(DateTime start, DateTime end) async {
    final db = await instance.database;
    final results = await db.query('sessions',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()]);
    int total = 0;
    for (final r in results) {
      total += r['duration_seconds'] as int;
    }
    return total ~/ 60;
  }

  Future<int> getLastWeekMinutes() async {
    final now = DateTime.now();
    final thisWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(seconds: 1));
    return getTotalMinutesBetween(lastWeekStart, lastWeekEnd);
  }

  Future<int> getLastWeekSessionCount() async {
    final now = DateTime.now();
    final thisWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final lastWeekStart = thisWeekStart.subtract(const Duration(days: 7));
    final lastWeekEnd = thisWeekStart.subtract(const Duration(seconds: 1));
    return getSessionCountBetween(lastWeekStart, lastWeekEnd);
  }

  Future<int> getThisWeekSessionCount() async {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    return getSessionCountBetween(weekStart, now);
  }

  // ─── Session Presets ─────────────────────────────────────────────
  Future<int> insertPreset(Map<String, dynamic> preset) async {
    final db = await instance.database;
    return await db.insert('session_presets', preset);
  }

  Future<List<Map<String, dynamic>>> getPresets() async {
    final db = await instance.database;
    return await db.query('session_presets', orderBy: 'created_at DESC');
  }

  Future<void> deletePreset(int id) async {
    final db = await instance.database;
    await db.delete('session_presets', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getStreakDaysBetween(DateTime start, DateTime end) async {
    final db = await instance.database;
    final results = await db.query('sessions',
        where: 'timestamp >= ? AND timestamp <= ?',
        whereArgs: [start.toIso8601String(), end.toIso8601String()],
        orderBy: 'timestamp ASC');
    final days = <String>{};
    for (final r in results) {
      final date = DateTime.parse(r['timestamp'] as String);
      days.add('${date.year}-${date.month}-${date.day}');
    }
    return days.length;
  }
}
