# Marketing Strategy Lab

Simulador de decisiones comerciales para estudiantes universitarios de
**Administración, Marketing y Negocios**. El estudiante dirige una marca
durante ocho periodos: elige a qué segmento se dirige, qué le promete, qué
producto entrega, a qué precio, en qué canales y con qué medios. Nadie le dice
qué quiere cada segmento: esa información se compra, cuesta dinero y viene con
error de muestreo.

**Stack:** Flutter 3.24.5 · Dart 3 · MVVM · una sola dependencia externa
(`shared_preferences`) · funciona sin conexión.

---

## Qué lo distingue de un simulador de empresa

| | Simulador de empresa típico | Marketing Strategy Lab |
|---|---|---|
| Unidad de análisis | La empresa | **El segmento** |
| Información del mercado | Visible | **Oculta, comprable y con error** |
| Qué atrae al cliente | El producto | **La promesa** |
| Qué lo retiene | — | **El producto**, vía satisfacción y reputación |
| Falla que enseña | Estrategia incoherente | **El producto promedio para el cliente promedio** |

---

## Los cinco módulos

| # | Módulo | Decisión |
|---|---|---|
| 1 | **Mercado** | Contratar estudios: tamaño, perfil, precio, canales, medios, mystery shopper, marca |
| 2 | **Cliente** | Segmento objetivo, beneficio prometido y nivel de la promesa |
| 3 | **Producto** | Calidad, beneficio real entregado, amplitud de línea |
| 4 | **Precio** | Precio de venta, leído contra el costo, la estructura y la referencia del segmento |
| 5 | **Campañas** | Inversión por medio y selección de canales |

Más el **analista de marketing**: 30 reglas y una proyección que corre el mismo
motor sobre el mercado *estimado por el estudiante*. No es un modelo
generativo, y no puede filtrar datos ocultos porque no los recibe.

---

## Los tres escenarios

| Escenario | Categoría | Lección |
|---|---|---|
| Bebida funcional embotellada | Consumo masivo | El nicho de valor vence al volumen cuando el líder domina el segmento masivo |
| Mochilas escolares y urbanas | Retail estacional | Aquí el peso está abajo: la penetración masiva rinde más del doble que el premium |
| Academia preuniversitaria en línea | Servicios educativos | No ataques de frente el territorio del líder; y reposicionar tarde no recupera la ventaja |

**Ninguna estrategia gana en los tres.** Está verificado con pruebas que juegan
partidas completas, no afirmado en un documento.

---

## Instalación y uso

```bash
flutter pub get
flutter test          # 9 suites
flutter analyze
flutter run
```

Para compilar el APK:

```bash
flutter create --project-name marketing_strategy_lab --org pe.educacion --platforms=android .
python3 tool/generar_icono.py android/app/src/main/res
flutter build apk --release
```

El repositorio **no versiona la carpeta `android/`** a propósito: la genera
Flutter para la versión exacta del SDK que se esté usando, y así el proyecto no
arrastra una configuración de Gradle desactualizada. GitHub Actions hace
exactamente estos tres pasos en cada push y publica el APK como artefacto.

---

## Verificar el motor

El modelo se calibró en Python antes de escribir Dart, y después el código Dart
entregado se transcribió de vuelta a Python para verificar que reproduce la
calibración:

```bash
python3 tool/calibracion/comparar.py
# IDENTICOS  (diferencia máxima entre las 25 políticas: 0.00 soles)

python3 tool/calibracion/run.py           # tabla de estrategias por escenario
python3 tool/calibracion/generar_dart.py  # regenera lib/data/catalogo_mercados.dart
```

Esa comparación corre en CI. Si alguien toca un parámetro del motor sin
actualizar la calibración, el trabajo falla.

---

## Estructura

```
lib/
├── core/            Tema, formato, widgets propios, generador determinista
├── domain/
│   ├── models/      13 modelos serializables
│   └── engine/      Motor puro, investigación, estimador, analista, evaluador
├── data/            Catálogo de mercados (generado), estudios, repositorio
└── features/        12 pantallas + VmPartida
test/                9 suites
docs/                Diseño educativo, arquitectura, modelo, guía docente
tool/                Generador de icono y prototipo de calibración
```

---

## Documentación

| Documento | Contenido |
|---|---|
| [`docs/01_diseno_educativo.md`](docs/01_diseno_educativo.md) | Problema, competencias, diferenciación, lecciones de cada escenario y lo que **no** enseña |
| [`docs/02_arquitectura.md`](docs/02_arquitectura.md) | Capas, frontera de honestidad, persistencia, evolución |
| [`docs/03_modelo_de_simulacion.md`](docs/03_modelo_de_simulacion.md) | Todas las ecuaciones y parámetros, calibración y limitaciones declaradas |
| [`docs/04_guia_docente.md`](docs/04_guia_docente.md) | Cómo usarlo en clase, qué mirar, preguntas de discusión, evaluación |

---

## Licencia

MIT. Ver [`LICENSE`](LICENSE).
