// Hive CE adapter registry.
// The theme adapter was removed — no active code reads or writes it to any Hive box.
// WeatherCacheEntry has its own @HiveType annotation (typeId: 2) and generates its own adapter.
// Add AdapterSpec entries here and run build_runner when new Hive models are introduced.
//
// Example:
// import 'package:hive_ce/hive.dart';
// import '../path/to/model.dart';
// @GenerateAdapters(firstTypeId: 0, [AdapterSpec<MyModel>()])
// part 'hive_adapters.g.dart';
