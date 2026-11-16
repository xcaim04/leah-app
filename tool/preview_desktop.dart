// Desktop preview only: `flutter run -d linux -t tool/preview_desktop.dart`.
// sqflite has no desktop backend, so route it through FFI before starting the app.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mi_armario/app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  runApp(const ProviderScope(child: MiArmarioApp()));
}
