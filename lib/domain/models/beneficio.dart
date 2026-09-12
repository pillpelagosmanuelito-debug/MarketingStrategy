/// Beneficio buscado por un segmento y prometido por una marca.
///
/// El beneficio es el eje de posicionamiento del simulador: un segmento compra
/// por un beneficio y una marca promete uno. La distancia entre ambos decide
/// cuanto atrae la marca; la distancia entre lo prometido y lo entregado decide
/// la satisfaccion.
enum Beneficio {
  salud('salud', 'Salud y bienestar'),
  energia('energia', 'Energia y rendimiento inmediato'),
  precio('precio', 'Precio accesible'),
  estatus('estatus', 'Imagen y estatus'),
  rendimiento('rendimiento', 'Desempeno y resultados'),
  flexibilidad('flexibilidad', 'Flexibilidad y conveniencia');

  const Beneficio(this.id, this.etiqueta);

  final String id;
  final String etiqueta;

  static Beneficio desdeId(String id) {
    return Beneficio.values.firstWhere(
      (b) => b.id == id,
      orElse: () => Beneficio.precio,
    );
  }
}
