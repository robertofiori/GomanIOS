# El goman (ElMango iOS) 🛒📱

Aplicación nativa de iOS desarrollada en **Swift** y **SwiftUI** para comparar precios de supermercados en tiempo real en Bahía Blanca y otras ciudades de Argentina.

Es la contraparte nativa de la plataforma web [Superscan](https://robertofiori.github.io/superscan/).

---

## ✨ Características

- 🔍 **Búsqueda en tiempo real**: Consulta precios actualizados entre Vea, Carrefour, ChangoMás y La Cooperativa Obrera a través de microservicios en Google Cloud Run.
- 📉 **Optimizador de Canasta Inteligente**:
  - Calcula automáticamente en qué supermercado conviene comprar toda tu lista.
  - Estima el costo con artículos faltantes para una comparativa transparente.
  - Muestra el mínimo teórico si dividieras la compra en cada súper más barato.
- 💳 **Promociones Bancarias y Billeteras**:
  - Descuentos automáticos según el día de la semana (Cuenta DNI, BNA+, MODO, Personal Pay).
- 🏷 **Ofertas del Día**:
  - Pestaña dedicada con promociones destacadas y soporte para *pull-to-refresh*.
- 📷 **Escáner de Códigos de Barra**:
  - Escaneo mediante cámara (`AVFoundation`) o entrada manual.
  - Integración con Open Food Facts para detalles de productos.
- 📍 **Selector de Ubicación**:
  - Optimizado para Bahía Blanca (CP 8000), con soporte para CABA, La Plata, Mar del Plata, Córdoba y Rosario.
- 🍏 **Diseño Nativo Apple (HIG)**:
  - `TabView`, `.searchable`, `NavigationStack`, colores semánticos y respuesta háptica.
  - Persistencia de datos en local (`UserDefaults`).

---

## 🛠 Tecnologías

- **Lenguaje**: Swift 6 / Modern Concurrency (`async/await`, `actor`)
- **UI**: SwiftUI (iOS 17+)
- **Estado**: Observation framework (`@Observable`)
- **Testing**: Swift Testing framework (`@Test`, `#expect`)
- **Backend / APIs**: Google Cloud Run & Open Food Facts API

---

## 🚀 Cómo Ejecutar

1. Clona el repositorio:
   ```bash
   git clone https://github.com/robertofiori/GomanIOS.git
   ```
2. Abre `El goman.xcodeproj` en **Xcode 16+**.
3. Selecciona el destino de compilación (Simulador de iPhone o dispositivo físico con iOS 17+).
4. Presiona **Cmd + R** para compilar y ejecutar.
