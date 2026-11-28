{{flutter_js}}
{{flutter_build_config}}

// Flutter's own service worker is deprecated and unregisters itself; we register web/sw.js from index.html instead.
_flutter.loader.load();
