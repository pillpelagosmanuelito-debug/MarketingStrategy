# Demostración web del motor

`index.html` es una página autónoma que corre **el mismo modelo de simulación**
que la aplicación Flutter, con los mismos parámetros calibrados. Sirve para
probar el simulador sin compilar nada: se abre en cualquier navegador.

Diferencias con la aplicación entregada:

| | Demo web | Aplicación Flutter |
|---|---|---|
| Motor de simulación | Idéntico (verificado: mismas utilidades hasta el sol) | Idéntico |
| Escenarios | Los tres | Los tres |
| Reglas del analista | 12 | 30 |
| Informe de cierre | Cuatro competencias, puntaje global | Competencias con componentes, comentarios y detalle |
| Persistencia | No (se reinicia al recargar) | Sí, con historial de partidas |
| Historial gráfico | No | Sí |

La verificación de que el motor JavaScript reproduce la calibración está en el
propio flujo de trabajo: las utilidades acumuladas de las tres políticas de
referencia coinciden con `tool/calibracion/run.py` con una diferencia menor a
un sol en ocho periodos.
