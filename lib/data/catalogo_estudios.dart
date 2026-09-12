import '../domain/models/estudio.dart';

/// Estudios de mercado que el estudiante puede contratar.
///
/// Los precios estan calibrados contra el presupuesto del periodo: contratar
/// todo, todos los periodos, consume alrededor de un tercio de la inversion
/// disponible en medios. Investigar no es gratis y no vende por si solo:
/// evita errores de puntería, que es distinto.
class CatalogoEstudios {
  const CatalogoEstudios._();

  static const Estudio tamano = Estudio(
    id: 'tamano',
    nombre: 'Estudio de tamano de mercado',
    descripcion:
        'Estima cuantos compradores potenciales tiene cada segmento por '
        'periodo. Es la primera pregunta de cualquier plan: a cuanta gente le '
        'puedo vender.',
    costo: 12000,
    tipo: TipoEstudio.tamanoMercado,
    porSegmento: false,
    errorBase: 0.20,
  );

  static const Estudio perfil = Estudio(
    id: 'perfil',
    nombre: 'Perfil del segmento',
    descripcion:
        'Entrevistas y encuesta a un segmento: que beneficio busca y cuanto '
        'pesa cada atributo en su decision de compra.',
    costo: 18000,
    tipo: TipoEstudio.perfilSegmento,
    porSegmento: true,
    errorBase: 0.16,
  );

  static const Estudio precio = Estudio(
    id: 'precio',
    nombre: 'Prueba de precio',
    descripcion:
        'Mide el precio de referencia del segmento y cuanto castiga alejarse '
        'de el. Sin este dato, fijar precio es adivinar.',
    costo: 15000,
    tipo: TipoEstudio.pruebaPrecio,
    porSegmento: true,
    errorBase: 0.14,
  );

  static const Estudio canales = Estudio(
    id: 'canales',
    nombre: 'Auditoria de canales',
    descripcion:
        'Donde compra realmente este segmento. Evita pagar por estar en un '
        'canal al que el objetivo no entra.',
    costo: 14000,
    tipo: TipoEstudio.auditoriaCanales,
    porSegmento: true,
    errorBase: 0.18,
  );

  static const Estudio medios = Estudio(
    id: 'medios',
    nombre: 'Habitos de medios',
    descripcion:
        'Que medios consume el segmento. Es la diferencia entre una campana '
        'vista y una campana pagada.',
    costo: 10000,
    tipo: TipoEstudio.habitosMedios,
    porSegmento: true,
    errorBase: 0.18,
  );

  static const Estudio mystery = Estudio(
    id: 'mystery',
    nombre: 'Mystery shopper de la competencia',
    descripcion:
        'Precio, calidad percibida y promesa de cada competidor, levantados '
        'en punto de venta.',
    costo: 16000,
    tipo: TipoEstudio.mysteryShopper,
    porSegmento: false,
    errorBase: 0.12,
  );

  static const Estudio marca = Estudio(
    id: 'marca',
    nombre: 'Estudio de marca y satisfaccion',
    descripcion:
        'Recuerdo de marca por segmento, satisfaccion de quienes ya compraron '
        'y claridad del posicionamiento. Solo tiene sentido despues de haber '
        'vendido al menos un periodo.',
    costo: 11000,
    tipo: TipoEstudio.satisfaccionMarca,
    porSegmento: false,
    errorBase: 0.15,
    desdePeriodo: 1,
  );

  static const List<Estudio> todos = <Estudio>[
    tamano,
    perfil,
    precio,
    canales,
    medios,
    mystery,
    marca,
  ];

  static Estudio? porId(String id) {
    for (final Estudio e in todos) {
      if (e.id == id) return e;
    }
    return null;
  }
}
