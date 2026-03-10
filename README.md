# Investment Companion App

Aplicación móvil personal para **visualizar y analizar acciones de una watchlist**.

La app permite mantener una lista de tickers y ejecutar análisis automáticos sobre ellos (indicadores técnicos, métricas de mercado y detección de señales) para ayudar a identificar oportunidades o riesgos.

> Proyecto personal.  
> No es una plataforma de trading ni un gestor de cartera.

El objetivo es construir una herramienta **ligera, rápida y útil para analizar acciones de interés** desde el móvil.

---

# Tabla de contenidos

- Objetivo del proyecto
- Visión general
- Principios del proyecto
- Casos de uso
- Funcionalidades
- Alcance del MVP
- Fuera de alcance
- Arquitectura general
- Stack tecnológico
- Estructura del repositorio
- Estructura interna de la app
- Modelo de datos
- Motor de análisis
- Flujo de datos
- Fuentes de datos de mercado
- Instalación y ejecución
- Build
- Roadmap
- Convenciones del proyecto
- Testing
- Licencia

---

# Objetivo del proyecto

Construir una aplicación móvil que permita:

- mantener una watchlist personal de acciones
- consultar datos de mercado relevantes
- ejecutar análisis automático sobre los tickers
- detectar señales interesantes
- visualizar información de forma clara y rápida

La aplicación actúa como un **analizador personal de acciones**, no como una herramienta de gestión financiera.

---

# Visión general

El objetivo de la app es centralizar el análisis de una lista personal de acciones evitando depender constantemente de múltiples herramientas externas.

La app permitirá responder rápidamente preguntas como:

- ¿Qué acciones de mi watchlist muestran señales interesantes hoy?
- ¿Qué acciones están en momentum alcista?
- ¿Cuáles están oversold?
- ¿Dónde hay volumen anómalo?
- ¿Qué tickers merecen una revisión más profunda?

La aplicación ejecutará análisis automáticos sobre cada ticker de la watchlist y mostrará un resumen claro de señales.

---

# Principios del proyecto

## Simplicidad
Arquitectura simple, sin backend innecesario.

## Rapidez
La app debe abrir rápido y mostrar información clave de forma inmediata.

## Utilidad práctica
Cada funcionalidad debe aportar valor real para analizar acciones.

## Bajo mantenimiento
Sin infraestructura compleja ni dependencias innecesarias.

## Evolución incremental
Primero un MVP útil, después mejoras progresivas.

---

# Casos de uso

## Watchlist personal

Mantener una lista de tickers a seguir.

Ejemplo:

ROOT  
SOUN  
TSSI  
NVDA  
AVGO

El usuario puede:

- añadir ticker
- eliminar ticker
- ordenar lista
- marcar favoritos

---

## Visualización rápida

Para cada ticker se muestran:

- precio actual
- cambio diario
- volumen
- métricas básicas
- resumen del análisis

---

## Análisis automático

La app ejecuta análisis sobre cada ticker:

- momentum
- RSI
- medias móviles
- volumen anómalo
- movimientos fuertes

Resultado: un resumen de señales.

---

# Funcionalidades

## Dashboard

Resumen global de la watchlist.

Información mostrada:

- top movers
- acciones con señales alcistas
- acciones oversold
- volumen anómalo

---

## Watchlist

Lista principal de tickers.

Ticker | Price | Change | Volume | Signal  
ROOT | 124 | +5.8% | High | Bullish  
SOUN | 11 | +2.1% | Normal | Neutral  
TSSI | 22 | -4.0% | Low | Oversold

Persistencia local con shared_preferences.

---

## Ficha de acción

Pantalla de detalle de un ticker.

Información mostrada:

- gráfico de precio
- indicadores técnicos
- métricas de mercado
- resumen del análisis

---

## Motor de análisis

Cada ticker pasa por un conjunto de evaluaciones automáticas que generan señales.

Ejemplo de resultado:

ROOT  
Precio: 124  
Cambio: +5.8%

Señales detectadas

✔ Volumen alto  
✔ Momentum alcista  
⚠ RSI alto

Score final: **BULLISH**

---

# Alcance del MVP

Primera versión funcional.

Incluye:

- watchlist
- consulta de precios
- dashboard
- ficha básica de acción
- indicadores técnicos básicos
- análisis automático simple
- persistencia local (shared_preferences)

No requiere backend.

---

# Fuera de alcance

Para mantener el proyecto simple quedan fuera:

- trading
- registro de compras
- registro de ventas
- gestión de cartera
- cálculo de beneficios
- integración con brokers
- multiusuario
- login
- sincronización cloud
- backend complejo

---

# Arquitectura general

Flutter Mobile App

Componentes principales:

UI  
Market Data API Client  
Analysis Engine  
Local Storage (watchlist)

Flujo simplificado:

Watchlist → Market API → Indicators → Analysis Engine → UI

---

# Stack tecnológico

App móvil  
Flutter

Lenguaje  
Dart

Gestión de estado (planificado)  
Riverpod

Persistencia local (planificado)  
Hive o SQLite

Networking (planificado)  
Dio o http

Visualización de gráficos (planificado)  
fl_chart

Notificaciones locales (planificado)  
flutter_local_notifications

---

# Estructura del repositorio

.
├── android/  
├── ios/  
├── web/  
├── windows/  
├── macos/  
├── linux/  
├── lib/  
├── assets/  
├── data/  
├── docs/  
├── scripts/  
├── test/  
├── integration_test/  
├── pubspec.yaml  
└── README.md

Descripción:

android/ios/web/windows/macos/linux/ → targets de plataforma generados por Flutter  
lib/ → código fuente de la app  
assets/ → recursos visuales  
data/ → datos de ejemplo  
docs/ → documentación  
scripts/ → scripts auxiliares  
test/ → tests unitarios  
integration_test/ → tests de integración  
pubspec.yaml → configuración de dependencias

---

# Estructura interna de la app

lib/

app/  
core/  
models/  
features/

Detalle:

app/

app.dart  
router.dart

core/

api/  
indicators/  
analysis_engine/  
network/  
storage/  
utils/

models/

ticker.dart  
market_data.dart  
analysis_result.dart

features/

dashboard/  
watchlist/  
stock_detail/  
settings/

Pantallas base:

dashboard_screen.dart  
watchlist_screen.dart  
stock_detail_screen.dart  
settings_screen.dart

---

# Modelo de datos

Ticker

ticker  
companyName  
sector

MarketData

price  
changePercent  
volume  
marketCap  
eps  
revenueGrowth

TechnicalIndicators

rsi  
sma50  
sma200  
macd

AnalysisResult

momentumSignal  
volumeSignal  
rsiSignal  
breakoutSignal  
overallScore

---

# Motor de análisis

El motor de análisis evalúa señales sobre cada ticker.

Ejemplos de reglas.

Momentum

price > SMA50  
SMA50 > SMA200

RSI

RSI < 30 → oversold  
RSI > 70 → overbought

Volumen

volume > averageVolume * 2

Breakout

price rompe resistencia reciente

Movimiento fuerte

dailyChange > 8%

---

# Flujo de datos

Watchlist  
↓  
Market Data API  
↓  
Indicators Calculation  
↓  
Analysis Engine  
↓  
UI Dashboard

---

# Fuentes de datos de mercado

Proveedor elegido:

Finnhub (API key requerida).

Validación de tickers con Finnhub antes de añadir a la watchlist.

Posibles proveedores alternativos:

Finnhub  
Alpha Vantage  
Polygon  
Yahoo Finance

La elección final dependerá de:

- límites gratuitos
- facilidad de uso
- cobertura de mercados

---

# Instalación y ejecución

Requisitos:

Flutter SDK  
Android SDK  
IntelliJ con plugin Flutter

Clonar repositorio:

git clone <repo>

Ejecutar aplicación:

flutter pub get  
flutter run --dart-define=FINNHUB_API_KEY=YOUR_KEY --dart-define=TWELVE_DATA_API_KEY=YOUR_KEY

---

# Build

Generar APK:

flutter build apk

Archivo generado:

build/app/outputs/flutter-apk/app-release.apk

---

# Roadmap

Fase 1

watchlist  
consulta de precios  
dashboard  
ficha de acción

Fase 2

motor de análisis

RSI  
medias móviles  
volumen  
momentum

Fase 3

mejoras

gráficos avanzados  
alertas  
mini screener  
filtros

---

# Convenciones del proyecto

nombres de archivos en snake_case  
estructura modular por features  
código en inglés  
documentación en docs/

---

# Testing

Tests previstos:

- lógica del motor de análisis
- cálculo de indicadores
- renderizado de widgets clave

---

# Licencia

Por definir.
