import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'schedule_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('shiftox.db'); // 在本機建立 shiftox.db 檔案 
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path, 
      version: 2, 
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  // 平滑升級機制，保護手機裡的舊資料！
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 偵測到手機裡是舊版 (v1)，自動幫 schedules 表格擴建兩個收入欄位
      await db.execute("ALTER TABLE schedules ADD COLUMN income_amount INTEGER DEFAULT 0");
      await db.execute("ALTER TABLE schedules ADD COLUMN income_note TEXT DEFAULT '[]'");
    }
  }

  // 🛠️ 嚴格依據計劃書的「三、 本地資料庫設計 (SQLite Schema)」建表 [cite: 18]
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE schedules (
        date TEXT PRIMARY KEY,
        position TEXT,
        start_time TEXT,
        end_time TEXT,
        expense_amount INTEGER,
        expense_note TEXT,
        income_amount INTEGER DEFAULT 0,
        income_note TEXT DEFAULT '[]'
      )
    ''');

    // 2. 建立 settings 表來存時薪等全域設定，預設時薪為 180 元
    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');
    await db.insert('settings', {'key': 'hourly_wage', 'value': '196'});
  }

  // 💾 寫入或更新當天資料
  Future<int> insertOrUpdateSchedule(ScheduleModel schedule) async {
    final db = await instance.database;
    return await db.insert(
      'schedules',
      schedule.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace, // 重複日期直接替換，達成防呆修改 
    );
  }

  // 🔍 依據日期查詢單日排班與記帳數據
  Future<ScheduleModel?> getScheduleByDate(String date) async {
    final db = await instance.database;
    final maps = await db.query(
      'schedules',
      where: 'date = ?',
      whereArgs: [date],
    );

    if (maps.isNotEmpty) {
      return ScheduleModel.fromMap(maps.first);
    }
    return null;
  }

  // 🔍 查詢整個月的所有排班數據 (用來算當月累計總薪資)
  Future<List<ScheduleModel>> getSchedulesByMonth(String yearMonth) async {
    final db = await instance.database;
    // yearMonth 格式為 "YYYY-MM"
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: "date LIKE ?",
      whereArgs: ['$yearMonth-%'],
    );

    return List.generate(maps.length, (i) => ScheduleModel.fromMap(maps[i]));
  }

  // 💰 讀取時薪
  Future<int> getHourlyWage() async {
    final db = await instance.database;
    final maps = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['hourly_wage'],
    );
    if (maps.isNotEmpty) {
      return int.tryParse(maps.first['value']?.toString() ?? '196') ?? 196;
    }
    return 196;
  }

  // 💰 設定時薪
  Future<void> setHourlyWage(int wage) async {
    final db = await instance.database;
    await db.insert(
      'settings',
      {'key': 'hourly_wage', 'value': wage.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}