// ============================================================
// HexGrid Product: Wall Mount Grid Base
// SKU: HG-WM3-015 (3-hex wall mount)
// SKU: HG-WM7-015 (7-hex wall mount / full ring)
// Print time: ~3-5 hrs | Filament: ~60-100g | Sell: $18-30
// The "base station" - everything else snaps onto this
// ============================================================

use <hex_common.scad>
include <hex_common.scad>

// --- Wall Mount Parameters ---
MOUNT_THICK    = 12;         // How thick the wall plate is
MOUNT_STYLE    = "3-row";    // "single", "3-hex", "7-hex", "3-row", "custom"

// Mounting hardware
SCREW_DIA      = 5;
SCREW_HEAD_DIA = 10;
ANCHOR_TYPE    = "keyhole";  // "keyhole" or "french_cleat"

// Magnet position (top face - pieces attach here)
WALL_MAG_Z     = MOUNT_THICK - MAG_DEPTH;

// --- Single Hex Wall Plate ---
module hex_wall_plate() {
    difference() {
        union() {
            hex_prism(MOUNT_THICK);

            // Reinforcement ring on wall side
            translate([0, 0, -1])
                hex_ring(2, HEX_SIZE + 4, 2);
        }

        // Magnet holes (on FRONT face - pieces stick here)
        translate([0, 0, MOUNT_THICK - MAG_DEPTH])
            for (a = [0:60:300])
                rotate([0, 0, a])
                    translate([HEX_SIZE/2 - MAG_INSET, 0, 0])
                        cylinder(d=MAG_DIA, h=MAG_DEPTH + 1, $fn=FN_ROUND);

        // Keyhole mounting slots (back face)
        translate([0, -12, -1])
            keyhole_mount();
        translate([0, 12, -1])
            keyhole_mount();
    }
}

// --- 3-Hex Horizontal Row ---
module hex_wall_3row() {
    spacing = HEX_SIZE + 1;

    difference() {
        union() {
            // 3 hexes in a row
            for (i = [-1, 0, 1])
                translate([i * spacing, 0, 0])
                    hex_prism(MOUNT_THICK);

            // Connecting bridges between hexes
            for (i = [-1, 0]) {
                translate([i * spacing + HEX_SIZE/2 - 5, -10, 0])
                    cube([spacing - HEX_SIZE + 10, 20, MOUNT_THICK]);
            }

            // Back reinforcement
            translate([-spacing - HEX_SIZE/2, -8, 0])
                cube([spacing * 2 + HEX_SIZE, 16, 3]);
        }

        // Magnet holes on each hex position
        for (i = [-1, 0, 1])
            translate([i * spacing, 0, MOUNT_THICK - MAG_DEPTH])
                for (a = [0:60:300])
                    rotate([0, 0, a])
                        translate([HEX_SIZE/2 - MAG_INSET, 0, 0])
                            cylinder(d=MAG_DIA, h=MAG_DEPTH + 1, $fn=FN_ROUND);

        // Screw holes (4 screws for 3-hex mount)
        for (x = [-spacing, 0, spacing])
            translate([x, 0, -1])
                keyhole_mount();

        // Level indicator line (scribed on back)
        translate([-spacing - HEX_SIZE/3, 0, 0.3])
            cube([spacing*2 + HEX_SIZE*2/3, 0.5, 0.5]);
    }
}

// --- 7-Hex Cluster (center + 6 ring) ---
module hex_wall_7cluster() {
    difference() {
        union() {
            // Center hex
            hex_prism(MOUNT_THICK);

            // 6 surrounding hexes
            for (a = [0:60:300])
                rotate([0, 0, a])
                    translate([HEX_SPACING, 0, 0])
                        hex_prism(MOUNT_THICK);

            // Bridge fills between hexes
            for (a = [0:60:300])
                rotate([0, 0, a])
                    translate([HEX_SPACING/2 - 5, -8, 0])
                        cube([10, 16, MOUNT_THICK]);

            // Outer connecting bridges
            for (a = [0:60:300])
                rotate([0, 0, a + 30]) {
                    translate([HEX_SPACING * 0.87 - 5, -8, 0])
                        cube([10, 16, MOUNT_THICK]);
                }

            // Back plate (full coverage for strength)
            translate([0, 0, 0])
                cylinder(r=HEX_SPACING + HEX_SIZE/2, h=3, $fn=60);
        }

        // Magnet holes on all 7 positions
        for (pos_a = [0:60:300])
            translate([HEX_SPACING * cos(pos_a), HEX_SPACING * sin(pos_a), 0])
                translate([0, 0, MOUNT_THICK - MAG_DEPTH])
                    for (a = [0:60:300])
                        rotate([0, 0, a])
                            translate([HEX_SIZE/2 - MAG_INSET, 0, 0])
                                cylinder(d=MAG_DIA, h=MAG_DEPTH + 1, $fn=FN_ROUND);

        // Center position magnets
        translate([0, 0, MOUNT_THICK - MAG_DEPTH])
            for (a = [0:60:300])
                rotate([0, 0, a])
                    translate([HEX_SIZE/2 - MAG_INSET, 0, 0])
                        cylinder(d=MAG_DIA, h=MAG_DEPTH + 1, $fn=FN_ROUND);

        // Mounting screws (6 around perimeter)
        for (a = [30:60:360])
            rotate([0, 0, a])
                translate([HEX_SPACING + 5, 0, -1])
                    keyhole_mount();

        // Center screw
        translate([0, 0, -1])
            keyhole_mount();
    }
}

// --- French Cleat Mount (alternative to screws) ---
module french_cleat_adapter() {
    cleat_w = 150;
    cleat_h = 40;
    cleat_angle = 45;

    difference() {
        cube([cleat_w, cleat_h, MOUNT_THICK + 5]);

        // 45-degree cleat cut
        translate([-1, cleat_h/2, MOUNT_THICK/2])
            rotate([cleat_angle, 0, 0])
                cube([cleat_w + 2, cleat_h, MOUNT_THICK]);

        // Screw holes for wall-side cleat
        for (x = [20, cleat_w/2, cleat_w - 20])
            translate([x, cleat_h/2, -1])
                cylinder(d=SCREW_DIA, h=MOUNT_THICK + 7, $fn=FN_ROUND);
    }
}

// Wall-side cleat piece
module french_cleat_wall() {
    cleat_w = 150;
    cleat_h = 40;
    cleat_angle = 45;

    difference() {
        cube([cleat_w, cleat_h, 15]);

        // Matching 45-degree cut
        translate([-1, cleat_h/2, 7])
            rotate([-cleat_angle, 0, 0])
                cube([cleat_w + 2, cleat_h, 15]);

        // Wall screw holes
        for (x = [20, cleat_w/2, cleat_w - 20])
            translate([x, cleat_h * 0.7, -1]) {
                cylinder(d=SCREW_DIA, h=17, $fn=FN_ROUND);
                cylinder(d=SCREW_HEAD_DIA, h=4, $fn=FN_ROUND);
            }
    }
}

// --- Keyhole Mount Cutout ---
module keyhole_mount() {
    $fn = FN_ROUND;
    // Head entry hole
    cylinder(d=SCREW_HEAD_DIA, h=5);
    // Shaft slot (slide up to lock)
    hull() {
        cylinder(d=SCREW_DIA, h=MOUNT_THICK + 2);
        translate([0, 8, 0])
            cylinder(d=SCREW_DIA, h=MOUNT_THICK + 2);
    }
    // Head recess
    cylinder(d=SCREW_HEAD_DIA, h=4);
}

// --- Render ---
// hex_wall_3row();
hex_wall_7cluster();

// Variants (uncomment one):
// hex_wall_plate();
// hex_wall_3row();
// hex_wall_7cluster();
// french_cleat_adapter();
// french_cleat_wall();
