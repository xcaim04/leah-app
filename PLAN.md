# Leah — Plan (Fase 0)

App Flutter de armario digital para una sola usuaria. 100 % local, gratis, sin backend, sin LLM.
Repositorio: `~/workspace/leah`. Entrega: APK release instalable (objetivo < 40 MB; esperado ~20 MB con `--split-per-abi`).

## 1. Decisiones

| Tema | Decisión | Por qué |
|---|---|---|
| Estado | **Riverpod** (`flutter_riverpod`, sin codegen) | Providers sin `BuildContext`, `AsyncValue` para carga/error de SQLite, fácil de sobreescribir en tests. Sin `riverpod_generator` ni `build_runner`. |
| Base de datos | **sqflite** | SQL directo, 2 tablas. drift obligaría a codegen sin aportar nada aquí. |
| Compresión | **`image_picker` con `maxWidth: 1080, imageQuality: 85`** | El picker ya redimensiona y comprime en nativo. **Se descarta `flutter_image_compress`**: sería una dependencia nativa para algo que ya hace el picker. |
| Thumbnail y píxeles | **`image`** (Dart puro, en isolate) | Genera el thumbnail (~300 px) y da los píxeles para extraer color. |
| Extracción de color | **K-means propio en Dart puro** | `palette_generator` está **descontinuado** en pub.dev. K-means sobre el thumbnail son ~60 líneas, puro y testeable. |
| Navegación | `Navigator` + `NavigationBar` | 3 pestañas y 1 formulario; `go_router` sobra. |
| Pesos de feedback | **Se calculan al vuelo desde la tabla de feedback** | Sin tabla de pesos: nada que desincronizar, y siempre explicable. |
| Rutas de fotos | Se guarda **solo el nombre de archivo**, no la ruta absoluta | La ruta del directorio de la app puede cambiar (reinstalación, iOS). |
| Permisos | Ninguno declarado | El selector de fotos de Android y la cámara por intent no requieren permisos. |
| Plataforma | Android. iOS no se configura. | Se puede añadir después sin cambios de código. |

## 2. Paquetes (versiones comprobadas en pub.dev el 2026-11-14)

Todos gratuitos y de código abierto (BSD / MIT / Apache).

| Paquete | Versión | Uso |
|---|---|---|
| `flutter_riverpod` | ^3.5.0 | Estado |
| `sqflite` | ^2.4.6 | SQLite |
| `path_provider` | ^2.1.6 | Directorio interno de la app |
| `path` | ^1.9.1 | Unir rutas |
| `image_picker` | ^1.2.4 | Galería / cámara + redimensionado |
| `image` | ^4.13.1 | Thumbnail y lectura de píxeles |
| dev: `sqflite_common_ffi` | ^2.4.7 | Tests del repositorio sin dispositivo |
| dev: `flutter_lints` | la que traiga `flutter create` | Lints |
| dev: `flutter_launcher_icons` | ^0.14.4 | Ícono (Fase 5) |

## 3. Estructura de carpetas

```
leah/
  lib/
    main.dart
    app.dart                      # MaterialApp, tema M3, shell con NavigationBar
    data/
      app_database.dart           # apertura + migraciones versionadas
      garment_repository.dart
      feedback_repository.dart
      photo_storage.dart          # guardar/borrar foto y thumbnail
    domain/                       # Dart puro, sin imports de Flutter
      garment.dart                # modelo + enums (Category, Occasion, Season)
      outfit.dart
      hsl_color.dart              # RGB→HSL, isNeutral, nombre del color en español
      color_extractor.dart        # k-means sobre lista de píxeles
      harmony.dart                # reglas de armonía entre dos colores
      outfit_engine.dart          # generación + puntuación + explicación
      feedback_weights.dart       # sesgos a partir del feedback
    presentation/
      providers.dart
      wardrobe/                   # grid + filtros, formulario alta/edición
      outfits/                    # sugerencias + 👍/👎
      favorites/
  test/
    data/                         # repositorios (sqflite_common_ffi)
    domain/                       # reglas de color, motor, pesos
```

## 4. Esquema SQLite (v1)

```sql
PRAGMA foreign_keys = ON;

CREATE TABLE garments (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  photo_file  TEXT    NOT NULL,
  thumb_file  TEXT    NOT NULL,
  category    TEXT    NOT NULL,  -- top|bottom|dress|shoes|outerwear|accessory
  colors      TEXT    NOT NULL,  -- JSON: [{"h":210,"s":0.6,"l":0.4,"weight":0.5}, ...]
  occasion    TEXT    NOT NULL,  -- casual|work|party|sport
  season      TEXT    NOT NULL,  -- summer|winter|midseason|all
  notes       TEXT    NOT NULL DEFAULT '',
  favorite    INTEGER NOT NULL DEFAULT 0,
  created_at  INTEGER NOT NULL   -- epoch ms
);
CREATE INDEX idx_garments_category ON garments(category);

CREATE TABLE outfit_feedback (
  outfit_key   TEXT    PRIMARY KEY,  -- ids ordenados, p. ej. "3-7-12"; un voto por outfit
  top_id       INTEGER REFERENCES garments(id) ON DELETE CASCADE,
  bottom_id    INTEGER REFERENCES garments(id) ON DELETE CASCADE,
  dress_id     INTEGER REFERENCES garments(id) ON DELETE CASCADE,
  shoes_id     INTEGER REFERENCES garments(id) ON DELETE CASCADE,
  outerwear_id INTEGER REFERENCES garments(id) ON DELETE CASCADE,
  vote         INTEGER NOT NULL,     -- +1 | -1
  created_at   INTEGER NOT NULL
);
```

Migraciones: lista ordenada de scripts; `onUpgrade` ejecuta los que van de `oldVersion` a `newVersion`.
Borrar una prenda borra sus archivos y, por cascada, el feedback de los outfits que la contenían.

## 5. Pantallas y navegación

`NavigationBar` con 3 pestañas:

1. **Armario** — grid de thumbnails, chips de filtro (categoría / ocasión / temporada), FAB "Añadir prenda". Tocar una prenda abre el formulario.
2. **Outfits** — filtros de ocasión y temporada, lista de los N mejores outfits con fotos, explicación y 👍/👎.
3. **Favoritos** — outfits con 👍 y prendas marcadas como favoritas.

Pantalla apilada: **Formulario de prenda** (alta y edición en la misma pantalla): foto, colores detectados, categoría, ocasión, temporada, notas, favorito, eliminar.

## 6. Motor de combinaciones (Dart puro)

- **Generación**: `top + bottom` (+ calzado, + abrigo opcionales) o `vestido + calzado`. Los accesorios no entran en el MVP.
- **Sin explosión combinatoria**: se puntúan los pares top+bottom, se conservan los mejores y a cada uno se le añade el calzado y abrigo que mejor puntúan.
- **Puntuación por par de colores** (diferencia de tono en HSL, ponderada por el peso de cada color):
  - Neutro (saturación baja, muy claro/oscuro, o navy/beige por rango): combina con todo.
  - Monocromático (Δtono < 15° con luminosidad distinta), análogo (15–45°), tríada (~120°), complementario (~180°): bonus.
  - Penalización: ambos muy saturados y no armónicos; tonos casi iguales con luminosidad casi igual ("se ensucian").
- **Bonus de contexto**: misma ocasión; temporada compatible (`todo` es compatible con cualquiera).
- **Explicación**: plantilla según la regla que más puntuó + nombres de color en español + ocasión/temporada.
- **Feedback**: `puntuación final = armonía + contexto + sesgo de prendas + sesgo de esquema`. Los sesgos son la suma acotada de votos de cada prenda y de cada esquema de armonía, recalculada desde `outfit_feedback`. Un outfit con 👎 no se vuelve a sugerir.

## 7. Fases (confirmación entre cada una)

| Fase | Entrega | Verificación |
|---|---|---|
| 1 Esqueleto | `flutter create`, tema M3, shell con 3 pestañas vacías, modelos, BD con migraciones | Tests de repositorios |
| 2 Armario | Alta/edición/borrado con foto, thumbnail, k-means, grid con filtros | Tests de k-means y HSL; prueba manual en dispositivo |
| 3 Motor | Reglas, puntuación, generación, pantalla de sugerencias | Tests unitarios de cada regla y del ranking |
| 4 Feedback | 👍/👎, sesgos, pantalla Favoritos | Tests de sesgos |
| 5 Pulido | Empty states, errores de IO, accesibilidad (semántica, contraste), ícono, APK release | `flutter build apk --release --split-per-abi` y medir tamaño |

Cada fase cierra con: resumen de cambios, cómo probarlo y decisiones tomadas.

## 8. Fuera del MVP

- iOS, login, sincronización, analytics.
- Accesorios dentro de los outfits.
- Recorte del fondo de la foto.
- Copia de seguridad / exportación.
- Varias ocasiones o temporadas por prenda.

## 9. Riesgos

1. **El fondo de la foto contamina los colores.** Mitigación del MVP: muestrear solo la zona central de la imagen y permitir quitar a mano un color detectado en el formulario. Funciona mejor con fotos sobre fondo liso.
2. **Sin copia de seguridad**: si se pierde o se restablece el móvil, se pierde el armario.
3. **Los umbrales de armonía son heurísticos**: habrá que ajustarlos con prendas reales en la Fase 3.
