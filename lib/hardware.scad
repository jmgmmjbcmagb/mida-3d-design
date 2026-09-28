// ====================================================================
// HARDWARE & FASTENERS LIBRARY FOR 3D PRINTING
// ====================================================================
// Standards for Screws, Heat-Set Inserts, Nuts, Magnets & Bearings

include <bambu_standards.scad>

// --------------------------------------------------------------------
// 1. METRIC SCREW DIMENSIONS (Clearance & Pilot holes)
// --------------------------------------------------------------------
// ISO Metric coarse screw clearance standards (with 3D print compensation)
function screw_clearance_d(size) = 
    (size == "M2")   ? 2.3 :
    (size == "M2.5") ? 2.8 :
    (size == "M3")   ? 3.4 :
    (size == "M4")   ? 4.5 :
    (size == "M5")   ? 5.5 :
    (size == "M6")   ? 6.6 : 3.4;

function screw_tap_d(size) = 
    (size == "M2")   ? 1.7 :
    (size == "M2.5") ? 2.1 :
    (size == "M3")   ? 2.6 :
    (size == "M4")   ? 3.4 :
    (size == "M5")   ? 4.3 :
    (size == "M6")   ? 5.1 : 2.6;

// DIN 912 Socket Head dimensions (Diameter & Head Height)
function cap_head_d(size) = 
    (size == "M2")   ? 3.8 + TOL_SNUG_FIT*2 :
    (size == "M2.5") ? 4.5 + TOL_SNUG_FIT*2 :
    (size == "M3")   ? 5.5 + TOL_SNUG_FIT*2 :
    (size == "M4")   ? 7.0 + TOL_SNUG_FIT*2 :
    (size == "M5")   ? 8.5 + TOL_SNUG_FIT*2 :
    (size == "M6")   ? 10.0 + TOL_SNUG_FIT*2 : 6.0;

function cap_head_h(size) = 
    (size == "M2")   ? 2.0 + 0.3 :
    (size == "M2.5") ? 2.5 + 0.3 :
    (size == "M3")   ? 3.0 + 0.3 :
    (size == "M4")   ? 4.0 + 0.3 :
    (size == "M5")   ? 5.0 + 0.3 :
    (size == "M6")   ? 6.0 + 0.3 : 3.3;

// DIN 7991 Countersunk Flat Head dimensions
function countersunk_head_d(size) =
    (size == "M2")   ? 4.0 + TOL_SNUG_FIT :
    (size == "M2.5") ? 5.0 + TOL_SNUG_FIT :
    (size == "M3")   ? 6.0 + TOL_SNUG_FIT :
    (size == "M4")   ? 8.0 + TOL_SNUG_FIT :
    (size == "M5")   ? 10.0 + TOL_SNUG_FIT :
    (size == "M6")   ? 12.0 + TOL_SNUG_FIT : 6.2;

// Module for Screw Hole (clearance hole + optional head recess)
module screw_hole(size="M3", length=20, head_type="none", head_extra_depth=0) {
    // head_type: "none", "socket" (DIN 912), "countersunk" (DIN 7991)
    d_hole = screw_clearance_d(size);
    
    union() {
        // Main shank pass-through
        cylinder(d=d_hole, h=length + 2, center=false);
        
        if (head_type == "socket") {
            dh = cap_head_d(size);
            hh = cap_head_h(size) + head_extra_depth;
            translate([0, 0, length - hh + 0.1])
                cylinder(d=dh, h=hh + 2);
        } else if (head_type == "countersunk") {
            dh = countersunk_head_d(size);
            cone_h = (dh - d_hole) / 2;
            translate([0, 0, length - cone_h + 0.1])
                cylinder(d1=d_hole, d2=dh, h=cone_h);
            if (head_extra_depth > 0) {
                translate([0, 0, length + 0.1])
                    cylinder(d=dh, h=head_extra_depth + 1);
            }
        }
    }
}

// --------------------------------------------------------------------
// 2. HEAT-SET THREADED INSERTS (Ruthex / CNC Kitchen / Standard)
// --------------------------------------------------------------------
// Standard brass inserts (M2, M3, M4, M5) with 8-degree draft angle and lead-in chamfer
function insert_top_d(size) = 
    (size == "M2")   ? 3.2 :
    (size == "M2.5") ? 3.6 :
    (size == "M3")   ? 4.2 :  // Ruthex M3 Standard: 4.0mm OD, hole 4.0-4.2mm
    (size == "M4")   ? 5.8 :  // Ruthex M4 Standard: 5.6mm OD
    (size == "M5")   ? 6.8 :  // Ruthex M5 Standard: 6.4mm OD
    (size == "M6")   ? 8.4 : 4.2;

function insert_bottom_d(size) = 
    (size == "M2")   ? 3.0 :
    (size == "M2.5") ? 3.4 :
    (size == "M3")   ? 4.0 :
    (size == "M4")   ? 5.4 :
    (size == "M5")   ? 6.4 :
    (size == "M6")   ? 8.0 : 4.0;

function insert_depth(size) = 
    (size == "M2")   ? 4.0 + 1.0 :
    (size == "M2.5") ? 5.7 + 1.0 :
    (size == "M3")   ? 5.7 + 1.2 :  // Extra 1.2mm for molten plastic well
    (size == "M4")   ? 8.1 + 1.5 :
    (size == "M5")   ? 9.5 + 1.5 :
    (size == "M6")   ? 12.7 + 2.0 : 6.0;

// Subtractive module for heat-set brass insert pocket
module heat_set_insert_pocket(size="M3", extra_well=1.0) {
    d_top = insert_top_d(size);
    d_bot = insert_bottom_d(size);
    h_insert = insert_depth(size);
    
    union() {
        // Tapered insert pocket
        cylinder(d1=d_bot, d2=d_top, h=h_insert);
        // Top lead-in chamfer
        translate([0, 0, h_insert - 0.5])
            cylinder(d1=d_top, d2=d_top + 0.8, h=0.6);
        // Screw clearance tunnel below insert
        translate([0, 0, -10])
            cylinder(d=screw_clearance_d(size), h=10.1);
    }
}

// --------------------------------------------------------------------
// 3. CAPTIVE HEX NUTS (DIN 934)
// --------------------------------------------------------------------
function hex_nut_flat_to_flat(size) = 
    (size == "M2")   ? 4.0 + TOL_PRESS_FIT*2 :
    (size == "M2.5") ? 5.0 + TOL_PRESS_FIT*2 :
    (size == "M3")   ? 5.5 + TOL_PRESS_FIT*2 :
    (size == "M4")   ? 7.0 + TOL_PRESS_FIT*2 :
    (size == "M5")   ? 8.0 + TOL_PRESS_FIT*2 :
    (size == "M6")   ? 10.0 + TOL_PRESS_FIT*2 : 5.8;

function hex_nut_thickness(size) = 
    (size == "M2")   ? 1.6 + 0.2 :
    (size == "M2.5") ? 2.0 + 0.2 :
    (size == "M3")   ? 2.4 + 0.3 :
    (size == "M4")   ? 3.2 + 0.3 :
    (size == "M5")   ? 4.0 + 0.4 :
    (size == "M6")   ? 5.0 + 0.4 : 2.7;

// Module for Hex Nut Pocket
module captive_nut_pocket(size="M3", slot_length=0) {
    s = hex_nut_flat_to_flat(size);
    h = hex_nut_thickness(size);
    r_outer = s / sqrt(3); // Point-to-point radius
    
    union() {
        cylinder(r=r_outer, h=h, $fn=6);
        if (slot_length > 0) {
            translate([0, -s/2, 0])
                cube([slot_length, s, h]);
        }
    }
}

// --------------------------------------------------------------------
// 4. NEODYMIUM MAGNET POCKETS
// --------------------------------------------------------------------
module magnet_pocket(diameter=6, thickness=3, tol=TOL_PRESS_FIT) {
    cylinder(d=diameter + tol*2, h=thickness + 0.3);
}

// --------------------------------------------------------------------
// 5. STANDARD BALL BEARINGS (608, 623, 624, 625, 688)
// --------------------------------------------------------------------
function bearing_specs(type) =
    (type == "608") ? [8, 22, 7] :     // Skate bearing: ID 8mm, OD 22mm, W 7mm
    (type == "623") ? [3, 10, 4] :     // ID 3mm, OD 10mm, W 4mm
    (type == "624") ? [4, 13, 5] :     // ID 4mm, OD 13mm, W 5mm
    (type == "625") ? [5, 16, 5] :     // ID 5mm, OD 16mm, W 5mm
    (type == "688") ? [8, 16, 5] : [8, 22, 7];

module bearing_pocket(type="608", lip_width=1.0, tol=TOL_PRESS_FIT) {
    specs = bearing_specs(type);
    id = specs[0];
    od = specs[1];
    w  = specs[2];
    
    union() {
        // Main bearing outer seat
        cylinder(d=od + tol*2, h=w + 0.2);
        // Through hole with clearance for inner ring rotation
        translate([0, 0, -5])
            cylinder(d=od - lip_width*2, h=w + 10);
    }
}
