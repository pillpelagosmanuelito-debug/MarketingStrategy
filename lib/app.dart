import 'package:flutter/material.dart';

import 'core/tema.dart';
import 'features/cierre/vista_cierre.dart';
import 'features/inicio/vista_inicio.dart';
import 'features/panel/vista_panel.dart';
import 'features/panel/vm_partida.dart';

/// Expone el ViewModel de la partida a todo el arbol de widgets.
///
/// Se usa `InheritedNotifier` en lugar de un paquete de inyeccion de
/// dependencias porque la aplicacion tiene un solo ViewModel con estado global
/// y agregar una dependencia para eso seria costo sin beneficio.
class AlcancePartida extends InheritedNotifier<VmPartida> {
  const AlcancePartida({
    super.key,
    required VmPartida vm,
    required super.child,
  }) : super(notifier: vm);

  static VmPartida de(BuildContext contexto) {
    final AlcancePartida? alcance =
        contexto.dependOnInheritedWidgetOfExactType<AlcancePartida>();
    assert(alcance != null, 'No hay AlcancePartida en el arbol de widgets');
    return alcance!.notifier!;
  }
}

class AplicacionMSL extends StatefulWidget {
  const AplicacionMSL({super.key});

  @override
  State<AplicacionMSL> createState() => _AplicacionMSLState();
}

class _AplicacionMSLState extends State<AplicacionMSL> {
  late final VmPartida _vm;

  @override
  void initState() {
    super.initState();
    _vm = VmPartida();
    _vm.iniciar();
  }

  @override
  void dispose() {
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlcancePartida(
      vm: _vm,
      child: MaterialApp(
        title: 'Marketing Strategy Lab',
        debugShowCheckedModeBanner: false,
        theme: Tema.construir(),
        home: const _Enrutador(),
      ),
    );
  }
}

class _Enrutador extends StatelessWidget {
  const _Enrutador();

  @override
  Widget build(BuildContext context) {
    final VmPartida vm = AlcancePartida.de(context);
    if (vm.cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!vm.hayPartida) return const VistaInicio();
    if (vm.partida!.terminada) return const VistaCierre();
    return const VistaPanel();
  }
}
