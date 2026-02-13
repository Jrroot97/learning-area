// ============================================================
// HexGrid Product: Mini Pull-Out Drawer
// SKU: HG-DRW-050 (50mm tall)
// Print time: ~3 hrs (2 parts) | Filament: ~45g ($0.90) | Sell: $14-18
// Great for: screws, jewelry, SD cards, coins, vitamins
// ============================================================

use <hex_common.scad>
include <hex_common.scad>

// --- Drawer Parameters ---
DRAWER_H      = DRAWER_HEIGHT;  // 50mm
DRAWER_GAP    = 0.4;     // Clearance between drawer and housing
HANDLE_STYLE  = "hex";   // "hex", "pull", or "ring"
SUBDIVIDE     = 0;       // 0=none, 2=halves, 4=quarters

// Derived
INNER_SIZE    = HEX_SIZE - HEX_WALL*2 - DRAWER_GAP*2;  // Drawer body size
DRAWER_DEPTH  = INNER_SIZE * cos(30) - 2;  // How far drawer slides
DRAWER_INNER_H = DRAWER_H - HEX_BASE - 5; // Usable depth inside drawer

// --- Drawer Housing (outer hex body) ---
module drawer_housing() {
    difference() {
        union() {
            // Outer hex shell
            hex_shell(DRAWER_H);

            // Base
            hex_prism(HEX_BASE + 1);

            // Anti-slip feet
            anti_slip_feet();

            // Drawer rails (side guides)
            translate([0, 0, HEX_BASE + 1])
                for (a = [90, 270]) {
                    rotate([0, 0, a])
                        translate([INNER_SIZE/2/cos(30) + DRAWER_GAP, -1.5, 0])
                            cube([1.5, 3, DRAWER_INNER_H + 3]);
                }
        }

        // Magnet holes
        mag_holes(MAG_Z);

        // Drawer slot (front opening)
        translate([0, 0, HEX_BASE + 1])
            hex_prism(DRAWER_H, INNER_SIZE + DRAWER_GAP);

        // Front opening (cut away front wall for drawer access)
        translate([-INNER_SIZE/2, -HEX_SIZE/2 - 1, HEX_BASE])
            cube([INNER_SIZE, HEX_WALL + 2, DRAWER_H]);

        // Brand text
        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();

        // Drawer stop slot (rear)
        translate([-3, HEX_SIZE/2 - HEX_WALL - 5, HEX_BASE + DRAWER_INNER_H])
            cube([6, 3, 3]);
    }
}

// --- Drawer Insert (the sliding part) ---
module drawer_insert() {
    insert_size = INNER_SIZE - 1;
    insert_r    = insert_size / 2 / cos(30);

    difference() {
        union() {
            // Hex body
            cylinder(r=insert_r, h=DRAWER_INNER_H + HEX_BASE, $fn=6);

            // Handle
            if (HANDLE_STYLE == "hex") {
                drawer_handle_hex();
            } else if (HANDLE_STYLE == "pull") {
                drawer_handle_pull();
            } else {
                drawer_handle_ring();
            }

            // Drawer stop tab
            translate([-2.5, insert_r - 3, DRAWER_INNER_H])
                cube([5, 2.5, 2.5]);
        }

        // Hollow interior
        translate([0, 0, HEX_BASE])
            cylinder(r=insert_r - HEX_WALL, h=DRAWER_INNER_H + 1, $fn=6);

        // Rail grooves (match housing rails)
        for (a = [90, 270]) {
            rotate([0, 0, a])
                translate([insert_r - 0.5, -2, HEX_BASE])
                    cube([2.5, 4, DRAWER_INNER_H + 2]);
        }

        // Subdivisions
        if (SUBDIVIDE > 0) {
            drawer_dividers(insert_r - HEX_WALL, DRAWER_INNER_H);
        }
    }
}

// --- Handle Styles ---
module drawer_handle_hex() {
    // Small hex knob on front face
    translate([0, -(HEX_SIZE/2 - HEX_WALL), DRAWER_INNER_H/2 + HEX_BASE])
        rotate([90, 0, 0]) {
            cylinder(r=8/cos(30), h=8, $fn=6);
            // Finger grip indent
            translate([0, 0, 6])
                sphere(d=10, $fn=FN_ROUND);
        }
}

module drawer_handle_pull() {
    // U-shaped pull handle
    handle_w = 25;
    handle_h = 12;
    translate([-handle_w/2, -HEX_SIZE/2 + HEX_WALL - 10,
               DRAWER_INNER_H/2 + HEX_BASE - handle_h/2]) {
        difference() {
            cube([handle_w, 10, handle_h]);
            translate([3, -1, 3])
                cube([handle_w - 6, 8, handle_h - 6]);
        }
    }
}

module drawer_handle_ring() {
    // Ring pull
    translate([0, -HEX_SIZE/2 + HEX_WALL - 5,
               DRAWER_INNER_H/2 + HEX_BASE])
        rotate([90, 0, 0]) {
            $fn = FN_ROUND;
            difference() {
                cylinder(d=18, h=3);
                cylinder(d=12, h=4);
            }
            // Pivot pin
            translate([0, 0, -3])
                cylinder(d=4, h=3);
        }
}

// --- Drawer Internal Dividers ---
module drawer_dividers(r, h) {
    translate([0, 0, HEX_BASE]) {
        if (SUBDIVIDE == 2) {
            // Half divider
            translate([-1, -r, 0])
                cube([2, r*2, h]);
        }
        if (SUBDIVIDE == 4) {
            // Cross divider
            translate([-1, -r, 0])
                cube([2, r*2, h]);
            translate([-r, -1, 0])
                cube([r*2, 2, h]);
        }
    }
}

// --- Stackable Double Drawer ---
module hex_drawer_double() {
    // Two drawers stacked vertically
    drawer_housing();
    translate([0, 0, DRAWER_H])
        drawer_housing();
}

// --- Assembly View ---
module drawer_assembly() {
    color("SteelBlue")
        drawer_housing();

    // Drawer pulled out slightly
    color("Orange")
        translate([0, -15, 1])
            drawer_insert();

    mag_preview();
}

// --- Render ---
drawer_assembly();

// Individual parts (uncomment for printing):
// drawer_housing();
// drawer_insert();
