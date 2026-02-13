// ============================================================
// FBA Prep Machine - Hopper Transition Funnel
// Feeds bottles from bulk hopper into single-file chute
// NOTE: Full hopper is too large to 3D print - use plywood.
//       This is the TRANSITION piece from hopper to chute.
// Print: 0.2mm layers, 3 walls, 20% infill, PETG
// ============================================================

use <common.scad>
include <common.scad>

// --- Funnel Parameters ---
// Input (hopper side) - wider mouth
INPUT_WIDTH    = CHUTE_DEPTH * 3;    // 3 bottles wide narrows to 1
INPUT_DEPTH    = 100;                // Funnel depth (direction of travel)

// Output (chute side) - matches chute
OUTPUT_WIDTH   = CHUTE_DEPTH + CHUTE_WALL * 2;
OUTPUT_DEPTH   = 50;

FUNNEL_HEIGHT  = 80;      // Funnel wall height
FUNNEL_LENGTH  = 250;     // Total length (must fit on bed - print in 2 halves)
BASE_THICK     = 4;
WALL_THICK     = 3;

// Anti-jam vibrator mount
VIBRATOR_DIA   = 25;      // Coin vibration motor housing
VIBRATOR_DEPTH = 8;

// Print in 2 halves (left and right) to fit on 220mm bed
HALF_LENGTH    = FUNNEL_LENGTH / 2;

// --- Funnel Half (Left) ---
module funnel_half_left() {
    difference() {
        union() {
            // Base plate (tapered from wide to narrow)
            hull() {
                // Wide end
                cube([INPUT_WIDTH/2, 1, BASE_THICK]);
                // Narrow end
                translate([(INPUT_WIDTH/2 - OUTPUT_WIDTH/2), FUNNEL_LENGTH, 0])
                    cube([OUTPUT_WIDTH/2, 1, BASE_THICK]);
            }

            // Left wall (outer, tapered)
            hull() {
                cube([WALL_THICK, 1, FUNNEL_HEIGHT]);
                translate([(INPUT_WIDTH/2 - OUTPUT_WIDTH/2), FUNNEL_LENGTH, 0])
                    cube([WALL_THICK, 1, FUNNEL_HEIGHT]);
            }

            // Center divider wall (half - joins with right half)
            translate([INPUT_WIDTH/2 - WALL_THICK/2, 0, 0])
                hull() {
                    cube([WALL_THICK/2, 1, FUNNEL_HEIGHT]);
                    translate([0, FUNNEL_LENGTH, 0])
                        cube([WALL_THICK/2, 1, FUNNEL_HEIGHT]);
                }

            // Snap join tabs (to connect halves)
            for (y = [FUNNEL_LENGTH * 0.25, FUNNEL_LENGTH * 0.5, FUNNEL_LENGTH * 0.75]) {
                x_at_y = INPUT_WIDTH/2 - (INPUT_WIDTH/2 - OUTPUT_WIDTH/2) * (y / FUNNEL_LENGTH);
                translate([x_at_y - WALL_THICK/2, y - 4, BASE_THICK])
                    cube([SNAP_DEPTH, SNAP_WIDTH, SNAP_HEIGHT]);
            }

            // Entry flare (wide end guide)
            translate([0, 0, FUNNEL_HEIGHT - 10])
                hull() {
                    cube([WALL_THICK, 1, 10]);
                    translate([-15, -20, 0])
                        cube([WALL_THICK, 1, 10]);
                }
        }

        // Floor slope (slight downhill toward output)
        translate([-1, -1, BASE_THICK])
            rotate([atan2(3, FUNNEL_LENGTH), 0, 0])
                cube([INPUT_WIDTH, FUNNEL_LENGTH + 20, 3]);

        // Vibrator motor recess (underneath base)
        translate([INPUT_WIDTH/4, FUNNEL_LENGTH * 0.3, -1])
            cylinder(d=VIBRATOR_DIA, h=VIBRATOR_DEPTH);

        // Mounting holes (base to table)
        for (y = [30, FUNNEL_LENGTH - 30])
            translate([INPUT_WIDTH/4, y, -1])
                cylinder(d=M4_DIA, h=BASE_THICK + 2);
    }
}

// --- Funnel Half (Right) - Mirror of left ---
module funnel_half_right() {
    mirror([1, 0, 0])
        funnel_half_left();
}

// --- Anti-Jam Ramp Insert ---
// Sits at the narrowing point to prevent bottle jams
module anti_jam_ramp() {
    ramp_w = OUTPUT_WIDTH - 4;
    ramp_l = 60;
    ramp_h = 15;

    difference() {
        // Wedge shape
        hull() {
            cube([ramp_w, ramp_l, 2]);
            translate([ramp_w * 0.2, ramp_l - 10, 0])
                cube([ramp_w * 0.6, 10, ramp_h]);
        }

        // Through holes for mounting
        translate([ramp_w/4, ramp_l/2, -1])
            cylinder(d=M3_DIA, h=ramp_h + 2);
        translate([ramp_w*3/4, ramp_l/2, -1])
            cylinder(d=M3_DIA, h=ramp_h + 2);
    }
}

// --- Chute Transition Adapter ---
// Connects funnel output to standard chute section
module chute_adapter() {
    adapter_len = 40;

    difference() {
        union() {
            // Main body matching chute dimensions
            cube([OUTPUT_WIDTH, adapter_len, BASE_THICK + CHUTE_HEIGHT]);

            // Male snap tabs (output end, connects to chute)
            translate([OUTPUT_WIDTH, CHUTE_WALL + 10, BASE_THICK])
                rotate([0, 0, 90])
                    snap_tab();
            translate([OUTPUT_WIDTH, OUTPUT_WIDTH - CHUTE_WALL - 10 - SNAP_WIDTH, BASE_THICK])
                rotate([0, 0, 90])
                    snap_tab();
        }

        // Inner channel
        translate([CHUTE_WALL, -1, BASE_THICK])
            cube([OUTPUT_WIDTH - CHUTE_WALL * 2, adapter_len + 2, CHUTE_HEIGHT + 1]);

        // Funnel connection screw holes (input end)
        translate([OUTPUT_WIDTH/4, 5, -1])
            cylinder(d=M3_DIA, h=BASE_THICK + 2);
        translate([OUTPUT_WIDTH*3/4, 5, -1])
            cylinder(d=M3_DIA, h=BASE_THICK + 2);
    }
}

// --- Bottle Singulator Gate ---
// Ensures only one bottle at a time enters the chute
module singulator_gate() {
    gate_w = OUTPUT_WIDTH;
    gate_h = BOTTLE_HEIGHT * 0.6;  // Doesn't need full height

    difference() {
        union() {
            // Frame
            cube([gate_w, 15, gate_h + 15]);

            // Servo mount
            translate([-SERVO_LENGTH - 5, 0, gate_h])
                difference() {
                    cube([SERVO_LENGTH + 4, 15, SERVO_HEIGHT + 6]);
                    translate([2, 1, 3])
                        cube([SERVO_LENGTH, 13, SERVO_HEIGHT]);
                }
        }

        // Bottle passage
        translate([CHUTE_WALL, -1, 0])
            cube([gate_w - CHUTE_WALL*2, 17, gate_h]);

        // Gate blade slot
        translate([CHUTE_WALL + 5, 6, 0])
            cube([gate_w - CHUTE_WALL*2 - 10, 3, gate_h + 5]);

        // Mounting holes
        translate([5, 7.5, -1])
            cylinder(d=M3_DIA, h=gate_h + 17);
        translate([gate_w - 5, 7.5, -1])
            cylinder(d=M3_DIA, h=gate_h + 17);
    }
}

// Singulator gate blade
module singulator_blade() {
    blade_w = OUTPUT_WIDTH - CHUTE_WALL*2 - 12;

    difference() {
        union() {
            // Blade
            cube([blade_w, 2.5, BOTTLE_HEIGHT * 0.5]);

            // Servo arm
            translate([blade_w/2 - 5, 0, BOTTLE_HEIGHT * 0.5])
                cube([10, 2.5, 20]);
        }

        // Servo horn hole
        translate([blade_w/2, -1, BOTTLE_HEIGHT * 0.5 + 15])
            rotate([-90, 0, 0])
                cylinder(d=2, h=5);
    }
}

// --- Full Assembly View ---
module hopper_assembly() {
    // Left funnel half
    color("SteelBlue")
        translate([-INPUT_WIDTH/2, 0, 0])
            funnel_half_left();

    // Right funnel half
    color("SteelBlue")
        translate([INPUT_WIDTH/2, 0, 0])
            funnel_half_right();

    // Anti-jam ramp
    color("Orange")
        translate([-(OUTPUT_WIDTH-4)/2, FUNNEL_LENGTH * 0.7, BASE_THICK])
            anti_jam_ramp();

    // Chute adapter
    color("LightGreen")
        translate([-OUTPUT_WIDTH/2, FUNNEL_LENGTH + 5, 0])
            chute_adapter();

    // Singulator gate
    color("Red")
        translate([-OUTPUT_WIDTH/2, FUNNEL_LENGTH + 50, 0])
            singulator_gate();

    // Some bottles for scale (preview)
    color("Brown", 0.3)
        for (x = [-BOTTLE_WIDTH, 0, BOTTLE_WIDTH])
            translate([x - BOTTLE_WIDTH/2, 20, BASE_THICK])
                cube([BOTTLE_WIDTH, BOTTLE_DEPTH, BOTTLE_HEIGHT]);
}

// --- Render ---
hopper_assembly();

// Individual parts (uncomment one):
// funnel_half_left();
// funnel_half_right();
// anti_jam_ramp();
// chute_adapter();
// singulator_gate();
// singulator_blade();
