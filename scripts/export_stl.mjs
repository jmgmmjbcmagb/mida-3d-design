#!/usr/bin/env node
/**
 * ====================================================================
 * COMPILADOR AUTÓNOMO OPENSCAD -> STL (HEADLESS WEB ASSEMBLY)
 * Diseñado para proyectos de impresión 3D Bambu Lab A1
 * Soporta estructura modular por proyecto: models/<proyecto>/exports/
 * ====================================================================
 * 
 * Uso:
 *   npm run export                                          # Compila todos los proyectos
 *   node scripts/export_stl.mjs --project <nombre_proyecto> # Compila un proyecto específico
 *   node scripts/export_stl.mjs --file models/<proyecto>/<archivo>.scad
 *   node scripts/export_stl.mjs --part <nombre_pieza>       # Compila una pieza específica
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import { createOpenSCAD } from 'openscad-wasm';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const ROOT_DIR = path.resolve(__dirname, '..');
const MODELS_DIR = path.join(ROOT_DIR, 'models');
const LIB_DIR = path.join(ROOT_DIR, 'lib');

// Procesar argumentos de línea de comandos
const args = process.argv.slice(2);
let targetFile = null;
let targetProject = null;
let targetPart = null;

for (let i = 0; i < args.length; i++) {
  if (args[i] === '--file' && args[i + 1]) {
    targetFile = path.resolve(ROOT_DIR, args[i + 1]);
    i++;
  } else if (args[i] === '--project' && args[i + 1]) {
    targetProject = args[i + 1];
    i++;
  } else if (args[i] === '--part' && args[i + 1]) {
    targetPart = args[i + 1];
    i++;
  }
}

/**
 * Encuentra todos los archivos .scad dentro de models/ (directos o en subcarpetas de proyecto)
 */
function findScadFiles(dir) {
  let results = [];
  if (!fs.existsSync(dir)) return results;

  const list = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of list) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name !== 'exports' && entry.name !== 'node_modules') {
        results = results.concat(findScadFiles(fullPath));
      }
    } else if (entry.isFile() && entry.name.endsWith('.scad')) {
      results.push(fullPath);
    }
  }
  return results;
}

/**
 * Detecta automáticamente las piezas definidas en el archivo .scad
 */
function extractPartsFromScad(scadContent) {
  // Busca comentarios tipo: part = "..."; // [assembly: ..., base: ..., ...]
  const selectorMatch = scadContent.match(/part\s*=\s*"[^"]*";\s*\/\/\s*\[([^\]]+)\]/);
  if (selectorMatch) {
    const rawOptions = selectorMatch[1].split(',');
    const parts = [];
    for (const opt of rawOptions) {
      const partsArr = opt.split(':');
      const id = partsArr[0].trim();
      const label = partsArr[1] ? partsArr[1].trim() : id;
      // Omitir vistas generales que no sean piezas imprimibles individuales
      if (id !== 'assembly' && id !== 'exploded') {
        parts.push({ id, label });
      }
    }
    if (parts.length > 0) return parts;
  }

  // Fallback: buscar condicionales `if (part == "xyz")`
  const ifMatches = [...scadContent.matchAll(/part\s*==\s*"([^"]+)"/g)];
  const ids = [...new Set(ifMatches.map(m => m[1]))].filter(id => id !== 'assembly' && id !== 'exploded');
  return ids.map(id => ({ id, label: id }));
}

/**
 * Compila una pieza individual en una instancia fresca e independiente de WebAssembly
 */
async function compilePart(scadPath, partId, outputFilename, projectExportDir) {
  console.log(`\n⚙️  Compilando pieza: [${partId}] -> ${outputFilename}...`);
  const startTime = Date.now();

  const engine = await createOpenSCAD();
  const instance = engine.getInstance();

  // Cargar librerías estándar en el sistema de archivos virtual (MEMFS)
  if (fs.existsSync(LIB_DIR)) {
    const libFiles = fs.readdirSync(LIB_DIR).filter(f => f.endsWith('.scad'));
    for (const lf of libFiles) {
      const content = fs.readFileSync(path.join(LIB_DIR, lf), 'utf-8');
      instance.FS.writeFile('/' + lf, content);
    }
  }

  // Leer y preparar el código SCAD (limpiando rutas relativas a lib/)
  const rawScad = fs.readFileSync(scadPath, 'utf-8');
  const preparedScad = rawScad
    .replace(/include\s*<.*?([^\/]+)\.scad>/g, 'include <$1.scad>')
    .replace(/part\s*=\s*"[^"]*";/, `part = "${partId}";`);

  instance.FS.writeFile('/input.scad', preparedScad);

  // Ejecución de compilación OpenSCAD
  instance.callMain(['/input.scad', '-o', '/output.stl']);

  const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
  const stlData = instance.FS.readFile('/output.stl');
  const outPath = path.join(projectExportDir, outputFilename);
  fs.writeFileSync(outPath, Buffer.from(stlData));

  // Limpieza de memoria virtual
  instance.FS.unlink('/input.scad');
  instance.FS.unlink('/output.stl');

  const sizeMb = (stlData.length / (1024 * 1024)).toFixed(2);
  const relPath = path.relative(ROOT_DIR, outPath);
  console.log(`✅ [${partId}] Exportado con éxito en ${elapsed}s: ${relPath} (${sizeMb} MB)`);
}

/**
 * Punto de entrada principal
 */
async function main() {
  console.log('🚀 === COMPILADOR AUTÓNOMO STL PARA BAMBU LAB A1 ===\n');

  let scadFiles = [];
  if (targetFile) {
    scadFiles = [targetFile];
  } else if (targetProject) {
    const projectPath = path.join(MODELS_DIR, targetProject);
    scadFiles = findScadFiles(projectPath);
  } else {
    scadFiles = findScadFiles(MODELS_DIR);
  }

  if (scadFiles.length === 0) {
    console.error('❌ No se encontraron archivos .scad para compilar.');
    process.exit(1);
  }

  for (const file of scadFiles) {
    const basename = path.basename(file, '.scad');
    const projectDir = path.dirname(file);
    const projectExportDir = path.join(projectDir, 'exports');

    // Crear directorio de exports del proyecto si no existe
    if (!fs.existsSync(projectExportDir)) {
      fs.mkdirSync(projectExportDir, { recursive: true });
    }

    const relFile = path.relative(ROOT_DIR, file);
    console.log(`📂 Procesando modelo: ${relFile}`);
    const content = fs.readFileSync(file, 'utf-8');
    const availableParts = extractPartsFromScad(content);

    if (availableParts.length === 0) {
      console.log(`   ℹ️  No se detectaron subpiezas específicas, compilando archivo completo...`);
      await compilePart(file, 'default', `${basename}.stl`, projectExportDir);
      continue;
    }

    const partsToProcess = targetPart 
      ? availableParts.filter(p => p.id === targetPart)
      : availableParts;

    if (partsToProcess.length === 0) {
      console.warn(`⚠️  La pieza '${targetPart}' no fue encontrada en ${relFile}.`);
      continue;
    }

    let index = 1;
    for (const p of partsToProcess) {
      const outName = `${index}_${basename}_${p.id}.stl`;
      await compilePart(file, p.id, outName, projectExportDir);
      index++;
    }
  }

  console.log(`\n🎉 ¡Compilación finalizada exitosamente!\n`);
}

main().catch(err => {
  console.error('\n❌ Error durante la compilación:', err);
  process.exit(1);
});
