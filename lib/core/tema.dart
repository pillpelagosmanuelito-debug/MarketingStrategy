import 'package:flutter/material.dart';

/// Paleta y tipografia de la aplicacion.
///
/// Criterio: la pantalla es un tablero de decision, no una pieza publicitaria.
/// El color se reserva para comunicar estado (riesgo, alerta, confirmacion) y
/// para distinguir modulos; todo lo demas es neutro para que los numeros se
/// lean.
class Tema {
  const Tema._();

  static const Color primario = Color(0xFF0F4C5C);
  static const Color primarioClaro = Color(0xFF2A7F92);
  static const Color acento = Color(0xFFE36414);
  static const Color fondo = Color(0xFFF6F6F3);
  static const Color superficie = Colors.white;
  static const Color texto = Color(0xFF1B1B1D);
  static const Color textoSuave = Color(0xFF5F6368);
  static const Color borde = Color(0xFFE1E1DC);

  static const Color critica = Color(0xFFC1121F);
  static const Color advertencia = Color(0xFFCC8B15);
  static const Color observacion = Color(0xFF335C67);
  static const Color confirmacion = Color(0xFF2A9D8F);

  static const Color mercado = Color(0xFF3D5A80);
  static const Color cliente = Color(0xFF7B2CBF);
  static const Color producto = Color(0xFF0F4C5C);
  static const Color precio = Color(0xFFB5651D);
  static const Color campanas = Color(0xFF2A9D8F);

  static ThemeData construir() {
    final ColorScheme esquema = ColorScheme.fromSeed(
      seedColor: primario,
      primary: primario,
      secondary: acento,
      surface: superficie,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: esquema,
      scaffoldBackgroundColor: fondo,
      appBarTheme: const AppBarTheme(
        backgroundColor: primario,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardTheme(
        color: superficie,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borde),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primario,
          side: const BorderSide(color: primario),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: primario,
        thumbColor: primario,
        inactiveTrackColor: borde,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w700, color: texto),
        titleLarge: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w700, color: texto),
        titleMedium: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w600, color: texto),
        bodyMedium: TextStyle(fontSize: 14, height: 1.45, color: texto),
        bodySmall: TextStyle(fontSize: 12.5, height: 1.4, color: textoSuave),
        labelLarge: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w600, color: textoSuave),
      ),
      dividerTheme: const DividerThemeData(color: borde, space: 1, thickness: 1),
    );
  }
}
