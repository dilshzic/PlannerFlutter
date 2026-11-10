import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

void setupDatabaseFactory() {
  databaseFactory = createDatabaseFactoryFfiWeb(
    options: SqfliteFfiWebOptions(
      sqlite3WasmUri: Uri.parse('sqlite3.wasm'),
      sharedWorkerUri: Uri.parse('sqflite_sw.js'),
    ),
  );
}
