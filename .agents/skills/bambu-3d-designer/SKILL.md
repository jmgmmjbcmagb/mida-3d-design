---
name: bambu-3d-designer
description: >-
  Specialized 3D CAD modeling and autonomous compilation skill for Bambu Lab A1 3D printer.
  Transforms natural language project descriptions into precise, mathematically sound,
  parametric Code-CAD (OpenSCAD/Python) models with accurate mechanical tolerances,
  standard fasteners (screws, heat-set inserts, nuts), printability checks (DFAM),
  and headless one-shot STL compilation.
---

# 🖨️ Bambu Lab A1 3D Parametric CAD & Autonomous STL Skill

Esta Skill guía al asistente de IA en el diseño de modelos 3D paramétricos de alta precisión mecánica para la impresora **Bambu Lab A1** (volumen de construcción de **256 × 256 × 256 mm**), utilizando **OpenSCAD** como motor de código CAD y una arquitectura de exportación STL rápida, portable y sin consumo de recursos en segundo plano.

---

## 🎯 1. Principios Clave de Diseño

1. **CAD Matemático Puro**: Todo modelo debe ser código OpenSCAD (`.scad`) 100% paramétrico, válido y determinista.
2. **Diseño para Fabricación Aditiva (DFAM)**: Orientación inteligente en la cama, chaflanes en lugar de filetes horizontales, puentes controlados y prevención de pie de elefante.
3. **Parametrización Total**: Dimensiones principales, holguras mecánicas y tipos de tornillos deben declararse como variables en la cabecera.
4. **Arquitectura Headless (Bajo Consumo)**: La compilación se ejecuta bajo demanda con WebAssembly (`openscad-wasm`). No se mantienen servidores web ni procesos residentes que consuman batería o memoria RAM.

---

## 📐 2. Restricciones y Especificaciones Bambu Lab A1

| Parámetro | Especificación | Regla de Diseño DFAM |
| :--- | :--- | :--- |
| **Volumen Máximo** | **256 × 256 × 256 mm** | No superar 250 mm sin segmentar en módulos acoplables. |
| **Boquilla Estándar** | 0.4 mm | Grosor de pared mínimo recomendado: `1.6 mm` (4 perímetros). |
| **Altura de Capa** | 0.20 mm estándar (0.08 - 0.28 mm) | Alinear escalones verticales y orificios con múltiplos de 0.2 mm. |
| **Ángulo de Voladizo** | **≤ 45°** (hasta 55° con ventilador) | Usar chaflanes a 45° en voladizos; usar orificios en lágrima (*teardrop*) para agujeros horizontales. |
| **Puentes (Bridging)** | Hasta 25 mm seguros | Evitar luces horizontales sin soporte superiores a 25 mm. |
| **Adhesión a Cama** | Placa PEI Texturizada Dorada | Aplicar chaflán inferior de `0.4 - 0.6 mm` a 45° para compensar el pie de elefante. |

---

## 🔩 3. Tabla de Tolerancias Mecánicas (FDM)

Siempre aplicar las holguras estándar según la función mecánica requerida:

| Ajuste | Tolerancia | Caso de Uso Típico |
| :--- | :--- | :--- |
| **Press Fit (Fricción Fuerte)** | `+0.10 mm` a `+0.12 mm` | Imanes de neodimio, pistas de rodamientos, pernos guía fijos. |
| **Snug Fit (Ajuste Preciso)** | `+0.20 mm` | Tapas correderas, labios de acople modular, ranuras para tablets/móviles. |
| **Loose Fit (Holgura Móvil)** | `+0.35 mm` a `+0.45 mm` | Ejes rotatorios, pasadores de bisagras, orificios pasantes de tornillos. |
| **Coarse Clearance** | `+0.50 mm` a `+0.80 mm` | Pasacables, orificios para conectores Schuko / USB, huecos no críticos. |

---

## 🧰 4. Biblioteca de Estándares Mecánicos (`lib/`)

Cada modelo ubicado en `models/<nombre_proyecto>/` debe incluir las librerías del proyecto al inicio:

```openscad
include <../../lib/bambu_standards.scad>
include <../../lib/hardware.scad>
```

### A. Tornillos Métricos (DIN 912 Cilíndricos / DIN 7991 Avellanados)
- Módulos disponibles: `screw_hole(size="M3", length=20, head_type="socket" | "countersunk" | "none")`
- Diámetros de orificio pasante recomendados:
  - **M2**: 2.3 mm
  - **M2.5**: 2.8 mm
  - **M3**: 3.4 mm
  - **M4**: 4.5 mm
  - **M5**: 5.5 mm

### B. Insertos Roscados de Latón por Calor (Ruthex Estándar)
- Módulos disponibles: `heat_set_insert_pocket(size="M3")`
- Geometría con ángulo cónico de 8°, chaflán de centrado y pozo de alivio para plástico sobrante:
  - **M2**: Ø Superior 3.2 mm, Profundidad 4.0 mm
  - **M2.5**: Ø Superior 3.6 mm, Profundidad 5.7 mm
  - **M3**: Ø Superior 4.2 mm, Profundidad 5.7 mm (Boss exterior ≥ 8.0 mm)
  - **M4**: Ø Superior 5.8 mm, Profundidad 8.1 mm (Boss exterior ≥ 10.0 mm)
  - **M5**: Ø Superior 6.8 mm, Profundidad 9.5 mm (Boss exterior ≥ 12.0 mm)

### C. Tuercas Hexagonales Empotradas (DIN 934)
- Módulos disponibles: `captive_nut_pocket(size="M3", slot_length=0)`
  - **M3**: 5.5 mm entre caras (+0.2 mm tolerancia), 2.4 mm grosor.

### D. Imanes y Rodamientos
- `magnet_pocket(diameter=6, thickness=3)` (ajuste por fricción +0.15 mm).
- `bearing_pocket(type="608" | "623" | "624" | "625")` (alojamiento para rodamiento 608 de skate: Ø22 mm ext, Ø8 mm int, 7 mm ancho).

---

## ⚡ 5. Compilación y Exportación Autónoma a STL

El proyecto incluye un script CLI universal y portable ([scripts/export_stl.mjs](file:///Users/jmgm/Projects/mida-3d-design/scripts/export_stl.mjs)) basado en `openscad-wasm`:

### Comandos Disponibles:

```bash
# Exportar todas las piezas de todos los proyectos a sus respectivas carpetas exports/:
npm run export

# Exportar solo un proyecto específico:
node scripts/export_stl.mjs --project <nombre_proyecto>

# Exportar una pieza específica:
node scripts/export_stl.mjs --part <nombre_pieza>

# Exportar un archivo SCAD concreto:
node scripts/export_stl.mjs --file models/<nombre_proyecto>/<nombre_proyecto>.scad
```

### Arquitectura de Scaffolding y Compilación:
1. **Scaffolding Aislado por Proyecto**: Cada proyecto reside en su propia carpeta bajo `models/<nombre_proyecto>/`:
   ```
   models/
   └── <nombre_proyecto>/
       ├── <nombre_proyecto>.scad
       └── exports/
           ├── 1_<nombre_proyecto>_<pieza1>.stl
           └── 2_<nombre_proyecto>_<pieza2>.stl
   ```
2. **Sin dependencias pesadas**: No requiere tener OpenSCAD GUI instalado en el sistema operativo ni servidores web corriendo.
3. **Aislamiento de Memoria**: Cada pieza se compila en una instancia independiente de WebAssembly con su propio espacio CGAL para evitar fugas de memoria en piezas complejas.
4. **Detección Automática**: Analiza el selector de piezas del archivo `.scad` y genera automáticamente los archivos con nombres descriptivos en la carpeta `exports/` correspondiente a cada proyecto.

---

## 🧩 6. Plantilla Estándar para Nuevos Diseños

Al crear un nuevo modelo paramétrico en `models/<nombre_proyecto>/<nombre_proyecto>.scad`, utilizar la siguiente estructura:

```openscad
// ====================================================================
// PROYECTO: [Nombre del Proyecto]
// Optimizado para Bambu Lab A1 (256x256x256 mm)
// ====================================================================

include <../../lib/bambu_standards.scad>
include <../../lib/hardware.scad>

/* [Selector de Pieza para Laminar] */
part = "assembly"; // [assembly: Conjunto, base: 1. Base Inferior, lid: 2. Tapa Superior, exploded: 3. Vista Explosionada]

/* [Dimensiones Principales] */
box_w    = 120;
box_d    = 80;
box_h    = 40;
wall_th  = 2.4;
corner_r = 6.0;

/* [Tolerancias y Tornillería] */
screw_type = "M3";

// Validación de volumen Bambu Lab A1
validate_bambu_bounds([box_w, box_d, box_h]);

module part_base() {
    difference() {
        // Cuerpo exterior con chaflán anti-pie de elefante
        rounded_box_outer(box_w, box_d, box_h/2, corner_r);
        
        // Vaciado interior
        translate([0, 0, wall_th])
            rounded_box_inner(box_w, box_d, box_h/2, corner_r, wall_th);
            
        // Insertos roscados M3 en las 4 esquinas
        for (x = [-box_w/2 + 10, box_w/2 - 10]) {
            for (y = [-box_d/2 + 10, box_d/2 - 10]) {
                translate([x, y, box_h/2 - insert_depth(screw_type)])
                    heat_set_insert_pocket(size=screw_type);
            }
        }
    }
}

module part_lid() {
    difference() {
        rounded_box_outer(box_w, box_d, box_h/2, corner_r);
        
        // Vaciado
        translate([0, 0, wall_th])
            rounded_box_inner(box_w, box_d, box_h/2, corner_r, wall_th);
            
        // Orificios avellanados para tornillos M3
        for (x = [-box_w/2 + 10, box_w/2 - 10]) {
            for (y = [-box_d/2 + 10, box_d/2 - 10]) {
                translate([x, y, -1])
                    screw_hole(size=screw_type, length=box_h/2 + 2, head_type="countersunk");
            }
        }
    }
}

// Selector de visualización y compilación
if (part == "base") {
    part_base();
} else if (part == "lid") {
    part_lid();
} else {
    part_base();
    translate([0, 0, box_h/2 + 5]) part_lid();
}
```

---

## 👥 7. Compartir el Proyecto con Otros Usuarios

Cualquier persona que clone o reciba este repositorio solo necesita:
1. Clonar el repositorio: `git clone <url>`
2. Instalar dependencias ligeras (tarda <1 segundo): `npm install`
3. Exportar todos los archivos STL listos para laminar: `npm run export`
4. Abrir los archivos de `models/<nombre_proyecto>/exports/` en **Bambu Studio** o **OrcaSlicer**.
