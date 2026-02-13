// ============================================================
// FBA Prep Machine - Poly Tube Bagger Station
// Feeds continuous poly tubing, wraps bottle, seals top & bottom
// Print: 0.2mm layers, 4 walls, 30% infill, PETG
// ============================================================

use <common.scad>
include <common.scad>

// --- Poly Tube Parameters ---
TUBE_ROLL_DIA    = 150;    // Poly tubing roll max diameter
TUBE_ROLL_CORE   = 50;     // Core inner diameter
TUBE_WIDTH       = 200;    // Flat width of poly tube (fits Texjoy + margin)
TUBE_THICKNESS   = 0.05;   // Poly film thickness (for reference)

// Forming collar (opens tube and guides bottle in)
COLLAR_WIDTH     = BOTTLE_WIDTH + 20;  // Inner width
COLLAR_DEPTH     = BOTTLE_DEPTH + 20;  // Inner depth
COLLAR_HEIGHT    = BOTTLE_HEIGHT + 40; // Taller than bottle for seal margin
COLLAR_WALL      = 2;
COLLAR_FLARE     = 20;     // Flare at top for tube entry

// Feed rollers
ROLLER_DIA       = 25;
ROLLER_LENGTH    = TUBE_WIDTH + 10;
ROLLER_SHAFT     = NEMA17_SHAFT_DIA + 0.3;

// --- Poly Tube Roll Holder ---
module tube_roll_holder() {
    holder_w = TUBE_WIDTH + 30;
    holder_h = TUBE_ROLL_DIA/2 + 20;

    difference() {
        union() {
            // Base
            cube([holder_w, 30, 5]);

            // Left upright
            cube([8, 30, holder_h]);

            // Right upright
            translate([holder_w - 8, 0, 0])
                cube([8, 30, holder_h]);

            // Cross brace
            translate([0, 13, holder_h - 5])
                cube([holder_w, 4, 5]);
        }

        // Spindle holes (for roll axle)
        translate([-1, 15, holder_h - 10])
            rotate([0, 90, 0])
                cylinder(d=M4_DIA, h=holder_w + 2);

        // Tension adjustment slot (vertical)
        for (x = [4, holder_w - 4])
            translate([x, 15, holder_h - 30])
                hull() {
                    cylinder(d=M4_DIA, h=1);
                    translate([0, 0, 15])
                        cylinder(d=M4_DIA, h=1);
                }

        // Base mounting holes
        for (x = [15, holder_w - 15])
            translate([x, 15, -1])
                cylinder(d=M4_DIA, h=7);
    }
}

// --- Forming Collar ---
// Opens the flat poly tube into a rectangular pocket for the bottle
module forming_collar() {
    outer_w = COLLAR_WIDTH + COLLAR_WALL * 2;
    outer_d = COLLAR_DEPTH + COLLAR_WALL * 2;

    difference() {
        union() {
            // Main rectangular tube
            cube([outer_w, outer_d, COLLAR_HEIGHT]);

            // Top flare (guides poly tube in)
            translate([-COLLAR_FLARE/2, -COLLAR_FLARE/2, COLLAR_HEIGHT - 20])
                hull() {
                    translate([COLLAR_FLARE/2, COLLAR_FLARE/2, 0])
                        cube([outer_w, outer_d, 1]);
                    cube([outer_w + COLLAR_FLARE, outer_d + COLLAR_FLARE, 1]);
                    translate([COLLAR_FLARE/4, COLLAR_FLARE/4, 20])
                        cube([outer_w + COLLAR_FLARE/2,
                              outer_d + COLLAR_FLARE/2, 1]);
                }

            // Mounting tabs (attach to frame)
            translate([-15, outer_d/2 - 10, 0])
                cube([15, 20, 8]);
            translate([outer_w, outer_d/2 - 10, 0])
                cube([15, 20, 8]);
        }

        // Inner channel (bottle passes through)
        translate([COLLAR_WALL, COLLAR_WALL, -1])
            cube([COLLAR_WIDTH, COLLAR_DEPTH, COLLAR_HEIGHT + 30]);

        // Rounded inner edges (prevent tube tearing)
        for (pos = [[COLLAR_WALL, COLLAR_WALL],
                    [COLLAR_WALL + COLLAR_WIDTH, COLLAR_WALL],
                    [COLLAR_WALL, COLLAR_WALL + COLLAR_DEPTH],
                    [COLLAR_WALL + COLLAR_WIDTH, COLLAR_WALL + COLLAR_DEPTH]])
            translate([pos[0], pos[1], -1])
                cylinder(r=3, h=COLLAR_HEIGHT + 30);

        // Poly tube entry slot (top, front and back)
        translate([COLLAR_WALL + 5, -1, COLLAR_HEIGHT - 15])
            cube([COLLAR_WIDTH - 10, COLLAR_WALL + 2, 10]);
        translate([COLLAR_WALL + 5, outer_d - COLLAR_WALL - 1, COLLAR_HEIGHT - 15])
            cube([COLLAR_WIDTH - 10, COLLAR_WALL + 2, 10]);

        // Mounting tab holes
        translate([-7.5, outer_d/2, -1])
            cylinder(d=M4_DIA, h=10);
        translate([outer_w + 7.5, outer_d/2, -1])
            cylinder(d=M4_DIA, h=10);
    }
}

// --- Feed Roller ---
// Grips and advances poly tube (stepper driven)
module feed_roller() {
    difference() {
        union() {
            // Main roller body
            cylinder(d=ROLLER_DIA, h=ROLLER_LENGTH);

            // Hub reinforcement
            cylinder(d=ROLLER_DIA/2, h=ROLLER_LENGTH);
        }

        // Shaft hole (D-shape)
        translate([0, 0, -1]) {
            cylinder(d=ROLLER_SHAFT, h=ROLLER_LENGTH + 2);
            // D-flat
            translate([ROLLER_SHAFT/2 - 0.5, -ROLLER_SHAFT, 0])
                cube([2, ROLLER_SHAFT*2, ROLLER_LENGTH + 2]);
        }

        // Grub screw hole
        translate([ROLLER_DIA/2, 0, ROLLER_LENGTH/2])
            rotate([0, -90, 0])
                cylinder(d=M3_DIA, h=ROLLER_DIA/2);

        // Grip texture (grooves around circumference)
        for (z = [5 : 8 : ROLLER_LENGTH - 5])
            translate([0, 0, z])
                difference() {
                    cylinder(d=ROLLER_DIA + 1, h=2);
                    cylinder(d=ROLLER_DIA - 3, h=2);
                }
    }
}

// --- Roller Mount Bracket ---
module roller_mount() {
    mount_w = 40;
    mount_h = 50;
    mount_d = 20;

    difference() {
        union() {
            // Main bracket
            cube([mount_w, mount_d, mount_h]);

            // Bearing housing
            translate([mount_w/2, mount_d + 5, mount_h/2])
                rotate([-90, 0, 0])
                    cylinder(d=20, h=8);
        }

        // Motor shaft hole (through for roller axle)
        translate([mount_w/2, -1, mount_h/2])
            rotate([-90, 0, 0])
                cylinder(d=NEMA17_BOSS_DIA, h=mount_d + 15);

        // NEMA 17 mount holes
        translate([mount_w/2, -1, mount_h/2])
            rotate([-90, 0, 0])
                for (x = [-1, 1])
                    for (y = [-1, 1])
                        translate([x * NEMA17_HOLE_SPACING/2,
                                  y * NEMA17_HOLE_SPACING/2, 0])
                            cylinder(d=M3_DIA, h=mount_d + 2);

        // Base mounting slots (adjustable tension)
        for (x = [8, mount_w - 8])
            translate([x, mount_d/2, -1])
                hull() {
                    cylinder(d=M4_DIA, h=mount_h/3);
                    translate([0, 0, 10])
                        cylinder(d=M4_DIA, h=1);
                }
    }
}

// --- Pusher Plate ---
// Pushes bottle down through the forming collar into poly tube
module pusher_plate() {
    plate_w = COLLAR_WIDTH - 4;  // Fits inside collar
    plate_d = COLLAR_DEPTH - 4;
    plate_thick = 5;

    difference() {
        union() {
            // Plate
            rounded_rect(plate_w, plate_d, plate_thick, r=3);

            // Linear rail mount (on top)
            translate([plate_w/2 - 10, plate_d/2 - 10, plate_thick])
                cube([20, 20, 10]);
        }

        // Lightening holes (reduce weight for faster movement)
        for (x = [plate_w * 0.25, plate_w * 0.75])
            for (y = [plate_d * 0.25, plate_d * 0.75])
                translate([x, y, -1])
                    cylinder(d=15, h=plate_thick + 2);

        // Linear bearing/rod mounting holes
        translate([plate_w/2, plate_d/2, plate_thick - 1])
            cylinder(d=M4_DIA, h=12);
        translate([plate_w/2 - 8, plate_d/2 - 8, plate_thick - 1])
            cylinder(d=M3_DIA, h=12);
        translate([plate_w/2 + 8, plate_d/2 + 8, plate_thick - 1])
            cylinder(d=M3_DIA, h=12);
    }
}

// --- Full Assembly View ---
module bagger_assembly() {
    // Tube roll holder (above)
    color("Gray")
        translate([-TUBE_WIDTH/2 - 15, -40, COLLAR_HEIGHT + 30])
            tube_roll_holder();

    // Poly tube roll (preview)
    color("White", 0.2)
        translate([0, -25, COLLAR_HEIGHT + 50])
            rotate([0, 90, 0])
                cylinder(d=TUBE_ROLL_DIA, h=TUBE_WIDTH, center=true);

    // Feed roller (top, pulls tube off roll)
    color("Orange")
        translate([0, 0, COLLAR_HEIGHT + 20])
            rotate([0, 90, 0])
                translate([0, 0, -ROLLER_LENGTH/2])
                    feed_roller();

    // Forming collar
    collar_w = COLLAR_WIDTH + COLLAR_WALL * 2;
    collar_d = COLLAR_DEPTH + COLLAR_WALL * 2;
    color("SteelBlue")
        translate([-collar_w/2, -collar_d/2, 0])
            forming_collar();

    // Pusher plate (shown at top position)
    color("Red")
        translate([-(COLLAR_WIDTH-4)/2, -(COLLAR_DEPTH-4)/2, COLLAR_HEIGHT - 10])
            pusher_plate();

    // Bottle preview (being bagged)
    color("Brown", 0.3)
        translate([-BOTTLE_WIDTH/2, -BOTTLE_DEPTH/2, 5])
            cube([BOTTLE_WIDTH, BOTTLE_DEPTH, BOTTLE_HEIGHT]);
}

// --- Render ---
bagger_assembly();

// Individual parts (uncomment one):
// tube_roll_holder();
// forming_collar();
// feed_roller();
// roller_mount();
// pusher_plate();
