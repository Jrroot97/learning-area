// ============================================================
// HexGrid Product: Succulent Planter with Drainage
// SKU: HG-PLT-065 (65mm tall)
// Print time: ~2 hrs | Filament: ~30g ($0.60) | Sell: $10-14
// Great for: succulents, air plants, small herbs, cacti
// ============================================================

use <hex_common.scad>
include <hex_common.scad>

// --- Planter Parameters ---
PLANTER_H        = PLANTER_HEIGHT;  // 65mm
DRAIN_HOLES      = true;    // Drainage holes in bottom
DRAIN_HOLE_DIA   = 6;       // Drainage hole diameter
SAUCER           = true;    // Include removable saucer/drip tray
SAUCER_H         = 8;       // Saucer height
SAUCER_GAP       = 0.5;     // Gap between pot and saucer

// Decorative options
PATTERN          = "smooth"; // "smooth", "honeycomb", "ridged", "faceted"
INNER_TAPER      = 3;       // Slight inward taper at bottom (helps roots)

// --- Main Planter Pot ---
module hex_planter() {
    difference() {
        union() {
            // Outer shell (slightly tapered for style)
            hull() {
                hex_prism(1, HEX_SIZE - 4);  // Bottom slightly narrower
                translate([0, 0, PLANTER_H - 1])
                    hex_prism(1, HEX_SIZE);   // Top full width
            }

            // Rim (thicker top edge)
            translate([0, 0, PLANTER_H - 3])
                hex_ring(3, HEX_SIZE + 2, HEX_WALL + 1);
        }

        // Interior cavity
        translate([0, 0, HEX_BASE + 1])
            hull() {
                hex_prism(1, HEX_SIZE - HEX_WALL*2 - INNER_TAPER*2 - 4);
                translate([0, 0, PLANTER_H - HEX_BASE - 2])
                    hex_prism(1, HEX_SIZE - HEX_WALL*2);
            }

        // Drainage holes
        if (DRAIN_HOLES) {
            // Center hole
            translate([0, 0, -1])
                cylinder(d=DRAIN_HOLE_DIA, h=HEX_BASE + 3, $fn=FN_ROUND);
            // Ring of holes
            for (a = [0:60:300])
                rotate([0, 0, a])
                    translate([15, 0, -1])
                        cylinder(d=DRAIN_HOLE_DIA, h=HEX_BASE + 3, $fn=FN_ROUND);
        }

        // Magnet holes — NOTE: z=8 (not MAG_Z=10) because the tapered
        // base is thinner at the bottom. 2mm Z-offset vs neighbors is OK:
        // 6mm disc magnets attract through ~3mm, and lateral alignment is exact.
        // Verified in master_assembly.scad fitment check.
        mag_holes(8);

        // Decorative pattern
        if (PATTERN == "honeycomb") {
            planter_honeycomb();
        }
        if (PATTERN == "ridged") {
            planter_ridges();
        }

        // Brand text
        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();
    }
}

// --- Drip Saucer ---
module hex_saucer() {
    saucer_size = HEX_SIZE + 4;  // Slightly wider than pot

    difference() {
        union() {
            // Saucer body
            hex_prism(SAUCER_H, saucer_size);

            // Anti-slip feet
            for (a = [0:60:300])
                rotate([0, 0, a + 30])
                    translate([saucer_size/2 - 10, 0, 0])
                        cylinder(d=4, h=0.8, $fn=FN_ROUND);
        }

        // Bowl recess (catches water)
        translate([0, 0, 2])
            hex_prism(SAUCER_H, saucer_size - 4);

        // Pot registration ring (keeps pot centered)
        translate([0, 0, 2])
            difference() {
                hex_prism(2, HEX_SIZE - 2);
                hex_prism(3, HEX_SIZE - 6);
            }

        // Brand text
        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text("HexGrid", 5);
    }
}

// --- Decorative Patterns ---
module planter_honeycomb() {
    cell = 8;
    wall = 1.5;
    // Wrap honeycomb pattern around each hex face
    for (face = [0:5]) {
        rotate([0, 0, face * 60])
            translate([HEX_SIZE/2 - 1, -HEX_SIZE/3, 10])
                rotate([0, 90, 0])
                    honeycomb_pattern(PLANTER_H - 15, HEX_SIZE * 0.6, cell, wall);
    }
}

module planter_ridges() {
    // Horizontal grooves
    for (z = [8 : 6 : PLANTER_H - 8]) {
        translate([0, 0, z])
            difference() {
                hex_prism(2, HEX_SIZE + 2);
                hex_prism(3, HEX_SIZE - 2);
            }
    }
}

// --- Self-Watering Variant ---
module hex_planter_self_water() {
    reservoir_h = 15;  // Water reservoir at bottom

    difference() {
        union() {
            // Outer shell (full height including reservoir)
            hex_shell(PLANTER_H + reservoir_h);
            hex_prism(HEX_BASE + 1, HEX_SIZE);
        }

        // Magnet holes
        mag_holes(MAG_Z);

        // Interior (above false floor)
        translate([0, 0, HEX_BASE + reservoir_h])
            hex_prism(PLANTER_H + 1, HEX_SIZE - HEX_WALL*2);

        // Water fill port (side hole near base)
        rotate([0, 0, 0])
            translate([HEX_SIZE/2 - 1, -5, HEX_BASE + 2])
                cube([5, 10, reservoir_h - 4]);
    }

    // False floor with wicking holes
    translate([0, 0, HEX_BASE + reservoir_h - 2]) {
        difference() {
            hex_prism(2, HEX_SIZE - HEX_WALL*2 - 1);
            // Wicking holes
            for (a = [0:60:300])
                rotate([0, 0, a])
                    translate([12, 0, -1])
                        cylinder(d=5, h=4, $fn=FN_ROUND);
            translate([0, 0, -1])
                cylinder(d=8, h=4, $fn=FN_ROUND);
        }
    }
}

// --- Assembly View ---
module planter_assembly() {
    // Saucer
    color("Tan")
        hex_saucer();

    // Planter sitting on saucer
    color("ForestGreen")
        translate([0, 0, SAUCER_H - 1])
            hex_planter();

    mag_preview(SAUCER_H - 1 + 8);
}

// --- Render ---
planter_assembly();

// Individual parts (uncomment one):
// hex_planter();
// hex_saucer();
// hex_planter_self_water();
