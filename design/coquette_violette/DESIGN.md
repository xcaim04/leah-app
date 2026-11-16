---
name: Coquette Violette
colors:
  surface: '#fff7fe'
  surface-dim: '#ead1fa'
  surface-bright: '#fff7fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#fcf0ff'
  surface-container: '#f8e9ff'
  surface-container-high: '#f4e2ff'
  surface-container-highest: '#f1dbff'
  on-surface: '#241433'
  on-surface-variant: '#4c4450'
  inverse-surface: '#3a2949'
  inverse-on-surface: '#faecff'
  outline: '#7d7481'
  outline-variant: '#cec3d2'
  surface-tint: '#7848a3'
  primary: '#62328c'
  on-primary: '#ffffff'
  primary-container: '#7b4ba6'
  on-primary-container: '#edd4ff'
  inverse-primary: '#dfb7ff'
  secondary: '#6f518e'
  on-secondary: '#ffffff'
  secondary-container: '#dbb8fe'
  on-secondary-container: '#624581'
  tertiary: '#733646'
  on-tertiary: '#ffffff'
  tertiary-container: '#8f4d5e'
  on-tertiary-container: '#ffd1da'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#f1daff'
  primary-fixed-dim: '#dfb7ff'
  on-primary-fixed: '#2d004f'
  on-primary-fixed-variant: '#5f2f89'
  secondary-fixed: '#efdbff'
  secondary-fixed-dim: '#dbb8fe'
  on-secondary-fixed: '#290a46'
  on-secondary-fixed-variant: '#563975'
  tertiary-fixed: '#ffd9e0'
  tertiary-fixed-dim: '#ffb1c2'
  on-tertiary-fixed: '#390819'
  on-tertiary-fixed-variant: '#6f3444'
  background: '#fff7fe'
  on-background: '#241433'
  surface-variant: '#f1dbff'
typography:
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-compact: 0.75rem
  margin: 1.25rem
  margin-compact: 1rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

Este sistema de diseño define la experiencia visual y sensorial de un armario digital personal offline para Android, arraigado en los principios de Material 3 con una interpretación estética *coquette*, lírica, femenina y sumamente pulida. 

### Personalidad y Tono
- **Encanto Refinado:** Delicado, íntimo y caprichoso, pero manteniendo un rigor de alta costura que evita caer en lo infantil o recargado.
- **Calma Táctil y Privacidad:** Al tratarse de una herramienta offline, la interfaz debe sentirse como un joyero personal o un diario textil privado: segura, serena, sin distracciones ni agresividad comercial.
- **Feminidad Estructurada:** Equilibrio entre la suavidad de las curvas orgánicas y la precisión funcional del archivo de prendas, atuendos y catálogos estacionales.

### Motivos Visuales e Iconografía
- **Trazos:** Iconografía de línea fina (1.5dp a 2dp) con remates redondeados (*round caps* y *round joins*) para evitar esquinas punzantes.
- **Acentos Gráficos:** Siluetas lineales minimalistas de conejitos y gatitos, pequeños lazos tenues (*ribbon bows*) y destellos de cuatro puntas (*sparkles*) utilizados de forma sobria como detalles de estado vacío (*empty states*), confirmaciones de guardado o separadores ornamentales.

## Colors

La paleta cromática se construye para evocar una bruma lavanda suave con anclajes en ciruela profundo para garantizar legibilidad AAA en entornos móviles diurnos y bajo luz natural.

### Asignación de Roles Cromáticos
- **Primary (`#7B4BA6`):** Violeta imperial vibrante. Utilizado para acciones principales flotantes (FAB), botones primarios, estados seleccionados activos e indicadores de navegación clave.
- **Secondary (`#C9A7EB`):** Lila pastel aterciopelado. Diseñado para acentos de apoyo, insignias de categoría, estados de foco secundario y elementos decorativos complementarios.
- **Tertiary (`#D88B9D`):** Rosa empolvado tenue (*rosewood blush*). Introduce una calidez textil coqueta para destacar favoritos, etiquetas especiales y prendas destacadas.
- **Neutral / Text (`#3B2A4A`):** Ciruela profundo con matiz violáceo. Sustituye al negro genérico, otorgando alto contraste cromático y calidez editorial a todo el texto sobre fondos claros.
- **Background (`#F6F1FB`):** Niebla lavanda etérea. Base general de la aplicación que elimina la estridencia del blanco puro.
- **Surface (`#FFFFFF`):** Blanco puro reservado para tarjetas de prendas, sábanas modales (*bottom sheets*) y contenedores que requieren máximo contraste fotográfico.
- **Surface Containers (`#EDE4F7` y `#F2EBFA`):** Tonos de soporte para fondos de campos de entrada, chips inactivos y barras de herramientas inferiores.

## Typography

Se emplea **Plus Jakarta Sans** a lo largo de toda la jerarquía tipográfica para aprovechar sus terminales suaves, proporciones humanistas y excelente rendimiento en pantallas móviles de alta densidad.

### Reglas Editoriales
- **Títulos y Secciones:** Emplean pesos semibold (600) y bold (700) con espaciado ligeramente cerrado (-0.01em) para dar un carácter de revista de moda personal.
- **Cuerpo de Texto:** Fluido, claro y con suficiente altura de interlineado (150%) para facilitar la lectura de descripciones de materiales, notas de lavado y combinaciones de ropa.
- **Etiquetas y Micro-textos:** Transformados sutilmente con peso medio o negrita para garantizar que fechas, tallas y categorías textiles permanezcan nítidas a escalas reducidas.

## Layout & Spacing

El diseño se basa en una cuadrícula fluida de 4 columnas optimizada para teléfonos móviles Android, adaptable a 8 columnas en orientación horizontal o tabletas pequeñas.

### Retícula y Márgenes
- **Márgenes Externos de Pantalla:** `1.25rem` (20dp) en condiciones estándar; se reduce a `1rem` (16dp) en pantallas compactas (<360dp de ancho).
- **Canales (Gutters):** `1rem` (16dp) entre tarjetas de prendas para permitir que las miniaturas de ropa respiren sin perder densidad visual.
- **Cuadrícula de Guardarropa:** 2 columnas para el catálogo principal de prendas (proporción visual 3:4 por tarjeta de prenda) para mostrar siluetas completas sin recortes forzados.

### Adaptabilidad Android
- Respeta íntegramente las zonas seguras (*WindowInsets*) del sistema operativo: barra de estado superior translúcida y barra de navegación gestual inferior integrada con padding dinámico adicional de `space-md`.

## Elevation & Depth

La profundidad se modela evitando sombras negras genéricas o contrastes severos, sustituyéndolas por una atmósfera etérea y luminosa inspirada en el resplandor difuso.

### Niveles de Elevación Tonal
- **Nivel 0 (Fondo Base):** Superficie `#F6F1FB` sin sombra.
- **Nivel 1 (Tarjetas de prendas y contenedores):** Superficie `#FFFFFF` con una sombra envolvente teñida: `0px 4px 16px rgba(123, 75, 166, 0.08)`. Bordes de 1dp opcionales en tinte `#EDE4F7` para definir bordes en pantallas AMOLED.
- **Nivel 2 (Tarjetas interactivas al tacto y hojas modales):** Sombra extendida `0px 8px 24px rgba(123, 75, 166, 0.12)`.
- **Nivel 3 (Botón de Acción Flotante - FAB / Menús contextuales):** Resplandor violeta concentrado `0px 6px 20px rgba(123, 75, 166, 0.22)`.
- **Sábanas Inferiores (Bottom Sheets):** Se proyectan sobre un scrim atenuado con tinte ciruela semitransparente: `rgba(59, 42, 74, 0.32)`.

## Shapes

La geometría del sistema abraza radios extra pronunciados para transmitir suavidad táctil y delicadeza ornamental.

### Mapeo de Radios Específicos
- **Botones y Acciones de Filtro:** Píldora absoluta (`9999px`) tanto en botones estándar como en tags y chips.
- **Tarjetas de Guardarropa:** `24px` a `28px` en las esquinas exteriores, asegurando que las fotografías de prendas queden enmarcadas como camafeos contemporáneos.
- **Hojas Modales Inferiores (Bottom Sheets):** Esquinas superiores de `28px`, esquinas inferiores rectas a ras de pantalla.
- **Campos de Texto:** `16px` para mantener estructura sin perder fluidez.
- **Insignias y Chips de Categoría:** `16px` a píldora completa.

## Components

### Botones (Buttons)
- **Primario:** Silueta completa en píldora (`9999px`), fondo `#7B4BA6`, texto e icono `#FFFFFF`, altura fija de 48dp para cumplir objetivos táctiles. Efecto de pulsación (*ripple*) en tono `#C9A7EB` al 20% de opacidad.
- **Secundario / Tonal:** Fondo `#EDE4F7`, texto `#7B4BA6`, sin bordes.
- **Flotante (FAB):** Píldora o círculo suave de 56dp, color primario con micro-icono de lazo o destello junto a la acción "Añadir Prenda".

### Chips & Filtros de Atuendo
- **Inactivos:** Fondo `#FFFFFF` con borde sutil de 1dp en `#EDE4F7`, texto `#3B2A4A`.
- **Activos / Seleccionados:** Fondo `#C9A7EB` o `#7B4BA6`, texto contrastante, esquinas redondeadas a 16dp o píldora total. Acompañados de un icono fino indicador (como una chispa o tilde redondeada).

### Tarjetas de Ropa y Conjuntos (Wardrobe Cards)
- Superficie blanca inmaculada `#FFFFFF`, radio de `26px`.
- Área visual con relación de aspecto 3:4 para fotografía de prenda con esquinas interiores recortadas suavemente.
- Pie de tarjeta con título de prenda en `label-lg` (`#3B2A4A`) y subetiqueta de tela/temporada en tono secundario. 
- Icono flotante en esquina superior derecha para marcar favorito (silueta de corazón estilizado o destello de cuatro puntas).

### Campos de Entrada (Input Fields)
- Altura estándar de 52dp con radio de `16px`. Fondo contenedor `#F2EBFA` sin línea inferior tosca.
- Estado de reposo: texto en `#3B2A4A` con placeholder en ciruela translúcido (50%).
- Estado enfocado: borde continuo de 1.5dp en `#7B4BA6` y elevación con suave resplandor violeta.

### Listas y Selectores de Categoría
- Separadores no destructivos mediante espacios de `0.75rem` en lugar de líneas divisorias grises.
- Ítems de lista agrupados en tarjetas tipo isla (*inset grouped*) sobre el lienzo `#F6F1FB`.

### Hojas de Detalle (Modal Bottom Sheets)
- Agarre superior (*drag handle*) en forma de barra redondeada de 32dp x 4dp en color `#C9A7EB`.
- Encabezado con tipografía `headline-md` y acceso rápido a edición de etiqueta de prenda, ocasiones de uso y paleta de combinación sugerida.