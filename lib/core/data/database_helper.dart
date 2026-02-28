import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:eirafocus/features/meditation/domain/meditation_models.dart';

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
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        method TEXT NOT NULL,
        duration_seconds INTEGER NOT NULL,
        timestamp TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE streaks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        last_session_date TEXT NOT NULL,
        current_streak INTEGER NOT NULL
      )
    ''');
  }

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
        await db.update('streaks', {
          'last_session_date': today,
          'current_streak': currentStreak + 1,
        });
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
    
    if (difference > 1) {
      return 0;
    }
    
    return result.first['current_streak'] as int;
  }
}
