#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Genera el icono de la aplicacion por codigo, sin dependencias externas.

Se dibuja con la biblioteca estandar (zlib + struct escriben el PNG a mano)
para que el icono se pueda regenerar en cualquier maquina y en CI sin instalar
nada. El icono no es decorativo: son tres barras de participacion de mercado
con un punto naranja sobre la barra elegida, que es exactamente lo que la
aplicacion ensena — elegir un segmento y concentrar el esfuerzo en el.

Uso:
    python3 tool/generar_icono.py [carpeta_destino_android]
"""
import os
import struct
import sys
import zlib

FONDO = (15, 76, 92)        # Tema.primario
BARRA = (255, 255, 255)
BARRA_TENUE = (120, 170, 180)
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

    # Tres barras: la del medio es la elegida.
    ancho_barra = lado * 0.15
    separacion = lado * 0.075
    base = lado * 0.76
    alturas = [lado * 0.20, lado * 0.38, lado * 0.28]
    colores = [BARRA_TENUE, BARRA, BARRA_TENUE]
    total = 3 * ancho_barra + 2 * separacion
    inicio = (lado - total) / 2

    for i in range(3):
        x0 = inicio + i * (ancho_barra + separacion)
        x1 = x0 + ancho_barra
        y0 = base - alturas[i]
        for y in range(int(y0), int(base)):
            for x in range(int(x0), int(x1)):
                if 0 <= x < lado and 0 <= y < lado:
                    px[y * lado + x] = colores[i] + (255,)

    # Punto naranja sobre la barra elegida: el segmento objetivo.
    cx = inicio + ancho_barra + separacion + ancho_barra / 2
    cy = base - alturas[1] - lado * 0.11
    r = lado * 0.075
    for y in range(lado):
        for x in range(lado):
            if (x + 0.5 - cx) ** 2 + (y + 0.5 - cy) ** 2 <= r * r:
                px[y * lado + x] = ACENTO + (255,)

    # Linea de base.
    y0 = int(base)
    for y in range(y0, min(lado, y0 + max(2, int(lado * 0.018)))):
        for x in range(int(inicio), int(inicio + total)):
            if 0 <= x < lado:
                px[y * lado + x] = BARRA + (255,)

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
