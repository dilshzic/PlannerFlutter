import 'platform_db_setup.dart' if (dart.library.html) 'platform_db_setup_web.dart';

void initializeDatabaseFactory() {
  setupDatabaseFactory();
}
