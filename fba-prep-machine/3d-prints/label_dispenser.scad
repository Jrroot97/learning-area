// ============================================================
// FBA Prep Machine - Label Dispenser (Peel-Bar Mechanism)
// Dispenses labels from a roll using peel-bar technique
// Used for: FNSKU, suffocation warning, sold-as-set, blank barcode cover
// Print: 0.2mm layers, 4 walls, 40% infill, PETG (strength needed)
// ============================================================

use <common.scad>
include <common.scad>

// --- Label Roll Parameters ---
LABEL_WIDTH      = 58;     // Standard 2.25" shipping label width
LABEL_ROLL_DIA   = 100;    // Max roll outer diameter
LABEL_CORE_DIA   = 25;     // Cardboard core inner diameter
LABEL_CORE_OD    = 38;     // Core outer diameter

// For blank barcode cover labels (smaller)
COVER_LABEL_WIDTH = 38;    // 1.5" wide cover label
COVER_LABEL_HEIGHT = 25;   // 1" tall cover label

// --- Peel Bar ---
PEEL_BAR_ANGLE   = 165;    // Acute angle forces label to separate from backing
PEEL_BAR_RADIUS  = 1.0;    // Sharp radius at peel point (smaller = better peel)
PEEL_BAR_WIDTH   = LABEL_WIDTH + 10;  // Wider than label

// --- Dispenser Frame ---
FRAME_WIDTH      = LABEL_WIDTH + 30;
FRAME_DEPTH      = 80;
FRAME_HEIGHT     = LABEL_ROLL_DIA + 30;
FRAME_WALL       = 4;

// Roll spindle
SPINDLE_DIA      = LABEL_CORE_DIA - 1;  // Slight press-fit
SPINDLE_LENGTH   = LABEL_WIDTH + 5;

// Take-up (for backing paper)
TAKEUP_DIA       = 25;
TAKEUP_LENGTH    = LABEL_WIDTH + 5;

// --- Peel Bar Module ---
module peel_bar() {
    // The key component - sharp edge where label separates from backing
    difference() {
        union() {
            // Main bar body
            cube([PEEL_BAR_WIDTH, 12, 8]);

            // Peel edge (sharp radius)
            translate([0, 0, 8])
                rotate([0, 90, 0])
                    // Triangular edge
                    linear_extrude(height=PEEL_BAR_WIDTH)
                        polygon([
                            [0, 0],
                            [-3, 0],
                            [-1, 8],
                            [0, 12]
                        ]);
        }

        // Mounting holes
        translate([10, 6, -1])
            cylinder(d=M3_DIA, h=10);
        translate([PEEL_BAR_WIDTH - 10, 6, -1])
            cylinder(d=M3_DIA, h=10);
    }
}

// --- Roll Holder Spindle ---
module roll_spindle() {
    difference() {
        union() {
            // Spindle shaft
            cylinder(d=SPINDLE_DIA, h=SPINDLE_LENGTH);

            // Flange (keeps roll from sliding)
            cylinder(d=SPINDLE_DIA + 15, h=3);

            // End cap flange
            translate([0, 0, SPINDLE_LENGTH - 3])
                cylinder(d=SPINDLE_DIA + 8, h=3);
        }

        // Center hole for mounting bolt
        translate([0, 0, -1])
            cylinder(d=M4_DIA, h=SPINDLE_LENGTH + 2);

        // Friction slots (allow slight compression for grip)
        for (a = [0, 90, 180, 270])
            rotate([0, 0, a])
                translate([-0.5, 0, 5])
                    cube([1, SPINDLE_DIA/2 + 1, SPINDLE_LENGTH - 10]);
    }
}

// --- Backing Paper Take-Up Spool ---
module takeup_spool() {
    difference() {
        union() {
            // Spool
            cylinder(d=TAKEUP_DIA, h=TAKEUP_LENGTH);

            // Flanges
            cylinder(d=TAKEUP_DIA + 15, h=2);
            translate([0, 0, TAKEUP_LENGTH - 2])
                cylinder(d=TAKEUP_DIA + 15, h=2);
        }

        // Shaft hole (motor driven)
        translate([0, 0, -1])
            cylinder(d=NEMA17_SHAFT_DIA + 0.3, h=TAKEUP_LENGTH + 2);

        // D-flat for shaft grip
        translate([NEMA17_SHAFT_DIA/2 - 0.3, -NEMA17_SHAFT_DIA, -1])
            cube([2, NEMA17_SHAFT_DIA * 2, TAKEUP_LENGTH + 2]);

        // Grub screw
        translate([TAKEUP_DIA/2 + 2, 0, TAKEUP_LENGTH/2])
            rotate([0, -90, 0])
                cylinder(d=M3_DIA, h=15);

        // Label catch slot (tape backing paper start here)
        translate([-1, -TAKEUP_DIA/2, TAKEUP_LENGTH/2 - 5])
            cube([2, TAKEUP_DIA, 10]);
    }
}

// --- Side Plate (left and right frame) ---
module side_plate() {
    difference() {
        // Main plate
        rounded_rect(FRAME_DEPTH, FRAME_HEIGHT, FRAME_WALL, r=5);

        // Label roll axle hole (upper)
        translate([FRAME_DEPTH/2, FRAME_HEIGHT - LABEL_ROLL_DIA/2 - 10, -1])
            cylinder(d=M4_DIA, h=FRAME_WALL + 2);

        // Take-up motor hole (lower)
        translate([FRAME_DEPTH - 25, 20, -1]) {
            // Motor shaft
            cylinder(d=NEMA17_BOSS_DIA, h=FRAME_WALL + 2);
            // Motor mounting holes
            for (x = [-1, 1])
                for (y = [-1, 1])
                    translate([x * NEMA17_HOLE_SPACING/2,
                              y * NEMA17_HOLE_SPACING/2, 0])
                        cylinder(d=M3_DIA, h=FRAME_WALL + 2);
        }

        // Peel bar mounting holes
        translate([15, FRAME_HEIGHT/2, -1])
            cylinder(d=M3_DIA, h=FRAME_WALL + 2);
        translate([15, FRAME_HEIGHT/2 + 15, -1])
            cylinder(d=M3_DIA, h=FRAME_WALL + 2);

        // Tension guide slot (vertical)
        translate([35, FRAME_HEIGHT/2 - 10, -1])
            hull() {
                cylinder(d=M3_DIA, h=FRAME_WALL + 2);
                translate([0, 20, 0])
                    cylinder(d=M3_DIA, h=FRAME_WALL + 2);
            }

        // Base mounting holes
        translate([15, 5, -1])
            cylinder(d=M4_DIA, h=FRAME_WALL + 2);
        translate([FRAME_DEPTH - 15, 5, -1])
            cylinder(d=M4_DIA, h=FRAME_WALL + 2);
    }
}

// --- Tension Roller Guide ---
module tension_guide() {
    roller_dia = 15;

    difference() {
        union() {
            // Arm
            cube([30, 15, FRAME_WALL]);

            // Roller mount
            translate([25, 7.5, FRAME_WALL])
                cylinder(d=roller_dia + 6, h=5);
        }

        // Adjustment slot
        translate([5, 7.5, -1])
            hull() {
                cylinder(d=M3_DIA, h=FRAME_WALL + 2);
                translate([10, 0, 0])
                    cylinder(d=M3_DIA, h=FRAME_WALL + 2);
            }

        // Roller bearing hole
        translate([25, 7.5, FRAME_WALL - 1])
            cylinder(d=M3_DIA, h=8);
    }
}

// --- Label Guide Fingers ---
// Keep label straight as it comes off the peel bar
module label_guide() {
    difference() {
        union() {
            cube([LABEL_WIDTH + 4, 20, 3]);

            // Side guides
            translate([0, 0, 0])
                cube([2, 20, 8]);
            translate([LABEL_WIDTH + 2, 0, 0])
                cube([2, 20, 8]);
        }

        // Label path slot
        translate([2, -1, 3])
            cube([LABEL_WIDTH, 22, 2]);

        // Mounting holes
        translate([LABEL_WIDTH/2, 10, -1])
            cylinder(d=M3_DIA, h=5);
    }
}

// --- Full Assembly View ---
module dispenser_assembly() {
    // Left side plate
    color("SteelBlue")
        side_plate();

    // Right side plate
    color("SteelBlue")
        translate([0, 0, FRAME_WIDTH - FRAME_WALL])
            side_plate();

    // Roll spindle
    color("Orange")
        translate([FRAME_DEPTH/2,
                   FRAME_HEIGHT - LABEL_ROLL_DIA/2 - 10,
                   FRAME_WALL + 2])
            rotate([0, 0, 0])
                roll_spindle();

    // Label roll (preview)
    color("White", 0.3)
        translate([FRAME_DEPTH/2,
                   FRAME_HEIGHT - LABEL_ROLL_DIA/2 - 10,
                   FRAME_WALL + 5])
            cylinder(d=LABEL_ROLL_DIA, h=LABEL_WIDTH);

    // Peel bar
    color("Red")
        translate([10, FRAME_HEIGHT/2, FRAME_WALL + 5])
            peel_bar();

    // Take-up spool
    color("Green")
        translate([FRAME_DEPTH - 25, 20, FRAME_WALL + 5])
            takeup_spool();

    // Tension guide
    color("Yellow")
        translate([30, FRAME_HEIGHT/2 + 20, FRAME_WALL + 2])
            tension_guide();
}

// --- Render ---
// Full assembly preview:
dispenser_assembly();

// Individual parts for printing (uncomment one at a time):
// peel_bar();
// roll_spindle();
// takeup_spool();
// side_plate();
// tension_guide();
// label_guide();
