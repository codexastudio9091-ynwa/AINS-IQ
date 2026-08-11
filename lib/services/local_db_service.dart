import 'package:hive_flutter/hive_flutter.dart';

class LocalDbService {
  static const String booksBoxName = 'nilam_bookshelf';
  static const String accessBoxName = 'app_access_settings';

  // Initialize Hive and open both local storage boxes on app startup
  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(booksBoxName);
    await Hive.openBox(accessBoxName);
  }

  // Getter for the NILAM Bookshelf database box
  static Box get booksBox => Hive.box(booksBoxName);

  // Getter for the User Credits & License Settings database box
  static Box get accessBox => Hive.box(accessBoxName);
}
