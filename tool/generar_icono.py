#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Genera el icono de la aplicacion por codigo, sin dependencias externas.

Se dibuja con la biblioteca estandar (zlib + struct escriben el PNG a mano)
para que el icono se pueda regenerar en cualquier maquina y en CI sin instalar
nada. El icono es una mira de precision (dianas concentricas + retícula) con
el centro naranja: apuntar con precision a un segmento de mercado, en vez de
disparar a todos, es exactamente la estrategia que la aplicacion ensena.

Uso:
    python3 tool/generar_icono.py [carpeta_destino_android]
"""
import os
import struct
import sys
import zlib

FONDO = (15, 76, 92)        # Tema.primario
ANILLO_TENUE = (120, 170, 180)
BLANCO = (255, 255, 255)
ACENTO = (227, 100, 20)     # Tema.acento

TAMANOS_ANDROID = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def escribir_png(ruta, pixeles, ancho, alto):
    """Escribe un PNG RGBA de 8 bits sin filtros."""
    crudo = bytearray()
    for y in range(alto):
        crudo.append(0)  # tipo de filtro: ninguno
        for x in range(ancho):
            crudo.extend(pixeles[y * ancho + x])

    def trozo(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos +
                struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))

    cabecera = struct.pack(">IIBBBBB", ancho, alto, 8, 6, 0, 0, 0)
    with open(ruta, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n")
        f.write(trozo(b"IHDR", cabecera))
        f.write(trozo(b"IDAT", zlib.compress(bytes(crudo), 9)))
        f.write(trozo(b"IEND", b""))


def dibujar(lado):
    """Devuelve la lista de pixeles RGBA del icono."""
    px = [(0, 0, 0, 0)] * (lado * lado)
    radio = lado * 0.22

    def dentro_redondeado(x, y):
        margen = 0
        izq, der = margen, lado - margen
        if x < izq + radio and y < izq + radio:
            return (x - (izq + radio)) ** 2 + (y - (izq + radio)) ** 2 <= radio ** 2
        if x > der - radio and y < izq + radio:
            return (x - (der - radio)) ** 2 + (y - (izq + radio)) ** 2 <= radio ** 2
        if x < izq + radio and y > der - radio:
            return (x - (izq + radio)) ** 2 + (y - (der - radio)) ** 2 <= radio ** 2
        if x > der - radio and y > der - radio:
            return (x - (der - radio)) ** 2 + (y - (der - radio)) ** 2 <= radio ** 2
        return True

    # Fondo redondeado.
    for y in range(lado):
        for x in range(lado):
            if dentro_redondeado(x + 0.5, y + 0.5):
                px[y * lado + x] = FONDO + (255,)

    cx, cy = lado / 2, lado / 2
    radio_externo = lado * 0.34
    radio_medio = radio_externo * 0.62
    radio_interno = radio_externo * 0.30
    grosor_retícula = max(1.0, lado * 0.02)

    for y in range(lado):
        for x in range(lado):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            dist2 = dx * dx + dy * dy
            if dist2 <= radio_externo ** 2:
                px[y * lado + x] = ANILLO_TENUE + (255,)
            if dist2 <= radio_medio ** 2:
                px[y * lado + x] = BLANCO + (255,)

    # Retícula: cruz fina de mira, bajo el centro naranja.
    for y in range(lado):
        for x in range(lado):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            if dx * dx + dy * dy > radio_externo ** 2:
                continue
            if abs(dx) <= grosor_retícula / 2 or abs(dy) <= grosor_retícula / 2:
                px[y * lado + x] = FONDO + (255,)

    # Centro: el segmento de mercado elegido.
    for y in range(lado):
        for x in range(lado):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            if dx * dx + dy * dy <= radio_interno ** 2:
                px[y * lado + x] = ACENTO + (255,)

    return px


def main():
    raiz = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    destino_assets = os.path.join(raiz, "assets", "icono")
    os.makedirs(destino_assets, exist_ok=True)

    for lado in (512, 192):
        ruta = os.path.join(destino_assets, f"icono_{lado}.png")
        escribir_png(ruta, dibujar(lado), lado, lado)
        print(f"generado {ruta}")

    destino_android = sys.argv[1] if len(sys.argv) > 1 else os.path.join(
        raiz, "android", "app", "src", "main", "res")
    if os.path.isdir(os.path.dirname(destino_android)) or len(sys.argv) > 1:
        for carpeta, lado in TAMANOS_ANDROID.items():
            ruta_carpeta = os.path.join(destino_android, carpeta)
            os.makedirs(ruta_carpeta, exist_ok=True)
            ruta = os.path.join(ruta_carpeta, "ic_launcher.png")
            escribir_png(ruta, dibujar(lado), lado, lado)
            print(f"generado {ruta}")
    else:
        print("carpeta android/ no encontrada: solo se generaron los assets")


if __name__ == "__main__":
    main()
