// ============================================================
// FBA Prep Machine - Turntable Barcode Scan Station
// Spins bottle to find UPC, then positions for blank label cover
// Print: 0.2mm layers, 4 walls, 30% infill, PETG recommended
// ============================================================

use <common.scad>
include <common.scad>

// --- Turntable Parameters ---
TURNTABLE_DIA     = 100;    // Turntable disk diameter
TURNTABLE_THICK   = 5;      // Disk thickness
SHAFT_COUPLER_DIA = 8;      // Coupler outer diameter
SHAFT_HOLE_DIA    = NEMA17_SHAFT_DIA + 0.2;  // 5.2mm with tolerance
RUBBER_RING_DIA   = TURNTABLE_DIA - 10;  // Groove for rubber band grip
RUBBER_RING_WIDTH = 3;
RUBBER_RING_DEPTH = 2;

BASE_HEIGHT       = 15;     // Base platform height (clearance for motor)
BASE_WIDTH        = NEMA17_SIZE + 30;
BASE_DEPTH        = NEMA17_SIZE + 60;  // Extra depth for scanner mount

// Bottle centering guide
GUIDE_HEIGHT      = 80;     // How tall the centering guides are
GUIDE_WALL        = 3;
GUIDE_CLEARANCE   = 5;      // Extra room beyond bottle size
GUIDE_INNER       = BOTTLE_WIDTH + GUIDE_CLEARANCE;

// Scanner arm
SCANNER_ARM_LEN   = 60;
SCANNER_ARM_WIDTH = 25;
SCANNER_ARM_THICK = 4;

// --- Base Platform (houses NEMA 17 underneath) ---
module turntable_base() {
    difference() {
        union() {
            // Main platform
            rounded_rect(BASE_WIDTH, BASE_DEPTH, BASE_HEIGHT, r=3);

            // Chute interface walls (input side)
            translate([BASE_WIDTH/2 - CHUTE_DEPTH/2 - CHUTE_WALL, 0, 0])
                cube([CHUTE_WALL, 20, BASE_HEIGHT + CHUTE_HEIGHT]);
            translate([BASE_WIDTH/2 + CHUTE_DEPTH/2, 0, 0])
                cube([CHUTE_WALL, 20, BASE_HEIGHT + CHUTE_HEIGHT]);

            // Chute interface walls (output side)
            translate([BASE_WIDTH/2 - CHUTE_DEPTH/2 - CHUTE_WALL, BASE_DEPTH - 20, 0])
                cube([CHUTE_WALL, 20, BASE_HEIGHT + CHUTE_HEIGHT]);
            translate([BASE_WIDTH/2 + CHUTE_DEPTH/2, BASE_DEPTH - 20, 0])
                cube([CHUTE_WALL, 20, BASE_HEIGHT + CHUTE_HEIGHT]);
        }

        // NEMA 17 motor pocket (underneath center)
        translate([BASE_WIDTH/2, BASE_DEPTH/2 - 10, -1]) {
            // Shaft hole through platform
            cylinder(d=NEMA17_BOSS_DIA + 2, h=BASE_HEIGHT + 2);

            // Mounting screw holes
            for (x = [-1, 1])
                for (y = [-1, 1])
                    translate([x * NEMA17_HOLE_SPACING/2,
                              y * NEMA17_HOLE_SPACING/2, 0])
                        cylinder(d=M3_DIA, h=BASE_HEIGHT + 2);
        }

        // Wire routing channel underneath
        translate([5, BASE_DEPTH/2 - 10 - 5, 0])
            cube([BASE_WIDTH/2 - NEMA17_SIZE/2 - 5, 10, 5]);
    }
}

// --- Turntable Disk ---
module turntable_disk() {
    difference() {
        union() {
            // Main disk
            cylinder(d=TURNTABLE_DIA, h=TURNTABLE_THICK);

            // Shaft coupler (center hub)
            cylinder(d=SHAFT_COUPLER_DIA + 6, h=TURNTABLE_THICK + 10);
        }

        // Shaft hole (D-shaped for NEMA 17)
        translate([0, 0, -1]) {
            // Round hole
            cylinder(d=SHAFT_HOLE_DIA, h=TURNTABLE_THICK + 12);

            // D-flat (3mm deep flat on 5mm shaft)
            translate([SHAFT_HOLE_DIA/2 - 0.5, -SHAFT_HOLE_DIA/2, 0])
                cube([2, SHAFT_HOLE_DIA, TURNTABLE_THICK + 12]);
        }

        // Grub screw hole to lock onto shaft
        translate([SHAFT_COUPLER_DIA/2 + 2, 0, TURNTABLE_THICK + 5])
            rotate([0, -90, 0])
                cylinder(d=M3_DIA, h=10);

        // Rubber band groove for grip
        translate([0, 0, TURNTABLE_THICK - RUBBER_RING_DEPTH])
            difference() {
                cylinder(d=RUBBER_RING_DIA + RUBBER_RING_WIDTH, h=RUBBER_RING_DEPTH + 1);
                cylinder(d=RUBBER_RING_DIA - RUBBER_RING_WIDTH, h=RUBBER_RING_DEPTH + 1);
            }
    }
}

// --- Bottle Centering Guide ---
// Sits above the turntable, does NOT rotate (mounted to base)
module centering_guide() {
    difference() {
        union() {
            // Four corner posts
            for (x = [0, GUIDE_INNER + GUIDE_WALL])
                for (y = [0, GUIDE_INNER + GUIDE_WALL]) {
                    translate([x, y, 0])
                        cube([GUIDE_WALL, GUIDE_WALL, GUIDE_HEIGHT]);
                }

            // Bottom ring connecting posts (sits just above turntable)
            translate([0, 0, 0])
                difference() {
                    cube([GUIDE_INNER + GUIDE_WALL*2,
                          GUIDE_INNER + GUIDE_WALL*2, 8]);
                    translate([GUIDE_WALL, GUIDE_WALL, -1])
                        cube([GUIDE_INNER, GUIDE_INNER, 10]);
                }

            // Top flare for bottle entry
            translate([0, 0, GUIDE_HEIGHT - 10])
                difference() {
                    cube([GUIDE_INNER + GUIDE_WALL*2 + 10,
                          GUIDE_INNER + GUIDE_WALL*2 + 10, 10]);
                    translate([5 + GUIDE_WALL, 5 + GUIDE_WALL, -1])
                        cube([GUIDE_INNER, GUIDE_INNER, 12]);
                }
        }

        // Turntable clearance (cutout for spinning disk)
        translate([GUIDE_WALL + GUIDE_INNER/2,
                   GUIDE_WALL + GUIDE_INNER/2, -1])
            cylinder(d=TURNTABLE_DIA + 4, h=TURNTABLE_THICK + 3);

        // Entry opening (front - bottles enter from chute)
        translate([GUIDE_WALL, -1, 8])
            cube([GUIDE_INNER, GUIDE_WALL + 2, GUIDE_HEIGHT - 8]);

        // Exit opening (back - bottles leave to next station)
        translate([GUIDE_WALL, GUIDE_INNER + GUIDE_WALL - 1, 8])
            cube([GUIDE_INNER, GUIDE_WALL + 2, GUIDE_HEIGHT - 8]);

        // Scanner window (side opening for barcode reader)
        translate([-1, GUIDE_WALL + 10, 15])
            cube([GUIDE_WALL + 2, GUIDE_INNER - 20, 40]);

        // Mounting holes to base
        for (x = [GUIDE_WALL/2, GUIDE_INNER + GUIDE_WALL*1.5])
            for (y = [GUIDE_WALL/2, GUIDE_INNER + GUIDE_WALL*1.5])
                translate([x, y, -1])
                    cylinder(d=M3_DIA, h=10);
    }
}

// --- Barcode Scanner Mount Arm ---
module scanner_arm() {
    difference() {
        union() {
            // Arm extending from base
            cube([SCANNER_ARM_WIDTH, SCANNER_ARM_LEN, SCANNER_ARM_THICK]);

            // Scanner cradle at end
            translate([0, SCANNER_ARM_LEN - GM65_LENGTH - 4, SCANNER_ARM_THICK])
                difference() {
                    cube([SCANNER_ARM_WIDTH, GM65_LENGTH + 8, GM65_HEIGHT + 4]);
                    // Scanner pocket
                    translate([(SCANNER_ARM_WIDTH - GM65_WIDTH)/2, 4, 2])
                        cube([GM65_WIDTH + 0.5, GM65_LENGTH + 0.5, GM65_HEIGHT + 3]);
                }

            // Reinforcement rib
            translate([SCANNER_ARM_WIDTH/2 - 1, 0, 0])
                cube([2, SCANNER_ARM_LEN * 0.6, SCANNER_ARM_THICK + 5]);
        }

        // Base mounting holes
        translate([SCANNER_ARM_WIDTH/2, 8, -1])
            cylinder(d=M3_DIA, h=SCANNER_ARM_THICK + 2);
        translate([SCANNER_ARM_WIDTH/2, 22, -1])
            cylinder(d=M3_DIA, h=SCANNER_ARM_THICK + 2);

        // Wire channel
        translate([SCANNER_ARM_WIDTH/2, 30, -1])
            cylinder(d=6, h=SCANNER_ARM_THICK + 2);
    }
}

// --- Label Applicator Arm (blank label over barcode) ---
// Mounts opposite the scanner, presses label after barcode is positioned
module label_press_arm() {
    arm_len = 50;
    arm_width = 20;
    pad_dia = 30;  // Silicone pad size for pressing label

    difference() {
        union() {
            // Pivot base
            cube([arm_width, 15, 20]);

            // Arm
            translate([0, 0, 15])
                cube([arm_width, arm_len, 5]);

            // Press pad mount
            translate([arm_width/2, arm_len - 5, 15])
                cylinder(d=pad_dia, h=8);
        }

        // Pivot hole (for servo rod or spring)
        translate([-1, 7.5, 10])
            rotate([0, 90, 0])
                cylinder(d=M3_DIA, h=arm_width + 2);

        // Pad center hole (for label feed-through)
        translate([arm_width/2, arm_len - 5, 14])
            cylinder(d=15, h=10);

        // Servo connection hole
        translate([arm_width/2, 3, -1])
            cylinder(d=M3_DIA, h=22);
    }
}

// --- Full Station Assembly View ---
module turntable_assembly() {
    // Base
    color("SteelBlue") turntable_base();

    // Turntable disk (shown in position)
    color("Orange")
        translate([BASE_WIDTH/2, BASE_DEPTH/2 - 10, BASE_HEIGHT + 1])
            turntable_disk();

    // Centering guide
    color("LightGreen")
        translate([BASE_WIDTH/2 - GUIDE_INNER/2 - GUIDE_WALL,
                   BASE_DEPTH/2 - 10 - GUIDE_INNER/2 - GUIDE_WALL,
                   BASE_HEIGHT + TURNTABLE_THICK + 2])
            centering_guide();

    // Scanner arm (left side)
    color("Red")
        translate([-SCANNER_ARM_WIDTH - 5,
                   BASE_DEPTH/2 - 10 - SCANNER_ARM_LEN/2,
                   BASE_HEIGHT])
            scanner_arm();

    // Label press arm (right side)
    color("Yellow")
        translate([BASE_WIDTH + 5,
                   BASE_DEPTH/2 - 10 - 20,
                   BASE_HEIGHT])
            label_press_arm();
}

// --- Render ---
// Full assembly preview:
turntable_assembly();

// Individual parts for printing (uncomment one at a time):
// turntable_base();
// translate([0, 0, 0]) turntable_disk();
// centering_guide();
// scanner_arm();
// label_press_arm();
