// Web needs the wasm-backed sqflite factory; Android keeps plain sqflite.
export 'db_factory_io.dart' if (dart.library.js_interop) 'db_factory_web.dart';
