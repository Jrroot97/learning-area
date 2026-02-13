// ============================================================
// FBA Prep Machine - Modular Bottle Chute Section
// Snap-together track sections for guiding bottles between stations
// Print: 0.2mm layers, 3 walls, 20% infill, PLA or PETG
// ============================================================

use <common.scad>
include <common.scad>

// --- Chute Section Parameters ---
SECTION_LENGTH = 200;       // Length of one chute section
BASE_THICKNESS = 4;         // Floor thickness
RAIL_HEIGHT    = CHUTE_HEIGHT; // Side wall height (50mm)
RAIL_TAPER     = 5;         // Outward taper at top for easy bottle entry

// Slope for gravity feed (adjustable via printed riser blocks)
SLOPE_DROP     = 0;         // Set >0 for gravity-fed slope per section

// --- Main Chute Section ---
module chute_section() {
    difference() {
        union() {
            // Base plate
            cube([SECTION_LENGTH, CHUTE_DEPTH + CHUTE_WALL*2, BASE_THICKNESS]);

            // Left wall
            translate([0, 0, 0])
                chute_wall();

            // Right wall
            translate([0, CHUTE_DEPTH + CHUTE_WALL, 0])
                chute_wall();

            // Male snap tabs on output end (right side)
            translate([SECTION_LENGTH, CHUTE_WALL + 10, BASE_THICKNESS])
                snap_tab();
            translate([SECTION_LENGTH, CHUTE_DEPTH + CHUTE_WALL - 10 - SNAP_WIDTH, BASE_THICKNESS])
                snap_tab();

            // Bottom snap tabs
            translate([SECTION_LENGTH, CHUTE_WALL + CHUTE_DEPTH/2 - SNAP_WIDTH/2, 0])
                rotate([0, 0, 0])
                    translate([0, 0, -SNAP_HEIGHT])
                        snap_tab();
        }

        // Female snap slots on input end (left side)
        translate([-SNAP_DEPTH - SNAP_TOLERANCE, CHUTE_WALL + 10 - SNAP_TOLERANCE, BASE_THICKNESS - SNAP_TOLERANCE])
            snap_slot();
        translate([-SNAP_DEPTH - SNAP_TOLERANCE, CHUTE_DEPTH + CHUTE_WALL - 10 - SNAP_WIDTH - SNAP_TOLERANCE, BASE_THICKNESS - SNAP_TOLERANCE])
            snap_slot();

        // Channel groove in base for smoother sliding
        translate([0, CHUTE_WALL + CHUTE_DEPTH/2 - 15, BASE_THICKNESS - 1])
            cube([SECTION_LENGTH, 30, 1.5]);
    }
}

// Single chute wall with taper
module chute_wall() {
    // Main wall
    cube([SECTION_LENGTH, CHUTE_WALL, BASE_THICKNESS + RAIL_HEIGHT]);

    // Taper flare at top (helps bottles enter)
    translate([0, -RAIL_TAPER, BASE_THICKNESS + RAIL_HEIGHT - 2])
        cube([SECTION_LENGTH, CHUTE_WALL + RAIL_TAPER, 2]);
}

// --- Curved Section (90-degree turn) ---
module chute_curve(radius=150, angle=90) {
    curve_steps = 20;
    step_angle = angle / curve_steps;

    for (i = [0:curve_steps-1]) {
        hull() {
            rotate([0, 0, i * step_angle])
                translate([radius, 0, 0])
                    cube([CHUTE_DEPTH + CHUTE_WALL*2, 2, BASE_THICKNESS + RAIL_HEIGHT]);
            rotate([0, 0, (i+1) * step_angle])
                translate([radius, 0, 0])
                    cube([CHUTE_DEPTH + CHUTE_WALL*2, 2, BASE_THICKNESS + RAIL_HEIGHT]);
        }
    }
}

// --- Riser Block (for gravity slope) ---
module riser_block(height=10) {
    difference() {
        cube([CHUTE_DEPTH + CHUTE_WALL*2 + 10, 30, height]);

        // Screw holes to attach to table
        translate([10, 15, 0])
            m3_hole(height);
        translate([CHUTE_DEPTH + CHUTE_WALL*2, 15, 0])
            m3_hole(height);
    }
}

// --- Station Stop Gate ---
// Blocks bottle at a station, servo-actuated release
module stop_gate() {
    gate_width = CHUTE_DEPTH + CHUTE_WALL * 2;

    difference() {
        union() {
            // Gate frame that sits on top of chute walls
            cube([gate_width, 15, RAIL_HEIGHT + 15]);

            // Servo mount tab
            translate([-SERVO_LENGTH - 5, 0, RAIL_HEIGHT])
                servo_mount();
        }

        // Channel for gate blade to slide
        translate([CHUTE_WALL - 1, 5, 0])
            cube([CHUTE_DEPTH + 2, 3, RAIL_HEIGHT + 5]);

        // Slot for the chute walls
        translate([0, 0, 0])
            cube([CHUTE_WALL + 0.5, 15, RAIL_HEIGHT]);
        translate([CHUTE_WALL + CHUTE_DEPTH - 0.5, 0, 0])
            cube([CHUTE_WALL + 0.5, 15, RAIL_HEIGHT]);
    }
}

// Gate blade (the part that actually blocks the bottle)
module gate_blade() {
    difference() {
        union() {
            // Blade
            cube([CHUTE_DEPTH - 2, 2.5, RAIL_HEIGHT]);

            // Arm extending up to connect to servo horn
            translate([CHUTE_DEPTH/2 - 5, 0, RAIL_HEIGHT])
                cube([10, 2.5, 20]);
        }

        // Servo horn connection hole
        translate([CHUTE_DEPTH/2, -1, RAIL_HEIGHT + 15])
            rotate([-90, 0, 0])
                cylinder(d=2, h=5);
    }
}

// Servo mount bracket
module servo_mount() {
    difference() {
        cube([SERVO_LENGTH + 4, 15, SERVO_HEIGHT + 6]);

        // Servo body cutout
        translate([2, 2, 3])
            cube([SERVO_LENGTH, 13, SERVO_HEIGHT]);

        // Servo tab screw holes
        translate([(SERVO_LENGTH + 4)/2 - SERVO_SCREW_SPACING/2, 7.5, 0])
            m3_hole(3);
        translate([(SERVO_LENGTH + 4)/2 + SERVO_SCREW_SPACING/2, 7.5, 0])
            m3_hole(3);
    }
}

// --- Render ---
// Uncomment the part you want to render/export:

chute_section();

// translate([0, -50, 0]) stop_gate();
// translate([0, -80, 0]) gate_blade();
// translate([0, -110, 0]) riser_block(10);
// translate([0, -130, 0]) riser_block(20);
// translate([0, -150, 0]) riser_block(30);
