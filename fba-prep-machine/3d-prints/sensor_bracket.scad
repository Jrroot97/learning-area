// ============================================================
// FBA Prep Machine - Sensor Brackets
// IR break-beam sensor mount (bottle counter)
// Clips onto bottle chute walls
// Print: 0.2mm layers, 3 walls, 30% infill, PLA
// ============================================================

use <common.scad>
include <common.scad>

// --- IR Sensor Parameters ---
IR_SENSOR_DIA  = IR_LED_DIA;   // 5.2mm
IR_DEPTH       = 8;            // How deep the LED/photodiode sit
BRACKET_WALL   = 3;
BRACKET_HEIGHT = 25;

// Clip dimensions (clips onto chute wall)
CLIP_WIDTH     = 15;
CLIP_GAP       = CHUTE_WALL + 0.4;  // Chute wall + tolerance
CLIP_DEPTH     = 12;
CLIP_LIP       = 2;

// --- IR Emitter Bracket (one side of chute) ---
module ir_emitter_bracket() {
    difference() {
        union() {
            // Main body
            cube([CLIP_WIDTH, CLIP_DEPTH + 10, BRACKET_HEIGHT]);

            // Chute wall clip
            translate([0, CLIP_DEPTH + 10, 0])
                chute_clip();
        }

        // LED hole
        translate([CLIP_WIDTH/2, -1, BRACKET_HEIGHT/2])
            rotate([-90, 0, 0])
                cylinder(d=IR_SENSOR_DIA, h=IR_DEPTH + 1);

        // Wire channel (back)
        translate([CLIP_WIDTH/2, CLIP_DEPTH + 5, BRACKET_HEIGHT/2])
            rotate([-90, 0, 0])
                cylinder(d=3, h=15);

        // Wire exit hole (top)
        translate([CLIP_WIDTH/2 - 1.5, CLIP_DEPTH, BRACKET_HEIGHT - 5])
            cube([3, 10, 6]);
    }
}

// --- IR Receiver Bracket (other side of chute) ---
module ir_receiver_bracket() {
    difference() {
        union() {
            // Main body
            cube([CLIP_WIDTH, CLIP_DEPTH + 10, BRACKET_HEIGHT]);

            // Chute wall clip
            translate([0, CLIP_DEPTH + 10, 0])
                chute_clip();
        }

        // Photodiode hole
        translate([CLIP_WIDTH/2, -1, BRACKET_HEIGHT/2])
            rotate([-90, 0, 0])
                cylinder(d=IR_SENSOR_DIA, h=IR_DEPTH + 1);

        // Ambient light shield (tube around sensor)
        translate([CLIP_WIDTH/2, 0, BRACKET_HEIGHT/2])
            rotate([-90, 0, 0])
                difference() {
                    cylinder(d=IR_SENSOR_DIA + 4, h=IR_DEPTH + 3);
                    cylinder(d=IR_SENSOR_DIA + 0.5, h=IR_DEPTH + 4);
                }

        // Wire channel
        translate([CLIP_WIDTH/2, CLIP_DEPTH + 5, BRACKET_HEIGHT/2])
            rotate([-90, 0, 0])
                cylinder(d=3, h=15);

        // Wire exit hole (top)
        translate([CLIP_WIDTH/2 - 1.5, CLIP_DEPTH, BRACKET_HEIGHT - 5])
            cube([3, 10, 6]);
    }
}

// --- Chute Wall Clip ---
module chute_clip() {
    // C-shaped clip that snaps over chute wall
    difference() {
        cube([CLIP_WIDTH, CLIP_GAP + BRACKET_WALL * 2, BRACKET_HEIGHT]);

        // Channel for chute wall
        translate([-1, BRACKET_WALL, -1])
            cube([CLIP_WIDTH + 2, CLIP_GAP, BRACKET_HEIGHT + 2]);

        // Entry relief (slight taper for snap-on)
        translate([-1, BRACKET_WALL - 0.5, -1])
            cube([CLIP_WIDTH + 2, 1, BRACKET_HEIGHT + 2]);
    }

    // Retention lips (snap over wall top)
    translate([2, BRACKET_WALL - CLIP_LIP, BRACKET_HEIGHT - 2])
        cube([CLIP_WIDTH - 4, CLIP_LIP + 0.5, 2]);
    translate([2, BRACKET_WALL + CLIP_GAP, BRACKET_HEIGHT - 2])
        cube([CLIP_WIDTH - 4, CLIP_LIP + 0.5, 2]);
}

// --- Adjustable Height Bracket ---
// For fine-tuning sensor alignment
module adjustable_bracket() {
    slot_length = 15;

    difference() {
        union() {
            // Base with vertical slot
            cube([CLIP_WIDTH, 8, BRACKET_HEIGHT + slot_length]);

            // Sensor holder (slides in slot)
            translate([0, 0, BRACKET_HEIGHT])
                cube([CLIP_WIDTH, CLIP_DEPTH + 10, 15]);
        }

        // Vertical adjustment slot
        translate([CLIP_WIDTH/2, -1, BRACKET_HEIGHT - 5])
            hull() {
                rotate([-90, 0, 0])
                    cylinder(d=M3_DIA, h=10);
                translate([0, 0, slot_length])
                    rotate([-90, 0, 0])
                        cylinder(d=M3_DIA, h=10);
            }

        // LED/photodiode hole
        translate([CLIP_WIDTH/2, -1, BRACKET_HEIGHT + 7.5])
            rotate([-90, 0, 0])
                cylinder(d=IR_SENSOR_DIA, h=CLIP_DEPTH + 12);
    }
}

// --- Dual Sensor Bracket (entry + exit count) ---
module dual_sensor_bracket() {
    spacing = 30;  // Distance between two sensors

    // Entry sensor
    ir_emitter_bracket();

    // Exit sensor (offset along chute)
    translate([0, 0, spacing])
        ir_emitter_bracket();

    // Connecting bar
    translate([0, CLIP_DEPTH + 8, 0])
        cube([CLIP_WIDTH, 3, BRACKET_HEIGHT + spacing]);
}

// --- Assembly View ---
module sensor_assembly() {
    // Show a pair facing each other across the chute
    chute_gap = CHUTE_DEPTH + CHUTE_WALL * 2;

    // Emitter side
    color("Red")
        ir_emitter_bracket();

    // Receiver side (mirrored across chute)
    color("DarkRed")
        translate([0, chute_gap + CLIP_DEPTH + 10, 0])
            mirror([0, 1, 0])
                ir_receiver_bracket();

    // Chute wall preview
    color("Gray", 0.2) {
        translate([0, CLIP_DEPTH + 10, 0])
            cube([CLIP_WIDTH, CHUTE_WALL, BRACKET_HEIGHT + 10]);
        translate([0, CLIP_DEPTH + 10 + CHUTE_DEPTH + CHUTE_WALL, 0])
            cube([CLIP_WIDTH, CHUTE_WALL, BRACKET_HEIGHT + 10]);
    }
}

// --- Render ---
sensor_assembly();

// Individual parts (uncomment one):
// ir_emitter_bracket();
// ir_receiver_bracket();
// adjustable_bracket();
// dual_sensor_bracket();
