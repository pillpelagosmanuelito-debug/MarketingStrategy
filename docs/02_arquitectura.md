# Arquitectura técnica

**Stack:** Flutter 3.24.5 · Dart 3 · MVVM ligero · `shared_preferences` como
única dependencia externa.

---

## 1. Criterio de diseño

Tres reglas gobiernan la estructura:

1. **El motor es una función pura.** No conoce Flutter, no guarda estado global
   y no hace entrada/salida. Se le entrega el mercado, las decisiones y la
   memoria de las marcas, y devuelve el resultado del periodo. Esa pureza es lo
   que permite correrlo miles de veces en las pruebas de calibración.
2. **La vista no conoce el motor.** Toda la interfaz habla con `VmPartida`.
   Ninguna pantalla importa `MotorSimulacion`, `RepositorioPartida` ni el
   catálogo directamente.
3. **El analista no conoce el mercado.** Recibe un `MercadoEstimado` construido
   con lo que el estudiante compró. Es una restricción de tipos, no una
   disciplina de programación.

---

## 2. Capas

```
┌───────────────────────────────────────────────────────────────┐
│  features/                                                     │
│  12 pantallas · InheritedNotifier (AlcancePartida)              │
│  inicio · panel · mercado · cliente · producto · precio ·       │
│  campañas · analista · resultados · historial · cierre ·        │
│  conceptos                                                      │
└───────────────────────────┬───────────────────────────────────┘
                            │  lee estado, envía decisiones
┌───────────────────────────▼───────────────────────────────────┐
│  VmPartida  (ChangeNotifier)                                   │
│  Único punto que la interfaz conoce. Orquesta motor,            │
│  investigación, analista, evaluador y repositorio.              │
└───────┬──────────────────────────────────┬────────────────────┘
        │                                  │
┌───────▼──────────────┐         ┌─────────▼─────────────────────┐
│  domain/engine/      │         │  data/                         │
│  MotorSimulacion     │         │  CatalogoMercados (generado)   │
│  Investigacion       │         │  CatalogoEstudios              │
│  MercadoEstimado     │         │  RepositorioPartida            │
│  AnalistaMarketing   │         │  (shared_preferences)          │
│  Evaluador           │         └────────────────────────────────┘
│  Parametros          │
└───────┬──────────────┘
┌───────▼───────────────────────────────────────────────────────┐
│  domain/models/                                                │
│  Segmento · Decisiones · EstadoMarca · Competidor · Evento ·   │
│  Mercado · EstadoMercado · ResultadoPeriodo · Estudio ·        │
│  Hallazgo · Partida · Beneficio · Medio · Canal                │
└───────────────────────────────────────────────────────────────┘
```

---

## 3. Estructura de carpetas

```
lib/
├── main.dart                       Punto de entrada
├── app.dart                        AlcancePartida (InheritedNotifier) + enrutador
├── core/
│   ├── tema.dart                   Paleta y tipografía
│   ├── formato.dart                Soles, porcentajes, miles
│   ├── aleatorio.dart              Generador determinista (solo investigación)
│   └── widgets/                    Tarjeta, Metrica, BarraValor, GraficoEvolucion
├── domain/
│   ├── models/                     13 modelos, todos serializables
│   └── engine/
│       ├── parametros.dart         Todas las constantes del modelo
│       ├── motor_simulacion.dart   Simulación pura
│       ├── investigacion.dart      Estudios con error de muestreo
│       ├── estimador.dart          MercadoEstimado: frontera de honestidad
│       ├── analista.dart           30 reglas + proyección
│       └── evaluador.dart          4 competencias
├── data/
│   ├── catalogo_mercados.dart      GENERADO desde la calibración
│   ├── catalogo_estudios.dart
│   └── repositorio_partida.dart
└── features/                       12 pantallas + VmPartida
```

---

## 4. Gestión de estado

Un solo `ChangeNotifier` (`VmPartida`) expuesto con `InheritedNotifier`. No se
agregó un paquete de inyección de dependencias porque la aplicación tiene un
único ViewModel con estado global: agregar Provider o Riverpod sería costo sin
beneficio.

```dart
final VmPartida vm = AlcancePartida.de(context);
vm.fijarPrecio(7.40);   // muta, guarda y notifica
```

Cada mutación persiste la partida. No hay botón de guardar: el estudiante puede
cerrar la aplicación en cualquier punto del periodo y retomar donde estaba.

---

## 5. Frontera de honestidad

Es la decisión arquitectónica más importante del proyecto.

```dart
// El analista NO puede recibir el mercado real: la firma no lo permite.
static List<Consejo> analizar(Partida partida, MercadoEstimado estimado)
```

`MercadoEstimado.construir(partida, real)` es el único lugar que lee el mercado
verdadero, y lo hace para **degradarlo**: donde hay estudio, usa el valor ya
ruidoso que guardó el hallazgo; donde no lo hay, usa un supuesto neutral y lo
registra en `supuestos`.

| Dato sin estudio | Supuesto neutral |
|---|---|
| Tamaño del segmento | Total declarado ÷ número de segmentos |
| Precio de referencia | El precio actual del estudiante |
| Pesos de decisión | 0.25 cada uno |
| Beneficio buscado | El que el estudiante promete |
| Afinidad de medios y canales | 0.30 |
| Recuerdo y reputación de rivales | 0.45 y 0.55 |

La proyección del analista corre **el mismo motor** sobre ese mercado estimado.
Con pocos estudios, se equivoca; y esa equivocación es parte de lo que enseña.

---

## 6. Persistencia

`RepositorioPartida` es la única frontera de almacenamiento. Guarda dos cosas:

- `msl_partida_actual`: la partida en curso, en JSON.
- `msl_historial`: hasta 20 resúmenes de partidas terminadas.

La partida guardada **identifica el mercado por id**: la definición del
escenario (pesos, precios de referencia, sensibilidades) vive en el catálogo y
no viaja al almacenamiento del teléfono. Lo único con datos de mercado que se
guarda son los hallazgos que el estudiante pagó, que son sus propias
estimaciones con error. Está verificado en `test/modelos_test.dart`.

Una partida guardada con un formato anterior no impide abrir la aplicación: se
descarta y se empieza de nuevo.

---

## 7. Frontera de evolución

`VmPartida` y `RepositorioPartida` son los dos puntos que habría que tocar para
las evoluciones previsibles, y ninguna toca la interfaz:

| Evolución | Qué cambia |
|---|---|
| Panel docente con resultados del aula | `RepositorioPartida` pasa a hablar con un backend |
| Simulación en servidor (anti-trampa) | `VmPartida.cerrarPeriodo()` llama a una API; el motor ya es puro |
| Nuevos escenarios | Un bloque más en el prototipo de calibración y regenerar `catalogo_mercados.dart` |
| Analista híbrido con LLM | Las reglas siguen siendo la fuente de verdad; el modelo solo redacta el texto de `Consejo` |

---

## 8. Archivo generado

`lib/data/catalogo_mercados.dart` **no se edita a mano**. Lo genera
`tool/calibracion/generar_dart.py` desde el prototipo con el que se calibró el
motor. Es lo que garantiza que los números del simulador no puedan separarse de
los números con los que se verificó que enseña lo que dice enseñar.

```bash
python3 tool/calibracion/generar_dart.py    # regenera el catálogo
python3 tool/calibracion/comparar.py        # verifica motor Dart vs calibración
```

`test/mercados_test.dart` existe justamente para que una edición manual de ese
archivo no pase desapercibida.

---

## 9. Pruebas

| Suite | Qué protege |
|---|---|
| `motor_test.dart` | Cada pieza del motor, con valores esperados sacados de la calibración |
| `calibracion_test.dart` | **Las propiedades educativas**: qué estrategia gana en cada escenario |
| `analista_test.dart` | La frontera de honestidad y el disparo de las reglas |
| `evaluador_test.dart` | Que el informe ordene correctamente partidas buenas y malas |
| `investigacion_test.dart` | Que los estudios nunca den el valor exacto y sean deterministas |
| `modelos_test.dart` | Ida y vuelta por JSON de toda la partida |
| `mercados_test.dart` | Integridad del catálogo generado |
| `repositorio_test.dart` | Persistencia y ciclo de vida del ViewModel |
| `interfaz_test.dart` | Que la aplicación arranque y el tablero muestre los cinco módulos |

---

## 10. Dependencias

Una sola: `shared_preferences`. Los gráficos se dibujan con `CustomPainter`
(cuarenta líneas) en vez de agregar una librería de charts, y el icono se genera
con la biblioteca estándar de Python en vez de depender de un paquete de
imágenes. Cada dependencia que no se agrega es una que no hay que mantener ni
auditar.
