import 'dart:async';
import 'dart:developer';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:football_challenges/models/club_model.dart';
import 'package:football_challenges/models/league_model.dart';
import 'package:football_challenges/models/player_model.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "PlayerDatabase.db";
  static var _databaseVersion;
  static const _newDatabaseVersion = 1;

  static const table = 'players';

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnImage = 'image';

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  final StreamController<double> _progressController =
      StreamController<double>.broadcast();

  Stream<double> get progressStream => _progressController.stream;

  Future<Database> get database async {
    if (_database != null) {
      _progressController.add(1.0);
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    var databasesPath = await getApplicationDocumentsDirectory();
    var path = join(databasesPath.path, "demo_asset_example.db");

// Check if the database exists
    var exists = await databaseExists(path);

    if (!exists) {
      // Should happen only the first time you launch your application
      print("Creating new copy from asset");

      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(url.join("assets", "mydb.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes written
/*       await File(path).writeAsBytes(bytes, flush: true); */

      await _copyFileWithProgress(bytes, path);
    } else {
      print("Opening existing database");

      var db = await openDatabase(path, password: dotenv.env['DATABASE_PASS']);
      _databaseVersion = db.getVersion();
      //if database does not exist yet it will return version 0
      if (await db.getVersion() < _newDatabaseVersion) {
        log("newer database detected");
        db.close();

        //delete the old database so you can copy the new one
        await deleteDatabase(path);

        try {
          await Directory(dirname(path)).create(recursive: true);
        } catch (_) {}

        //copy db from assets to database folder
        ByteData data = await rootBundle.load("assets/mydb.db");
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
/*         await File(path).writeAsBytes(bytes, flush: true); */

        await _copyFileWithProgress(bytes, path);

        //open the newly created db
        db = await openDatabase(path, password: dotenv.env['DATABASE_PASS']);

        //set the new version to the copied db so you do not need to do it manually on your bundled database.db
        db.setVersion(_newDatabaseVersion);
      }
      _progressController.add(1.0);

      return db;
    }
    return await openDatabase(
      path,
      version: _databaseVersion,
      password: dotenv.env['DATABASE_PASS'],
    );
  }

  Future<void> _copyFileWithProgress(List<int> bytes, String path) async {
    final file = File(path);
    final totalBytes = bytes.length;
    int bytesCopied = 0;
    final int bufferSize = 1024 * 1024; // 1 MB buffer
    final List<int> buffer = List.filled(bufferSize, 0);

    for (int i = 0; i < bytes.length; i += bufferSize) {
      final int end =
          (i + bufferSize < bytes.length) ? i + bufferSize : bytes.length;
      await file.writeAsBytes(bytes.sublist(i, end), mode: FileMode.append);
      bytesCopied += end - i;
      _progressController.add(bytesCopied / totalBytes);
    }

    _progressController
        .add(1.0); // Ensure the progress is set to 100% at the end
  }

  Future<List<Map<String, dynamic>>> fuzzySearchClubs(
      String query, List<int> leagueIds) async {
    Database db = await instance.database;
    final String leagueIdsString = leagueIds.join(', ');

    if (query.length < 2) return List<Map<String, dynamic>>.empty();
    final data = await db.rawQuery(
      'SELECT id, name, league_id, logo FROM Clubs WHERE league_id IN ($leagueIdsString)',
    );

    final fuse = Fuzzy(
      data,
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'name',
            weight: 1,
            getter: (obj) =>
                (obj as Map<String, dynamic>)['name']?.toString() ?? '',
          ),
        ],
        threshold: 0.4,
        isCaseSensitive: false,
        // Adjust the threshold as needed
      ),
    );

    final result = fuse.search(query);
    final fixedResult =
        result.map((e) => e.item as Map<String, dynamic>).toList();
    return fixedResult;
  }

  Future<List<Map<String, dynamic>>> fuzzySearchPlayers(
      String query, List<int> leagueIds) async {
    Database db = await instance.database;
    final String leagueIdsString = leagueIds.join(', ');
    if (query.length < 3) return List<Map<String, dynamic>>.empty();
    String searchQuery = '%$query%';
    final data = await db.rawQuery(
      'SELECT id, name, image, name_in_home_country, full_name FROM Players WHERE id IN (SELECT player_id FROM PlayerClubHistory WHERE club_id IN (SELECT id FROM Clubs WHERE league_id IN ($leagueIdsString)))',
    );
    final fuse = Fuzzy(
      data,
      options: FuzzyOptions(
        shouldSort: true,
        keys: [
          WeightedKey(
            name: 'name',
            weight: 5,
            getter: (obj) =>
                (obj as Map<String, dynamic>)['name']?.toString() ?? '',
          ),
          WeightedKey(
            name: 'name_in_home_country',
            weight: 1,
            getter: (obj) =>
                (obj as Map<String, dynamic>)['name_in_home_country']
                    ?.toString() ??
                '',
          ),
          WeightedKey(
            name: 'full_name',
            weight: 1,
            getter: (obj) =>
                (obj as Map<String, dynamic>)['full_name']?.toString() ?? '',
          ),
        ],
        threshold: 0.3,
        isCaseSensitive: false,
        // Adjust the threshold as needed
      ),
    );

    final result = fuse.search(query);
    final fixedResult =
        result.map((e) => e.item as Map<String, dynamic>).toList();
    return fixedResult;
  }

  Future<List<Map<String, dynamic>>> searchPlayers(
      String query, List<int> leagueIds) async {
    Database db = await instance.database;
    final String leagueIdsString = leagueIds.join(', ');
    if (query.length < 3) return List<Map<String, dynamic>>.empty();
    String searchQuery = '%$query%';
    return await db.rawQuery(
      'SELECT id, name, image, name_in_home_country, full_name FROM Players WHERE id IN (SELECT player_id FROM PlayerClubHistory WHERE club_id IN (SELECT id FROM Clubs WHERE league_id IN ($leagueIdsString))) AND (name LIKE ? OR full_name LIKE ? OR name_in_home_country LIKE ?)',
      [searchQuery, searchQuery, searchQuery],
    );
  }

  Future<bool> validatePlayerInClub(int playerId, int clubId) async {
    Database db = await instance.database;
    final temp = await db.rawQuery(
      'SELECT DISTINCT player_id FROM PlayerClubHistory WHERE player_id = ? AND club_id = ?',
      [playerId, clubId],
    );
    if (temp.isEmpty) return false;
    return true;
  }

  Future<List<Map<String, dynamic>>> getAllPlayerClubs(
      int playerId, List<int> leagueIds) async {
    Database db = await instance.database;
    final String leagueIdsString = leagueIds.join(', ');

    return await db.rawQuery(
      'SELECT DISTINCT club_id FROM PlayerClubHistory WHERE player_id = ? AND club_id IN (SELECT id FROM clubs WHERE league_id IN ($leagueIdsString))',
      [playerId],
    );
  }

  Future<List<Map<String, dynamic>>> getAllClubPlayers(int clubId) async {
    Database db = await instance.database;
    return await db.rawQuery(
      'SELECT * FROM PlayerClubHistory WHERE club_id = ?',
      [clubId],
    );
  }

  Future<List<Map<String, dynamic>>> searchClubs(
      String query, List<int> leagueIds) async {
    Database db = await instance.database;
    final String leagueIdsString = leagueIds.join(', ');

    if (query.length < 2) return List<Map<String, dynamic>>.empty();
    String searchQuery = '%$query%';
    return await db.rawQuery(
      'SELECT id, name, league_id, logo FROM Clubs WHERE name LIKE ? AND league_id IN ($leagueIdsString)',
      [searchQuery],
    );
  }

  Future<List<League>> getLeagues() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('leagues');
    return List.generate(maps.length, (i) => League.fromMap(maps[i]));
  }

  Future<List<League>> getLeaguesByIds(List<int> ids) async {
    Database db = await instance.database;
    String idsString =
        ids.join(','); // Convert the list of IDs to a comma-separated string

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM leagues WHERE id IN ($idsString)',
    );

    return List.generate(maps.length, (i) => League.fromMap(maps[i]));
  }

  Future<List<Club>> getClubsByLeagueIds(List<int> leagueIds) async {
    Database db = await instance.database;

    final String leagueIdsString = leagueIds.join(', ');
    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM Clubs WHERE league_id IN ($leagueIdsString)',
    );
    return List.generate(maps.length, (i) => Club.fromMap(maps[i]));
  }

  Future<Club> getClubsById(int id) async {
    Database db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM Clubs WHERE id = $id',
    );
    return Club.fromMap(maps[0]);
  }

  Future<Player> getPlayerById(int id) async {
    Database db = await instance.database;

    final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT * FROM Players WHERE id = $id',
    );
    return Player.fromMap(maps[0]);
  }
}
