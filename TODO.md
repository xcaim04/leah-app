# Mi Armario (Leah) — TODO

App Flutter Android de armario digital para una sola usuaria. 100 % local, offline, gratis.
Sin backend, sin APIs, sin cuentas, sin LLM. UI en español, código en inglés.

**Estado:** Fases 1–5 implementadas, revisadas e integradas en `main`. Falta el andamiaje Android y la verificación/compilación real (bloqueado: no se ha ejecutado `flutter`/`dart`).

---

## Hecho

### Fase 0 — Plan
- Arquitectura, paquetes, esquema SQLite, pantallas y plan por fases (`PLAN.md`).

### Fase 1 — Esqueleto
- App Material 3, `main.dart` / `app.dart`.
- Entidades y enums con `.label` en español: `Garment`, `GarmentColor`, `Outfit`, `OutfitFeedback`, `GarmentCategory`, `Occasion`, `Season`, `FeedbackRating`, `EmptyState`.
- Esquema SQLite v1 (`garments`, `outfit_feedback`) + migraciones versionadas.
- Shell de navegación con `NavigationBar`: Armario / Looks / Favoritos.

### Fase 2 — Armario
- Alta/edición/borrado de prendas con cámara o galería.
- Compresión y miniatura propias; extracción de color dominante (paleta).
- Grid con filtros (categoría / ocasión / temporada), tarjeta de prenda, pantalla de detalle, favorito.

### Fase 3 — Motor de looks
- Reglas de armonía de color en HSL (neutro, monocromático, análogo, tríada, complementario, penalizaciones).
- Puntuador con pesos (`ScoringWeights`) + generador de combinaciones + explicaciones en español.

### Fase 4 — Feedback
- 👍/👎 persistido por look (upsert por firma).
- Pesos adaptativos aprendidos del historial (`weight_learning.dart`, acotados a ~0.3×–1.7× de la base).
- Pantalla Favoritos = looks con "me gusta".

### Fase 5 — Pulido
- Manejo de errores de cámara/galería y paleta con SnackBars en español (paleta best-effort).
- Accesibilidad: tooltips/Semantics, `supportedLocales` (es/en).
- `cacheWidth` en miniaturas y foto de detalle; versión `0.5.0+5`.

### Infraestructura git
- Repo con `main` + `staging`, ramas `feat/phase-1..5`, remoto bare local, tags `v0.1-fase1` … `v0.5-fase5`.
- Correcciones de integración: imágenes siempre `.jpg`; `Color.toARGB32()` (evita API deprecada).

### Tests escritos (9, **sin ejecutar**)
- `color_math_test`, `garment_color_test`, `garment_filter_test`, `garment_repository_test`, `harmony_rules_test`, `image_storage_helper_test`, `outfit_engine_test`, `outfit_feedback_repository_test`, `weight_learning_test`.

### Fase 6 — Diseño (Coquette Violette)
- Sistema de diseño de Stitch aplicado (`design/coquette_violette/DESIGN.md`): paleta Material 3 violeta exacta (claro + oscuro derivado) y tipografía en `app_theme.dart` (ya no usa semilla `0xFFB0698A`).
- Tema de componentes: tarjetas redondeadas 24, chips tipo píldora, botones `StadiumBorder`, `NavigationBar` con indicador `secondaryContainer`, inputs rellenos sin borde.
- Pantallas re-estilizadas: armario (tarjeta de prenda con píldora de categoría, badge "Offline"), formulario (foto hero con Cámara/Galería, selectores por chips, tarjetas de sección), detalle (hero, paleta, tarjetas de especificación, dock Editar/Eliminar), looks (miniaturas de prenda + badge de puntuación), favoritos.

---

## Pendiente

### Bloqueante para tener APK
- [ ] `flutter create --platforms=android .` para generar `android/` (aún no existe).
- [ ] Fijar `applicationId` y `namespace` = `com.leah.app` (editar `build.gradle` + mover `MainActivity.kt`).
- [ ] Nombre visible de la app ("Mi Armario") y permiso `CAMERA` en `AndroidManifest.xml`.
- [ ] Icono de app (y splash) con `flutter_launcher_icons`.
- [ ] `flutter pub get` → `flutter analyze` (dejar 0 warnings) → `flutter test` (los 9 en verde).
- [ ] Revisar avisos de deprecación (p. ej. `DropdownButtonFormField.value` → `initialValue`).
- [ ] Build release: `flutter build apk --release --split-per-abi` y medir tamaño (objetivo < 40 MB).

### Verificación manual en dispositivo
- [ ] Permisos de cámara/galería y flujo de alta de prenda con fotos reales.
- [ ] Ajustar umbrales de armonía con prendas reales (los actuales son heurísticos).
- [ ] Comprobar que el fondo de la foto no contamine la paleta (muestreo central + quitar color a mano).

### Opcional (fuera del MVP)
- [ ] Empaquetar la fuente "Plus Jakarta Sans" como asset (el diseño la usa; hoy se usa la fuente por defecto).
- [ ] Renombrar el paquete Dart `mi_armario` → `leah_app` (tocar imports `package:mi_armario/`).
- [ ] `flutter_localizations` para textos nativos del sistema en español.
- [ ] Copia de seguridad / exportación del armario.
- [ ] Recorte de fondo de la foto; accesorios dentro de los looks.

---

## Notas
- El paquete Dart sigue llamándose `mi_armario` (solo cambió la carpeta a `Leah-App`); los imports `package:mi_armario/...` funcionan igual.
- El remoto bare local vive en `.leah/mi_armario.git` (ignorado por git).
- `PLAN.md` es el plan original de la Fase 0; algunas decisiones (paquetes, esquema) evolucionaron durante la implementación.
