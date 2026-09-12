import 'package:marketing_strategy_lab/domain/models/beneficio.dart';
import 'package:marketing_strategy_lab/domain/models/canal.dart';
import 'package:marketing_strategy_lab/domain/models/decisiones.dart';
import 'package:marketing_strategy_lab/domain/models/medio.dart';

import 'ayuda_simulacion.dart';

/// Politicas completas usadas por las pruebas de calibracion.
///
/// Son las mismas que se corrieron en el prototipo de calibracion
/// (`tool/calibracion/`): si alguien cambia un parametro del motor, estas
/// politicas dejan de ordenarse como el escenario dice que deben ordenarse y
/// las pruebas fallan.
class Politicas {
  const Politicas._();

  static Decisiones Function(int) fija(Decisiones d) =>
      (int periodo) => d;

  // -------------------------------------------------------------- bebida

  static Decisiones nichoPremiumBebida = decisiones(
    objetivo: 'fitness',
    promesa: Beneficio.rendimiento,
    nivel: 4.5,
    calidad: 4.4,
    real: Beneficio.rendimiento,
    amplitud: 1,
    precio: 7.4,
    canales: <Canal>{Canal.retail, Canal.propio, Canal.marketplace},
    medios: <Medio, double>{
      Medio.digital: 34000,
      Medio.influencers: 30000,
      Medio.puntoVenta: 6000,
    },
  );

  static Decisiones imagenJovenBebida = decisiones(
    objetivo: 'joven',
    promesa: Beneficio.estatus,
    nivel: 4.2,
    calidad: 3.8,
    real: Beneficio.estatus,
    amplitud: 1,
    precio: 7.6,
    canales: <Canal>{Canal.retail, Canal.marketplace, Canal.propio},
    medios: <Medio, double>{Medio.influencers: 40000, Medio.digital: 28000},
  );

  static Decisiones masivoBaratoBebida = decisiones(
    objetivo: 'familia',
    promesa: Beneficio.precio,
    nivel: 2.0,
    calidad: 2.2,
    real: Beneficio.precio,
    amplitud: 3,
    precio: 3.1,
    canales: <Canal>{Canal.bodegas, Canal.mayorista, Canal.retail},
    medios: <Medio, double>{
      Medio.tv: 45000,
      Medio.radio: 25000,
      Medio.puntoVenta: 14000,
    },
  );

  static Decisiones promedioBebida = decisiones(
    objetivo: 'oficina',
    promesa: Beneficio.energia,
    nivel: 3.0,
    calidad: 3.0,
    real: Beneficio.energia,
    amplitud: 2,
    precio: 5.0,
    canales: <Canal>{
      Canal.retail,
      Canal.bodegas,
      Canal.marketplace,
      Canal.propio,
      Canal.mayorista
    },
    medios: <Medio, double>{
      Medio.tv: 18000,
      Medio.radio: 18000,
      Medio.digital: 18000,
      Medio.influencers: 18000,
      Medio.puntoVenta: 18000,
    },
  );

  static Decisiones promesaIncumplidaBebida = decisiones(
    objetivo: 'fitness',
    promesa: Beneficio.rendimiento,
    nivel: 5.0,
    calidad: 2.0,
    real: Beneficio.precio,
    amplitud: 1,
    precio: 7.4,
    canales: <Canal>{Canal.retail, Canal.propio, Canal.marketplace},
    medios: <Medio, double>{
      Medio.digital: 34000,
      Medio.influencers: 30000,
      Medio.puntoVenta: 6000,
    },
  );

  static Decisiones regaladoBebida = decisiones(
    objetivo: 'familia',
    promesa: Beneficio.precio,
    nivel: 2.0,
    calidad: 2.2,
    real: Beneficio.precio,
    amplitud: 3,
    precio: 1.9,
    canales: <Canal>{Canal.bodegas, Canal.mayorista, Canal.retail},
    medios: <Medio, double>{
      Medio.tv: 45000,
      Medio.radio: 25000,
      Medio.puntoVenta: 14000,
    },
  );

  static Decisiones sinMediosBebida = decisiones(
    objetivo: 'fitness',
    promesa: Beneficio.rendimiento,
    nivel: 4.5,
    calidad: 4.4,
    real: Beneficio.rendimiento,
    amplitud: 1,
    precio: 7.4,
    canales: <Canal>{Canal.retail, Canal.propio, Canal.marketplace},
    medios: <Medio, double>{},
  );

  /// Buena mezcla para un segmento premium, pero apuntada al segmento
  /// equivocado: es lo que pasa cuando se decide sin investigar.
  static Decisiones aCiegasBebida = decisiones(
    objetivo: 'familia',
    promesa: Beneficio.precio,
    nivel: 2.0,
    calidad: 2.2,
    real: Beneficio.precio,
    amplitud: 3,
    precio: 6.9,
    canales: <Canal>{Canal.retail, Canal.propio, Canal.marketplace},
    medios: <Medio, double>{
      Medio.digital: 34000,
      Medio.influencers: 30000,
      Medio.puntoVenta: 6000,
    },
  );

  // ------------------------------------------------------------ mochilas

  static Decisiones nichoPremiumMochilas = decisiones(
    objetivo: 'privado',
    promesa: Beneficio.salud,
    nivel: 4.5,
    calidad: 4.4,
    real: Beneficio.salud,
    amplitud: 1,
    precio: 132.0,
    canales: <Canal>{Canal.retail, Canal.marketplace, Canal.propio},
    medios: <Medio, double>{
      Medio.digital: 40000,
      Medio.influencers: 24000,
      Medio.puntoVenta: 8000,
    },
  );

  static Decisiones imagenJovenMochilas = decisiones(
    objetivo: 'universitario',
    promesa: Beneficio.estatus,
    nivel: 4.2,
    calidad: 3.8,
    real: Beneficio.estatus,
    amplitud: 1,
    precio: 158.0,
    canales: <Canal>{Canal.marketplace, Canal.propio, Canal.retail},
    medios: <Medio, double>{Medio.influencers: 44000, Medio.digital: 30000},
  );

  static Decisiones masivoBaratoMochilas = decisiones(
    objetivo: 'publico',
    promesa: Beneficio.precio,
    nivel: 2.2,
    calidad: 2.4,
    real: Beneficio.precio,
    amplitud: 3,
    precio: 43.0,
    canales: <Canal>{Canal.mayorista, Canal.bodegas, Canal.retail},
    medios: <Medio, double>{
      Medio.radio: 40000,
      Medio.tv: 42000,
      Medio.puntoVenta: 16000,
    },
  );

  static Decisiones promedioMochilas = decisiones(
    objetivo: 'publico',
    promesa: Beneficio.precio,
    nivel: 3.0,
    calidad: 3.0,
    real: Beneficio.precio,
    amplitud: 2,
    precio: 78.0,
    canales: <Canal>{
      Canal.retail,
      Canal.bodegas,
      Canal.marketplace,
      Canal.propio,
      Canal.mayorista
    },
    medios: <Medio, double>{
      Medio.tv: 20000,
      Medio.radio: 20000,
      Medio.digital: 20000,
      Medio.influencers: 20000,
      Medio.puntoVenta: 20000,
    },
  );

  static Decisiones promesaIncumplidaMochilas = decisiones(
    objetivo: 'privado',
    promesa: Beneficio.salud,
    nivel: 5.0,
    calidad: 2.0,
    real: Beneficio.precio,
    amplitud: 1,
    precio: 132.0,
    canales: <Canal>{Canal.retail, Canal.marketplace, Canal.propio},
    medios: <Medio, double>{
      Medio.digital: 40000,
      Medio.influencers: 24000,
      Medio.puntoVenta: 8000,
    },
  );

  static Decisiones regaladoMochilas = decisiones(
    objetivo: 'publico',
    promesa: Beneficio.precio,
    nivel: 2.2,
    calidad: 2.4,
    real: Beneficio.precio,
    amplitud: 3,
    precio: 20.0,
    canales: <Canal>{Canal.mayorista, Canal.bodegas, Canal.retail},
    medios: <Medio, double>{
      Medio.radio: 40000,
      Medio.tv: 42000,
      Medio.puntoVenta: 16000,
    },
  );

  static Decisiones sinMediosMochilas = decisiones(
    objetivo: 'publico',
    promesa: Beneficio.precio,
    nivel: 2.2,
    calidad: 2.4,
    real: Beneficio.precio,
    amplitud: 3,
    precio: 43.0,
    canales: <Canal>{Canal.mayorista, Canal.bodegas, Canal.retail},
    medios: <Medio, double>{},
  );

  static Decisiones aCiegasMochilas = decisiones(
    objetivo: 'privado',
    promesa: Beneficio.salud,
    nivel: 4.5,
    calidad: 4.4,
    real: Beneficio.salud,
    amplitud: 1,
    precio: 132.0,
    canales: <Canal>{Canal.mayorista, Canal.bodegas},
    medios: <Medio, double>{
      Medio.radio: 40000,
      Medio.tv: 42000,
      Medio.puntoVenta: 16000,
    },
  );

  // ------------------------------------------------------------ academia

  static Decisiones nichoPremiumAcademia = decisiones(
    objetivo: 'postulante',
    promesa: Beneficio.rendimiento,
    nivel: 4.6,
    calidad: 4.5,
    real: Beneficio.rendimiento,
    amplitud: 1,
    precio: 195.0,
    canales: <Canal>{Canal.propio, Canal.marketplace},
    medios: <Medio, double>{
      Medio.digital: 46000,
      Medio.influencers: 18000,
      Medio.puntoVenta: 6000,
    },
  );

  static Decisiones flexibleAcademia = decisiones(
    objetivo: 'trabajador',
    promesa: Beneficio.flexibilidad,
    nivel: 3.8,
    calidad: 3.8,
    real: Beneficio.flexibilidad,
    amplitud: 2,
    precio: 128.0,
    canales: <Canal>{Canal.propio, Canal.marketplace},
    medios: <Medio, double>{
      Medio.digital: 44000,
      Medio.radio: 18000,
      Medio.influencers: 8000,
    },
  );

  static Decisiones masivoBaratoAcademia = decisiones(
    objetivo: 'repitente',
    promesa: Beneficio.precio,
    nivel: 2.2,
    calidad: 2.4,
    real: Beneficio.precio,
    amplitud: 3,
    precio: 74.0,
    canales: <Canal>{Canal.propio, Canal.marketplace, Canal.bodegas},
    medios: <Medio, double>{
      Medio.radio: 30000,
      Medio.digital: 26000,
      Medio.tv: 14000,
    },
  );

  static Decisiones promedioAcademia = decisiones(
    objetivo: 'trabajador',
    promesa: Beneficio.flexibilidad,
    nivel: 3.0,
    calidad: 3.0,
    real: Beneficio.flexibilidad,
    amplitud: 2,
    precio: 140.0,
    canales: <Canal>{
      Canal.retail,
      Canal.bodegas,
      Canal.marketplace,
      Canal.propio,
      Canal.mayorista
    },
    medios: <Medio, double>{
      Medio.tv: 16000,
      Medio.radio: 16000,
      Medio.digital: 16000,
      Medio.influencers: 16000,
      Medio.puntoVenta: 16000,
    },
  );

  static Decisiones promesaIncumplidaAcademia = decisiones(
    objetivo: 'postulante',
    promesa: Beneficio.rendimiento,
    nivel: 5.0,
    calidad: 2.0,
    real: Beneficio.precio,
    amplitud: 1,
    precio: 195.0,
    canales: <Canal>{Canal.propio, Canal.marketplace},
    medios: <Medio, double>{
      Medio.digital: 46000,
      Medio.influencers: 18000,
      Medio.puntoVenta: 6000,
    },
  );

  static Decisiones regaladoAcademia = decisiones(
    objetivo: 'repitente',
    promesa: Beneficio.precio,
    nivel: 2.2,
    calidad: 2.4,
    real: Beneficio.precio,
    amplitud: 3,
    precio: 34.0,
    canales: <Canal>{Canal.propio, Canal.marketplace, Canal.bodegas},
    medios: <Medio, double>{
      Medio.radio: 30000,
      Medio.digital: 26000,
      Medio.tv: 14000,
    },
  );

  static Decisiones sinMediosAcademia = decisiones(
    objetivo: 'postulante',
    promesa: Beneficio.rendimiento,
    nivel: 4.6,
    calidad: 4.5,
    real: Beneficio.rendimiento,
    amplitud: 1,
    precio: 195.0,
    canales: <Canal>{Canal.propio, Canal.marketplace},
    medios: <Medio, double>{},
  );

  static Decisiones aCiegasAcademia = decisiones(
    objetivo: 'escolar',
    promesa: Beneficio.estatus,
    nivel: 4.2,
    calidad: 4.5,
    real: Beneficio.rendimiento,
    amplitud: 1,
    precio: 195.0,
    canales: <Canal>{Canal.propio, Canal.marketplace},
    medios: <Medio, double>{
      Medio.radio: 46000,
      Medio.tv: 18000,
      Medio.puntoVenta: 6000,
    },
  );
}
