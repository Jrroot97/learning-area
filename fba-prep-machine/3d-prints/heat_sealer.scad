// ============================================================
// FBA Prep Machine - Heat Sealer Clamp Assembly
// Servo-actuated clamp with nichrome wire for poly bag sealing
// Print: 0.2mm layers, 4 walls, 50% infill, PETG (heat resistant)
// ============================================================

use <common.scad>
include <common.scad>

// --- Sealer Parameters ---
SEAL_WIDTH       = 200;    // Wide enough for poly tube (bottle + margin)
JAW_DEPTH        = 30;     // Jaw depth
JAW_THICK        = 10;     // Jaw thickness
WIRE_CHANNEL_W   = 2;      // Nichrome wire channel width
WIRE_CHANNEL_D   = 1.5;    // Nichrome wire channel depth

// PTFE tape channel (goes over nichrome, prevents sticking)
PTFE_CHANNEL_W   = 8;
PTFE_CHANNEL_D   = 0.5;

// Hinge
HINGE_DIA        = 8;
HINGE_PIN_DIA    = 4.2;    // M4 bolt as hinge pin
HINGE_WIDTH      = 15;
HINGE_OFFSET     = 10;     // Distance from jaw end to hinge center

// Servo lever
LEVER_LENGTH     = 60;     // Leverage arm for servo
LEVER_WIDTH      = 15;

// Silicone pad recess (opposing jaw)
PAD_WIDTH        = PTFE_CHANNEL_W + 4;
PAD_DEPTH        = 3;

// --- Lower Jaw (fixed) ---
module lower_jaw() {
    difference() {
        union() {
            // Main jaw body
            cube([SEAL_WIDTH, JAW_DEPTH, JAW_THICK]);

            // Hinge knuckles (3 knuckles on lower jaw)
            for (i = [0, 1, 2]) {
                translate([SEAL_WIDTH + HINGE_OFFSET,
                           JAW_DEPTH/5 + i * JAW_DEPTH*2/5 - HINGE_WIDTH/2,
                           JAW_THICK/2])
                    rotate([-90, 0, 0])
                        cylinder(d=HINGE_DIA, h=HINGE_WIDTH);
            }

            // Mounting tabs
            translate([-15, 0, 0])
                cube([15, JAW_DEPTH, 5]);
            translate([SEAL_WIDTH, 0, 0])
                cube([15, JAW_DEPTH, 5]);
        }

        // Nichrome wire channel (centered on sealing face)
        translate([-1, JAW_DEPTH/2 - WIRE_CHANNEL_W/2, JAW_THICK - WIRE_CHANNEL_D])
            cube([SEAL_WIDTH + 2, WIRE_CHANNEL_W, WIRE_CHANNEL_D + 1]);

        // PTFE tape channel (wider, shallower, over the wire)
        translate([-1, JAW_DEPTH/2 - PTFE_CHANNEL_W/2, JAW_THICK - PTFE_CHANNEL_D])
            cube([SEAL_WIDTH + 2, PTFE_CHANNEL_W, PTFE_CHANNEL_D + 1]);

        // Wire exit holes (each end)
        translate([-1, JAW_DEPTH/2, JAW_THICK - WIRE_CHANNEL_D - 2])
            rotate([0, 90, 0])
                cylinder(d=3, h=5);
        translate([SEAL_WIDTH - 3, JAW_DEPTH/2, JAW_THICK - WIRE_CHANNEL_D - 2])
            rotate([0, 90, 0])
                cylinder(d=3, h=5);

        // Hinge pin holes
        for (i = [0, 1, 2]) {
            translate([SEAL_WIDTH + HINGE_OFFSET,
                       JAW_DEPTH/5 + i * JAW_DEPTH*2/5 - HINGE_WIDTH/2 - 1,
                       JAW_THICK/2])
                rotate([-90, 0, 0])
                    cylinder(d=HINGE_PIN_DIA, h=HINGE_WIDTH + 2);
        }

        // Mounting holes
        translate([-7.5, JAW_DEPTH/2, -1])
            cylinder(d=M4_DIA, h=7);
        translate([SEAL_WIDTH + 7.5, JAW_DEPTH/2, -1])
            cylinder(d=M4_DIA, h=7);
    }
}

// --- Upper Jaw (hinged, servo-actuated) ---
module upper_jaw() {
    difference() {
        union() {
            // Main jaw body
            cube([SEAL_WIDTH, JAW_DEPTH, JAW_THICK]);

            // Hinge knuckles (2 knuckles on upper jaw, interleave with lower)
            for (i = [0, 1]) {
                translate([SEAL_WIDTH + HINGE_OFFSET,
                           JAW_DEPTH/5 + (i*2+1) * JAW_DEPTH*2/5 - HINGE_WIDTH/2 + JAW_DEPTH/10,
                           JAW_THICK/2])
                    rotate([-90, 0, 0])
                        cylinder(d=HINGE_DIA, h=HINGE_WIDTH);
            }

            // Servo lever arm
            translate([SEAL_WIDTH * 0.7, -LEVER_LENGTH, 0])
                cube([LEVER_WIDTH, LEVER_LENGTH, JAW_THICK/2]);
        }

        // Silicone pad recess (faces the nichrome wire on lower jaw)
        translate([-1, JAW_DEPTH/2 - PAD_WIDTH/2, -PAD_DEPTH])
            cube([SEAL_WIDTH + 2, PAD_WIDTH, PAD_DEPTH + 1]);

        // Hinge pin holes
        for (i = [0, 1]) {
            translate([SEAL_WIDTH + HINGE_OFFSET,
                       JAW_DEPTH/5 + (i*2+1) * JAW_DEPTH*2/5 - HINGE_WIDTH/2 + JAW_DEPTH/10 - 1,
                       JAW_THICK/2])
                rotate([-90, 0, 0])
                    cylinder(d=HINGE_PIN_DIA, h=HINGE_WIDTH + 2);
        }

        // Servo horn connection hole (at end of lever)
        translate([SEAL_WIDTH * 0.7 + LEVER_WIDTH/2, -LEVER_LENGTH + 10, -1])
            cylinder(d=M3_DIA, h=JAW_THICK);

        // Spring holes (return spring to open jaw)
        translate([20, JAW_DEPTH/2, -1])
            cylinder(d=3, h=JAW_THICK + 2);
        translate([SEAL_WIDTH - 20, JAW_DEPTH/2, -1])
            cylinder(d=3, h=JAW_THICK + 2);
    }
}

// --- Poly Tube Guide (feeds tube under sealer) ---
module tube_guide() {
    guide_width = SEAL_WIDTH + 20;
    guide_depth = 40;
    slot_height = 8;  // Tube passes through this slot

    difference() {
        cube([guide_width, guide_depth, slot_height + 6]);

        // Tube slot
        translate([-1, 5, 3])
            cube([guide_width + 2, guide_depth - 10, slot_height]);

        // Cut relief for sealed tube to exit
        translate([guide_width/2 - 50, -1, 3])
            cube([100, 7, slot_height]);

        // Mounting holes
        translate([10, guide_depth/2, -1])
            cylinder(d=M3_DIA, h=20);
        translate([guide_width - 10, guide_depth/2, -1])
            cylinder(d=M3_DIA, h=20);
    }
}

// --- Cutter Bar (separates sealed bags) ---
module cutter_bar() {
    bar_width = SEAL_WIDTH + 20;

    difference() {
        union() {
            // Bar body
            cube([bar_width, 10, 8]);

            // Blade holder ridge
            translate([5, 2, 8])
                cube([bar_width - 10, 6, 3]);
        }

        // Blade slot (for replaceable utility blade)
        translate([10, 4, 7])
            cube([bar_width - 20, 2, 5]);

        // Blade retention screw holes
        for (x = [30, bar_width/2, bar_width - 30])
            translate([x, 5, -1])
                cylinder(d=M3_DIA, h=15);
    }
}

// --- Servo Mount Bracket (for sealer actuation) ---
module sealer_servo_mount() {
    bracket_w = SERVO_TAB_WIDTH + 10;
    bracket_d = 30;
    bracket_h = SERVO_HEIGHT + 10;

    difference() {
        union() {
            // Base
            cube([bracket_w, bracket_d, 5]);

            // Upright
            cube([bracket_w, 5, bracket_h]);
        }

        // Servo pocket
        translate([(bracket_w - SERVO_LENGTH)/2, -1, bracket_h - SERVO_HEIGHT - 3])
            cube([SERVO_LENGTH, 7, SERVO_HEIGHT]);

        // Servo tab screw holes
        translate([(bracket_w - SERVO_TAB_WIDTH)/2, 2.5, bracket_h - SERVO_HEIGHT - 5])
            cylinder(d=M3_DIA, h=10);
        translate([(bracket_w + SERVO_TAB_WIDTH)/2, 2.5, bracket_h - SERVO_HEIGHT - 5])
            cylinder(d=M3_DIA, h=10);

        // Base mounting holes
        translate([10, bracket_d/2, -1])
            cylinder(d=M4_DIA, h=7);
        translate([bracket_w - 10, bracket_d/2, -1])
            cylinder(d=M4_DIA, h=7);
    }
}

// --- Full Assembly View ---
module sealer_assembly() {
    // Lower jaw
    color("SteelBlue")
        lower_jaw();

    // Upper jaw (shown open at 30 degrees)
    color("Orange")
        translate([SEAL_WIDTH + HINGE_OFFSET, 0, JAW_THICK/2])
            rotate([0, -30, 0])
                translate([-(SEAL_WIDTH + HINGE_OFFSET), 0, JAW_THICK/2 + 2])
                    upper_jaw();

    // Tube guide (below jaws)
    color("LightGreen")
        translate([-10, -5, -15])
            tube_guide();

    // Cutter bar (after sealer)
    color("Red")
        translate([-10, JAW_DEPTH + 5, 0])
            cutter_bar();

    // Servo mount
    color("Yellow")
        translate([SEAL_WIDTH * 0.7 - 5, -50, -10])
            sealer_servo_mount();
}

// --- Render ---
sealer_assembly();

// Individual parts (uncomment one):
// lower_jaw();
// upper_jaw();
// tube_guide();
// cutter_bar();
// sealer_servo_mount();
