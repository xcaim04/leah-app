import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';

import 'app.dart';
import 'data/db/db_factory.dart';

void main() {
  final factory = platformDatabaseFactory();
  if (factory != null) databaseFactory = factory;
  runApp(const ProviderScope(child: MiArmarioApp()));
}
