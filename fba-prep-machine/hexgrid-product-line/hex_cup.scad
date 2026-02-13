// ============================================================
// HexGrid Product: Pencil/Pen Cup
// SKU: HG-CUP-100 (100mm tall)
// Print time: ~2.5 hrs | Filament: ~35g ($0.70) | Sell: $12-15
// ============================================================

use <hex_common.scad>
include <hex_common.scad>

// --- Cup Variants ---
// Change these for different product listings:
CUP_H        = CUP_HEIGHT;   // 100mm standard, 70mm short, 130mm tall
DIVIDER      = false;         // true = 3-compartment divider
PENCIL_SLOTS = false;         // true = individual pencil holes in base

// --- Main Cup ---
module hex_cup() {
    difference() {
        union() {
            // Outer hex shell
            hex_shell(CUP_H);

            // Reinforced base
            hex_prism(HEX_BASE + 1);

            // Anti-slip feet
            anti_slip_feet();
        }

        // Magnet holes (accessible from top during assembly)
        mag_holes(MAG_Z);

        // Interior chamfer at base (easier to clean)
        translate([0, 0, HEX_BASE])
            cylinder(r1=(HEX_SIZE/2/cos(30)) - HEX_WALL - 3,
                     r2=(HEX_SIZE/2/cos(30)) - HEX_WALL,
                     h=3, $fn=6);

        // Top edge chamfer
        translate([0, 0, CUP_H - 1])
            difference() {
                hex_prism(2);
                translate([0, 0, -0.1])
                    cylinder(r1=HEX_SIZE/2/cos(30) - 0.5,
                             r2=HEX_SIZE/2/cos(30) - 1.5,
                             h=2.1, $fn=6);
            }

        // Brand text on bottom
        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();
    }

    // Optional: 3-compartment divider
    if (DIVIDER) {
        cup_divider();
    }

    // Optional: Individual pencil slots
    if (PENCIL_SLOTS) {
        pencil_slot_base();
    }
}

// --- 3-Compartment Divider ---
module cup_divider() {
    div_height = CUP_H * 0.6;  // Doesn't go all the way up
    div_thick  = 1.6;

    // Y-shaped divider (3 equal sections)
    translate([0, 0, HEX_BASE]) {
        for (a = [0, 120, 240]) {
            rotate([0, 0, a])
                translate([-div_thick/2, 0, 0])
                    cube([div_thick,
                          HEX_SIZE/2 - HEX_WALL - 1,
                          div_height]);
        }
    }
}

// --- Pencil Slot Base Insert ---
module pencil_slot_base() {
    slot_dia = 9;     // Standard pencil diameter + clearance
    slot_depth = 15;  // How deep the slots go

    translate([0, 0, HEX_BASE]) {
        difference() {
            // Solid insert
            hex_prism(slot_depth, HEX_SIZE - HEX_WALL*2 - 1);

            // Pencil holes in hex pattern
            for (ring = [0:2]) {
                if (ring == 0) {
                    // Center hole
                    translate([0, 0, -1])
                        cylinder(d=slot_dia, h=slot_depth + 2, $fn=FN_ROUND);
                } else {
                    for (a = [0:60:300]) {
                        rotate([0, 0, a + (ring == 2 ? 30 : 0)])
                            translate([ring * 12, 0, -1])
                                cylinder(d=slot_dia, h=slot_depth + 2, $fn=FN_ROUND);
                    }
                }
            }
        }
    }
}

// --- Tall Variant (Vase/Brush Holder) ---
module hex_cup_tall() {
    CUP_H_TALL = 130;
    difference() {
        union() {
            hex_shell(CUP_H_TALL);
            hex_prism(HEX_BASE + 1);
            anti_slip_feet();
        }
        mag_holes(MAG_Z);
        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();
    }
}

// --- Short Variant (Business Card/Post-It Holder) ---
module hex_cup_short() {
    CUP_H_SHORT = 45;
    difference() {
        union() {
            hex_shell(CUP_H_SHORT);
            hex_prism(HEX_BASE + 1);
            anti_slip_feet();
        }
        mag_holes(MAG_Z);
        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();
    }
}

// --- Render ---
hex_cup();
mag_preview();

// Variants (uncomment one):
// hex_cup_tall();
// hex_cup_short();
