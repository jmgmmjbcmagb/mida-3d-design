# 🚀 Bambu 3D Design Studio & Parametric CAD Assistant

Code-CAD parametric 3D design system optimized for the **Bambu Lab A1** (build volume of **256 × 256 × 256 mm**), featuring an autonomous WebAssembly-based STL compiler and an **Antigravity AI Agent Skill**.

---

## 🛠️ Project Structure

The repository organizes designs in isolated per-project folders under `models/`, ensuring project files and exported STLs never mix:

```
mida-3d-design/
├── .agents/
│   └── skills/
│       └── bambu-3d-designer/
│           └── SKILL.md             # Antigravity Skill (DFAM rules, hardware standards, tolerances, workflow)
├── lib/
│   ├── bambu_standards.scad         # FDM tolerances, Bambu A1 bounding box validation, DFAM utilities
│   └── hardware.scad                # Metric fasteners (M2-M6), heat-set brass inserts, hex nuts, magnets
├── models/
│   └── <project_name>/              # Dedicated project folder
│       ├── <project_name>.scad      # Parametric OpenSCAD design source
│       └── exports/                 # Compiled STL meshes ready for slicing
├── scripts/
│   └── export_stl.mjs               # Headless OpenSCAD -> STL compiler (Node.js + WebAssembly)
├── package.json
└── README.md
```

---

## ⚡ How to Build & Export STL Files

This repository uses the OpenSCAD C++/CGAL geometry engine compiled to WebAssembly (`openscad-wasm`). **No local OpenSCAD GUI installation, display servers, or background daemons are required.**

### 1. Initial Setup (One-time)
```bash
npm install
```

### 2. Export All Projects & Models
```bash
npm run export
```
All `.stl` files will be automatically compiled and saved directly into their respective `models/<project_name>/exports/` directories.

### 3. Targeted Compilation Options
```bash
# Export only a specific project:
node scripts/export_stl.mjs --project <project_name>

# Export a single component/part by identifier:
node scripts/export_stl.mjs --part <part_name>

# Export a specific .scad file:
node scripts/export_stl.mjs --file models/<project_name>/<project_name>.scad
```

---

## 📐 Mechanical Engineering Standards (`lib/`)

### Built-in FDM Tolerances:
- **Press Fit (Magnets / Bearings / Dowels):** `+0.10 mm` to `+0.12 mm`
- **Snug Fit (Enclosures / Sliding Lids / Modular Joints):** `+0.20 mm`
- **Loose Fit (Moving Axles / Hinges / Clearance Holes):** `+0.35 mm` to `+0.45 mm`
- **Coarse Clearance (Cable Pass-Throughs / Power Inlets):** `+0.50 mm` to `+0.80 mm`

### Hardware Library:
- **Metric Screws (M2, M2.5, M3, M4, M5, M6)**: DIN 7991 countersunk and DIN 912 socket head cap profiles.
- **Threaded Heat-Set Brass Inserts (Ruthex standard)**: 8° conical angle, self-aligning pilot chamfer, and plastic melt overflow reservoir.
- **Captive Hex Nuts (DIN 934)**.
- **Neodymium Magnet & Bearing Pockets (608, 623, 624, 625)**.

---

## 🖨️ Slicing Workflow in Bambu Studio / OrcaSlicer

1. Run `npm run export` (or export your specific project with `--project <project_name>`).
2. Drag and drop the generated `.stl` files from `models/<project_name>/exports/` directly into **Bambu Studio** or **OrcaSlicer**.
3. Select the **Textured PEI Plate** and a standard $0.4\text{ mm}$ nozzle profile with $\ge 4$ wall perimeters.
