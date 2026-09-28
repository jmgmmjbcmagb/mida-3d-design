// ====================================================================
// BAMBU LAB A1 PRINTING & MECHANICAL ENGINEERING STANDARDS LIBRARY
// ====================================================================
// Parameters & tolerances specifically tuned for Bambu Lab A1 (0.4mm nozzle)

// --------------------------------------------------------------------
// 1. BAMBU LAB A1 MACHINE SPECIFICATIONS
// --------------------------------------------------------------------
BAMBU_A1_BED_X = 256;
BAMBU_A1_BED_Y = 256;
BAMBU_A1_BED_Z = 256;

// Recommended minimum feature sizes for 0.4mm nozzle
NOZZLE_DIAMETER = 0.4;
MIN_WALL_THICKNESS = 1.2;     // 3 perimeters (0.4 * 3)
MIN_FLOOR_CEILING = 1.2;      // 6 layers at 0.2mm layer height
MIN_PIN_DIAMETER = 2.0;       // Minimum reliable vertical pin
MIN_EMBOSS_DETAIL = 0.4;      // Min width for embossed/debossed text
MAX_OVERHANG_ANGLE = 45;      // Safe overhang angle without support
SAFE_BRIDGE_SPAN = 25.0;      // Safe bridging length in mm

// --------------------------------------------------------------------
// 2. FDM FIT TOLERANCES (Diametral / Bilateral Clearances in mm)
// --------------------------------------------------------------------
// Add these tolerances to holes, or subtract from outer shafts
TOL_PRESS_FIT   = 0.10; // Tight friction fit (magnets, fixed dowels, bearing outer ring)
TOL_SNUG_FIT    = 0.20; // Sliding fit, interlocking lids, snap joints
TOL_LOOSE_FIT   = 0.35; // Free motion, rotating axles, hinge pins
TOL_COARSE_FIT  = 0.50; // High-clearance pass-through holes

// Quality circle smoothness
$fn = 64;

// --------------------------------------------------------------------
// 3. PRINTER BED BOUNDS VALIDATOR
// --------------------------------------------------------------------
module validate_bambu_bounds(size=[10,10,10]) {
    if (size[0] > BAMBU_A1_BED_X || size[1] > BAMBU_A1_BED_Y || size[2] > BAMBU_A1_BED_Z) {
        echo("<font color='red'><b>WARNING: Part exceeds Bambu Lab A1 build volume (256x256x256mm)!</b></font>");
    } else {
        echo("<font color='green'>Part dimensions [", size[0], ",", size[1], ",", size[2], "] fit inside Bambu Lab A1.</font>");
    }
}

// --------------------------------------------------------------------
// 4. DFAM UTILITIES (Design for Additive Manufacturing)
// --------------------------------------------------------------------

// Teardrop horizontal hole (prints cleanly horizontally without supports)
module horizontal_teardrop_hole(r=2, d=undef, h=20, center=false) {
    radius = (d != undef) ? d/2 : r;
    rotate([0, 90, 0])
    rotate([0, 0, 90])
    linear_extrude(height=h, center=center)
    polygon([
        [0, 0],
        [-radius, 0],
        [-radius, -radius],
        [0, -radius*sqrt(2)],
        [radius, -radius],
        [radius, 0],
        [0, radius]
    ]);
}

// 45-degree chamfered cylinder base to eliminate elephant's foot
module anti_elephant_foot_cylinder(r=5, h=10, chamfer=0.4) {
    cylinder(r1=r-chamfer, r2=r, h=chamfer);
    translate([0,0,chamfer])
    cylinder(r=r, h=h-chamfer);
}

// Interlocking Dovetail Tenon (Male)
module dovetail_tenon(width=15, length=10, height=20, angle=15, clearance=0) {
    w_top = width - clearance;
    w_bottom = width + 2 * length * tan(angle) - clearance;
    linear_extrude(height=height)
    polygon([
        [-w_top/2, 0],
        [w_top/2, 0],
        [w_bottom/2, length],
        [-w_bottom/2, length]
    ]);
}

// Interlocking Dovetail Mortise (Female) with tolerance
module dovetail_mortise(width=15, length=10, height=20, angle=15, tol=TOL_SNUG_FIT) {
    dovetail_tenon(width=width, length=length+tol, height=height+1, angle=angle, clearance=-tol);
}

// Snap-fit cantilever joint
module cantilever_snap_hook(length=15, width=8, thickness=2, hook_depth=1.5, hook_angle=45) {
    cube([width, thickness, length]);
    translate([0, thickness, length - hook_depth * tan(hook_angle)])
    rotate([hook_angle, 0, 0])
    cube([width, hook_depth * sqrt(2), hook_depth]);
}
