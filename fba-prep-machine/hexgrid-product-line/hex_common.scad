// ============================================================
// HexGrid Modular Organizer System - Core Geometry
// All pieces share hex footprint + magnetic connection system
// Dimensions in millimeters
// ============================================================

// --- Hex Parameters ---
// "Size" = flat-to-flat distance (across flats)
HEX_SIZE      = 70;        // 70mm flat-to-flat (~2.75 inches)
HEX_RADIUS    = HEX_SIZE / 2 / cos(30);  // Circumscribed radius (vertex-to-center)
HEX_WALL      = 2.4;       // Wall thickness (6 perimeters at 0.4mm nozzle)
HEX_BASE      = 2.0;       // Floor thickness

// Connection system: 6mm x 3mm disc magnets in hex edges
MAG_DIA       = 6.2;       // Magnet hole diameter (6mm + tolerance)
MAG_DEPTH     = 3.2;       // Magnet hole depth (3mm + press-fit)
MAG_INSET     = 4.0;       // Distance from outer edge to magnet center
MAG_Z         = 10;        // Height of magnets from base (consistent across all products)

// Grid spacing (center-to-center when tiled)
HEX_SPACING   = HEX_SIZE + 0.5;  // Tiny gap for easy attach/detach

// --- Product Heights ---
CUP_HEIGHT       = 100;    // Pencil cup
DRAWER_HEIGHT    = 50;     // Mini drawer
SHELF_HEIGHT     = 25;     // Flat tray
PLANTER_HEIGHT   = 65;     // Succulent pot
HOOK_HEIGHT      = 30;     // Hook base
CABLE_HEIGHT     = 20;     // Cable clip base

// --- Print Quality ---
$fn = 6;  // Hexagons! Override to higher for round features
FN_ROUND = 40;  // For round features like magnet holes

// --- Visual (for preview renders) ---
PREVIEW_MAGNETS = true;

// ============================================================
// CORE MODULES
// ============================================================

// Basic hexagonal prism (flat-to-flat = HEX_SIZE)
module hex_prism(h, size=HEX_SIZE) {
    r = size / 2 / cos(30);
    cylinder(r=r, h=h, $fn=6);
}

// Hollow hex shell (outer hex minus inner hex)
module hex_shell(h, size=HEX_SIZE, wall=HEX_WALL) {
    difference() {
        hex_prism(h, size);
        translate([0, 0, HEX_BASE])
            hex_prism(h, size - wall*2);
    }
}

// Hex outline only (no floor) - for open-bottom pieces
module hex_ring(h, size=HEX_SIZE, wall=HEX_WALL) {
    difference() {
        hex_prism(h, size);
        translate([0, 0, -1])
            hex_prism(h + 2, size - wall*2);
    }
}

// ============================================================
// MAGNETIC CONNECTION SYSTEM
// ============================================================

// Magnet holes on all 6 edges (subtract this from any hex piece)
module mag_holes(z_pos=MAG_Z) {
    for (a = [0:60:300]) {
        rotate([0, 0, a])
            translate([HEX_SIZE/2 - MAG_INSET, 0, z_pos])
                cylinder(d=MAG_DIA, h=MAG_DEPTH, $fn=FN_ROUND);
    }
}

// Magnet holes from the outside (for pieces where you insert from edge)
module mag_holes_edge(z_pos=MAG_Z) {
    for (a = [0:60:300]) {
        rotate([0, 0, a])
            translate([HEX_SIZE/2 + 1, 0, z_pos])
                rotate([0, -90, 0])
                    cylinder(d=MAG_DIA, h=MAG_DEPTH + 1, $fn=FN_ROUND);
    }
}

// Visual magnet preview (for assembly renders)
module mag_preview(z_pos=MAG_Z) {
    if (PREVIEW_MAGNETS) {
        color("Silver")
        for (a = [0:60:300]) {
            rotate([0, 0, a])
                translate([HEX_SIZE/2 - MAG_INSET, 0, z_pos])
                    cylinder(d=6, h=3, $fn=FN_ROUND);
        }
    }
}

// ============================================================
// DECORATIVE ELEMENTS
// ============================================================

// Chamfered top edge (looks premium, comfortable to touch)
module hex_chamfer_top(h, size=HEX_SIZE, chamfer=1.5) {
    translate([0, 0, h - chamfer])
        difference() {
            hex_prism(chamfer + 1, size);
            hex_prism(chamfer + 1, size - chamfer*2);
            // Angled cut
            difference() {
                translate([0, 0, 0])
                    hex_prism(chamfer + 1, size + 1);
                translate([0, 0, -0.1])
                    cylinder(r1=size/2/cos(30), r2=size/2/cos(30) - chamfer - 0.5,
                             h=chamfer + 0.2, $fn=6);
            }
        }
}

// Honeycomb pattern for decorative walls or drainage
module honeycomb_pattern(w, h, cell_size=8, wall=1.5) {
    spacing_x = cell_size + wall;
    spacing_y = (cell_size + wall) * sin(60);
    cols = ceil(w / spacing_x) + 1;
    rows = ceil(h / spacing_y) + 1;

    intersection() {
        cube([w, h, cell_size]);
        for (row = [0:rows])
            for (col = [0:cols]) {
                x = col * spacing_x + (row % 2) * spacing_x/2;
                y = row * spacing_y;
                translate([x, y, -1])
                    cylinder(d=cell_size, h=cell_size + 2, $fn=6);
            }
    }
}

// ============================================================
// UTILITY MODULES
// ============================================================

// Rounded cylinder (for smooth edges on round features)
module rcylinder(d, h, r=1) {
    $fn = FN_ROUND;
    hull() {
        translate([0, 0, r])
            cylinder(d=d-2*r, h=h-2*r);
        translate([0, 0, 0])
            cylinder(d=d, h=0.01);
        translate([0, 0, h-0.01])
            cylinder(d=d, h=0.01);
    }
}

// Text emboss (for branding on bottom)
module brand_text(text_str="HexGrid", size=6) {
    $fn = FN_ROUND;
    linear_extrude(height=0.6)
        text(text_str, size=size, halign="center", valign="center",
             font="Liberation Sans:style=Bold");
}

// Anti-slip feet (small bumps on bottom)
module anti_slip_feet() {
    $fn = FN_ROUND;
    for (a = [0:60:300]) {
        rotate([0, 0, a + 30])
            translate([HEX_SIZE/2 - 12, 0, 0])
                cylinder(d=4, h=0.8);
    }
}

// ============================================================
// GRID LAYOUT HELPERS (for product photos / assembly preview)
// ============================================================

// Position a module at hex grid coordinate (q, r) using axial coordinates
module hex_place(q, r) {
    x = HEX_SPACING * (q + r * cos(60));
    y = HEX_SPACING * r * sin(60);
    translate([x, y, 0])
        children();
}

// Ring of hexes at distance n from center
module hex_ring_positions(n) {
    if (n == 0) {
        children();
    } else {
        for (i = [0:n-1]) {
            hex_place(-n+i, n) children();      // Edge 0
            hex_place(i, n-i) children();        // Edge 1  (skip when i=n)
            hex_place(n, -i) children();         // Edge 2
            hex_place(n-i, -n) children();       // Edge 3
            hex_place(-i, -n+i) children();      // Edge 4
            hex_place(-n, i) children();         // Edge 5
        }
    }
}
