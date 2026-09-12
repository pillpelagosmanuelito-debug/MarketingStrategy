# Diseño educativo

**Marketing Strategy Lab** · Simulador de decisiones comerciales para
estudiantes de Administración, Marketing y Negocios.

---

## 1. El problema, precisado

El enunciado de partida —"los estudiantes estudian marketing teóricamente, pero
tienen poca práctica tomando decisiones frente a mercados competitivos"— es
correcto, pero por sí solo produce un simulador genérico. La brecha real es más
específica y se puede nombrar:

> El estudiante sabe definir segmentación, posicionamiento y las cuatro P, pero
> nunca ha tenido que **renunciar** a un segmento, ni ha pagado el costo de
> decidir sin información, ni ha visto qué le pasa a una marca que promete más
> de lo que entrega.

Esa precisión cambió el diseño. El núcleo de la aplicación no es "simular una
empresa": es poner al estudiante frente a **tres decisiones que duelen** y
mostrarle la consecuencia.

| Decisión que duele | Cómo la fuerza el simulador |
|---|---|
| Renunciar a segmentos | Un producto promedio para todos rinde 20% a 90% menos que uno enfocado, en los tres escenarios |
| Pagar por información que no vende | Los estudios cuestan dinero real del presupuesto y devuelven estimaciones con error, nunca la verdad |
| Sostener una promesa con el producto | La satisfacción es entrega menos expectativa; prometer de más hunde la reputación y acelera el olvido de la marca |

---

## 2. Evaluación contra los ocho criterios del proyecto

| Criterio | Resultado |
|---|---|
| Valor educativo | **Alto.** Entrena juicio comercial bajo incertidumbre y restricción presupuestal, no memoria de definiciones. |
| Problema real | Documentado y transversal a tres carreras; el déficit de práctica decisional es la queja estándar de los egresados de marketing. |
| Usuario objetivo | Estudiantes de 4.º a 10.º ciclo que ya vieron el marco conceptual (4P, STP, investigación de mercados). |
| Competencia profesional | Segmentación, investigación de mercado, estrategia comercial, posicionamiento: las cuatro que pidió el encargo, y las cuatro que el informe de cierre mide por separado. |
| Experiencia de aprendizaje | Simulación con **información imperfecta y costosa**: es el rasgo que la distingue de cualquier hoja de cálculo. |
| Viabilidad técnica | Alta. Motor determinista, sin backend, sin costo por uso, funciona sin conexión. |
| Diferenciación | Los simuladores de marketing del mercado (Markstrat, Simbrand) son de escritorio, caros, en inglés y con licencia por estudiante. |
| Potencial de uso real | Alto. Una partida completa cabe en una sesión de 90 minutos. |

---

## 3. Diferenciación frente a la aplicación #30 del catálogo

El **Business Strategy Simulator** (#30) ya simula una empresa con precio,
calidad, marca y capacidad. Si esta aplicación repitiera ese modelo, sería la
misma app con otro nombre. La separación es deliberada y está en la unidad de
análisis:

| | #30 Business Strategy Simulator | Marketing Strategy Lab |
|---|---|---|
| Unidad de análisis | La empresa | **El segmento** |
| Pregunta central | ¿Mis decisiones son coherentes con mi estrategia genérica? | **¿A quién le estoy hablando y qué sabe él de mí?** |
| Demanda | Atractivo agregado frente a un competidor | **Elección discreta por segmento** (logit sobre cuatro segmentos con preferencias distintas) |
| Información | Todos los datos del mercado están a la vista | **Oculta y comprable**, con error de muestreo |
| Mecánica propia | Coherencia estratégica en el tiempo | **Promesa contra entrega**: lo que atrae y lo que retiene son cosas distintas |
| Falla característica | Estrategia incoherente | **Producto promedio para el cliente promedio** |

---

## 4. La mecánica central: promesa y entrega

Es la decisión de diseño que sostiene todo lo demás.

```
        promesa  ──────►  atractivo  ──────►  ventas
           │                                     │
           │                                     ▼
           └────── expectativa ◄──── satisfacción ◄──── producto real
                        │                 │
                        │                 ▼
                        │           reputación ───► atractivo del
                        │                            periodo siguiente
                        └── precio alto sube la expectativa
```

- **La promesa atrae.** Lo que el segmento percibe antes de comprar depende del
  beneficio prometido, del nivel de la promesa, del recuerdo de marca y de la
  claridad del posicionamiento.
- **El producto retiene.** La satisfacción compara lo entregado con lo esperado.
- **La reputación cierra el círculo.** Alimenta el atractivo del periodo
  siguiente y, por debajo de 45% de satisfacción, invierte el efecto de la
  publicidad: la marca se olvida más rápido de lo que la campaña la instala.

Un estudiante que descubre esto por sí mismo aprendió algo que ningún resumen
de las 4P le enseña.

---

## 5. Las cuatro competencias y cómo se miden

Cada una vale 25% del informe de cierre. Lo que se evalúa es **el proceso
comercial**, no el resultado: por eso el resultado económico pesa 45% dentro de
una sola competencia, es decir 11% de la nota final.

### Segmentación

| Componente | Peso | Qué mide |
|---|---|---|
| Foco en el objetivo | 40% | Qué proporción de las ventas salió del segmento declarado |
| Estabilidad del objetivo | 25% | Cuántas veces cambió de objetivo |
| Viabilidad del segmento | 35% | En cuántos periodos el ingreso del objetivo sostuvo la estructura de costos |

### Investigación de mercado

| Componente | Peso | Qué mide |
|---|---|---|
| Evidencia antes de decidir | 40% | Cuántos de los 4 estudios clave del objetivo compró en los primeros tres periodos |
| Eficiencia de la inversión | 30% | Que la investigación esté entre 3% y 20% del gasto comercial |
| Coherencia con la evidencia | 30% | Decisiones de medios y canales que contradicen un estudio ya pagado |

### Estrategia comercial

| Componente | Peso | Qué mide |
|---|---|---|
| Resultado económico | 45% | Utilidad acumulada contra la mejor estrategia verificada del escenario |
| Participación de mercado | 25% | Participación promedio en unidades |
| Sostenibilidad | 30% | Margen bruto sobre 20%; la quiebra la anula |

### Posicionamiento

| Componente | Peso | Qué mide |
|---|---|---|
| Coherencia promesa-producto | 40% | Distancia entre lo comunicado y lo entregado |
| Satisfacción del cliente | 35% | Satisfacción promedio de la partida |
| Claridad de marca alcanzada | 25% | Claridad final, que solo crece con repetición |

---

## 6. Los tres escenarios y su lección

Cada escenario premia una estrategia distinta, y eso está **verificado con
pruebas automatizadas** que juegan partidas completas, no afirmado en un
documento.

| Escenario | Estrategia ganadora | Lección |
|---|---|---|
| Bebida funcional | Nicho de alto valor (deportistas o jóvenes) | Cuando el líder domina el volumen con costos que no puedes igualar, pelear por volumen es jugar su partido |
| Mochilas escolares | Penetración masiva | El peso del mercado está abajo: copiar el manual premium en un mercado de precio es el error caro |
| Academia en línea | Segmento desatendido (trabajador que estudia) | El territorio del líder no se ataca de frente; y reposicionar tarde cuesta credibilidad y no recupera la ventaja |

Medición final (utilidad acumulada en 8 periodos, mismas condiciones):

| Estrategia | Bebida | Mochilas | Academia |
|---|---|---|---|
| Nicho premium | 5.00 M | 3.76 M | 2.64 M |
| Imagen / estatus | **5.31 M** | 4.60 M | — |
| Penetración masiva | 0.78 M | **8.14 M** | 1.24 M |
| Segmento desatendido | — | — | **3.11 M** |
| Promedio para todos | 3.90 M | −0.02 M | 2.23 M |
| Promesa incumplida | 1.95 M | 0.72 M | 0.35 M |
| Decidir a ciegas | 2.37 M | quiebra | 1.08 M |
| Sin inversión en medios | −0.82 M | −0.56 M | quiebra |
| Precio bajo el costo | quiebra | quiebra | quiebra |

**Ninguna estrategia gana en los tres.** Eso es lo que impide que el curso se
resuelva con una receta memorizada.

---

## 7. Recorrido del estudiante

1. **Elige mercado y nombra su marca.** Lee el briefing: solo información
   pública (tamaño total de la categoría, competidores instalados).
2. **Módulo Mercado.** Contrata estudios. Cada uno cuesta y devuelve una
   estimación con error. Aquí ya está decidiendo: qué vale la pena saber.
3. **Módulo Cliente.** Elige segmento objetivo y define la promesa. La
   aplicación le dice si su promesa coincide con lo que ese segmento busca
   **solo si compró el perfil**.
4. **Módulos Producto, Precio y Campañas.** Construye la mezcla. Cada pantalla
   muestra la lectura que corresponde: costo unitario, punto de equilibrio,
   precio relativo, afinidad de medios, cobertura de canales.
5. **Consulta al analista** cuando quiera. Recibe observaciones ordenadas por
   gravedad, cada una con su fundamento y su evidencia.
6. **Cierra el periodo.** Ve ventas, satisfacción y participación por segmento,
   más el estado de resultados completo.
7. **Repite ocho veces.** Los eventos del mercado y la reacción de los
   competidores cambian el tablero.
8. **Informe de cierre.** Cuatro competencias, sus componentes, y recién
   entonces la lección del escenario.

---

## 8. Por qué la lección se revela al final

Si el escenario dijera de entrada "aquí gana el nicho premium", el estudiante
resolvería el ejercicio leyendo en vez de decidiendo. La lección aparece en el
informe de cierre, cuando ya tiene una experiencia propia contra la cual
contrastarla. Es la diferencia entre que le cuenten una conclusión y que la
reconozca.

---

## 9. Lo que el simulador NO enseña

Declararlo es parte del diseño honesto:

- **No enseña a hacer investigación de mercados.** Enseña a decidir qué
  investigar y a usar el resultado; no a diseñar un cuestionario ni a elegir
  una muestra.
- **No enseña creatividad publicitaria.** El contenido de la campaña no existe
  en el modelo: solo el medio, el monto y la afinidad.
- **No enseña negociación con canales.** Los márgenes de canal son un dato, no
  algo que se negocie.
- **No reemplaza un caso real.** Un simulador comprime el tiempo y elimina la
  ambigüedad del mundo; es un complemento del caso, no su sustituto.
