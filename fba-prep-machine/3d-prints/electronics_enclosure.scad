// ============================================================
// FBA Prep Machine - Electronics Enclosure
// Houses ESP32, A4988 stepper drivers, relay module, power
// Print: 0.2mm layers, 3 walls, 20% infill, PLA or PETG
// ============================================================

use <common.scad>
include <common.scad>

// --- Enclosure Parameters ---
// Internal dimensions
INT_WIDTH   = 120;     // Fits ESP32 + 3 A4988 drivers side by side
INT_DEPTH   = 90;      // Depth for components
INT_HEIGHT  = 45;      // Height with wiring room
WALL        = 3;       // Wall thickness
LID_LIP     = 2;       // Lip height for lid retention

// Component layout
ESP32_X     = 10;
ESP32_Y     = 10;
DRIVER_X    = 10;      // First driver X position
DRIVER_Y    = 50;      // Drivers row Y position
DRIVER_SPACING = 28;   // Space between drivers

// Ventilation
VENT_SLOT_W = 2;
VENT_SLOT_L = 20;
VENT_SPACING = 5;

// --- Main Box ---
module enclosure_box() {
    difference() {
        // Outer shell
        rounded_rect(INT_WIDTH + WALL*2,
                     INT_DEPTH + WALL*2,
                     INT_HEIGHT + WALL, r=3);

        // Inner cavity
        translate([WALL, WALL, WALL])
            rounded_rect(INT_WIDTH, INT_DEPTH, INT_HEIGHT + 1, r=2);

        // Lid lip recess
        translate([WALL - 1, WALL - 1, INT_HEIGHT + WALL - LID_LIP])
            rounded_rect(INT_WIDTH + 2, INT_DEPTH + 2, LID_LIP + 1, r=2);

        // --- Cable Entry Holes ---
        // Left side - stepper motor cables (3x)
        for (i = [0:2])
            translate([-1, WALL + 15 + i * 20, WALL + 10])
                rotate([0, 90, 0])
                    hull() {
                        cylinder(d=8, h=WALL + 2);
                        translate([0, 0, 0])
                            cylinder(d=8, h=WALL + 2);
                    }

        // Right side - servo cables (2x)
        for (i = [0:1])
            translate([INT_WIDTH + WALL - 1, WALL + 20 + i * 25, WALL + 10])
                rotate([0, 90, 0])
                    cylinder(d=6, h=WALL + 2);

        // Back - power cable
        translate([INT_WIDTH/2, INT_DEPTH + WALL - 1, WALL + 15])
            rotate([-90, 0, 0])
                cylinder(d=10, h=WALL + 2);

        // Back - barcode scanner cable
        translate([INT_WIDTH/2 + 30, INT_DEPTH + WALL - 1, WALL + 15])
            rotate([-90, 0, 0])
                cylinder(d=6, h=WALL + 2);

        // Front - USB port access (for ESP32 programming)
        translate([ESP32_X + WALL + ESP32_LENGTH/2 - 5,
                   -1,
                   WALL + 3])
            cube([10, WALL + 2, 8]);

        // --- Ventilation Slots (sides) ---
        for (i = [0:4]) {
            // Left vents
            translate([-1, WALL + 10 + i * (VENT_SLOT_L + VENT_SPACING), INT_HEIGHT])
                cube([WALL + 2, VENT_SLOT_L, VENT_SLOT_W]);
            // Right vents
            translate([INT_WIDTH + WALL - 1, WALL + 10 + i * (VENT_SLOT_L + VENT_SPACING), INT_HEIGHT])
                cube([WALL + 2, VENT_SLOT_L, VENT_SLOT_W]);
        }

        // Bottom ventilation grid
        for (x = [0:5])
            for (y = [0:3])
                translate([WALL + 15 + x * 16, WALL + 15 + y * 18, -1])
                    rounded_rect(10, 12, WALL + 2, r=1);
    }

    // --- Internal Features ---

    // ESP32 mounting standoffs
    translate([WALL + ESP32_X, WALL + ESP32_Y, WALL]) {
        // Corner posts
        for (pos = [[2, 2], [ESP32_LENGTH - 2, 2],
                    [2, ESP32_WIDTH - 2], [ESP32_LENGTH - 2, ESP32_WIDTH - 2]])
            translate([pos[0], pos[1], 0])
                difference() {
                    cylinder(d=5, h=5);
                    translate([0, 0, 2])
                        cylinder(d=2, h=4);
                }
    }

    // A4988 driver standoffs (3 drivers)
    for (i = [0:2]) {
        translate([WALL + DRIVER_X + i * DRIVER_SPACING, WALL + DRIVER_Y, WALL]) {
            for (pos = [[2, 2], [A4988_WIDTH - 2, 2],
                        [2, A4988_LENGTH - 2], [A4988_WIDTH - 2, A4988_LENGTH - 2]])
                translate([pos[0], pos[1], 0])
                    difference() {
                        cylinder(d=4, h=8);
                        translate([0, 0, 5])
                            cylinder(d=1.8, h=4);
                    }
        }
    }

    // Wire management clips
    translate([WALL + INT_WIDTH/2, WALL + 5, WALL])
        wire_clip();
    translate([WALL + INT_WIDTH/2, WALL + INT_DEPTH - 10, WALL])
        wire_clip();

    // Lid screw bosses (4 corners)
    for (pos = [[WALL + 5, WALL + 5],
                [WALL + INT_WIDTH - 5, WALL + 5],
                [WALL + 5, WALL + INT_DEPTH - 5],
                [WALL + INT_WIDTH - 5, WALL + INT_DEPTH - 5]])
        translate([pos[0], pos[1], WALL])
            screw_boss();
}

// --- Lid ---
module enclosure_lid() {
    difference() {
        union() {
            // Lid top
            rounded_rect(INT_WIDTH + WALL*2, INT_DEPTH + WALL*2, WALL, r=3);

            // Lip (fits inside box)
            translate([WALL - 0.5, WALL - 0.5, -LID_LIP])
                rounded_rect(INT_WIDTH + 1, INT_DEPTH + 1, LID_LIP, r=2);
        }

        // Screw holes (4 corners)
        for (pos = [[WALL + 5, WALL + 5],
                    [WALL + INT_WIDTH - 5, WALL + 5],
                    [WALL + 5, WALL + INT_DEPTH - 5],
                    [WALL + INT_WIDTH - 5, WALL + INT_DEPTH - 5]])
            translate([pos[0], pos[1], -LID_LIP - 1])
                cylinder(d=M3_DIA, h=WALL + LID_LIP + 2);

        // Label recess (for labeling the box)
        translate([WALL + 10, WALL + 20, WALL - 0.6])
            rounded_rect(INT_WIDTH - 20, INT_DEPTH - 40, 1, r=2);

        // Ventilation slots on lid
        for (i = [0:3])
            translate([WALL + 20 + i * 22, WALL + 10, -1])
                rounded_rect(15, INT_DEPTH - 20, WALL + 2, r=1);
    }
}

// --- Helper: Wire management clip ---
module wire_clip() {
    clip_w = 10;
    clip_h = 10;
    wire_d = 5;

    difference() {
        cube([clip_w, 8, clip_h]);
        translate([clip_w/2, -1, clip_h - wire_d/2])
            rotate([-90, 0, 0])
                cylinder(d=wire_d, h=10);
        // Opening for wire insertion
        translate([clip_w/2 - wire_d/2, -1, clip_h - wire_d/2])
            cube([wire_d, 10, wire_d]);
    }
}

// --- Helper: Screw boss ---
module screw_boss() {
    difference() {
        cylinder(d=8, h=INT_HEIGHT - 1);
        translate([0, 0, INT_HEIGHT - 8])
            cylinder(d=2.5, h=9);  // Self-tapping screw hole
    }
}

// --- DIN Rail Mount Clip (optional, for clean installation) ---
module din_rail_clip() {
    // Standard 35mm DIN rail
    rail_w = 35;
    clip_h = 15;

    difference() {
        union() {
            cube([rail_w + 10, 12, clip_h]);

            // Spring clip
            translate([0, 10, 0])
                cube([8, 5, clip_h]);
            translate([rail_w + 2, 10, 0])
                cube([8, 5, clip_h]);
        }

        // Rail channel
        translate([5, 3, -1])
            cube([rail_w, 8, clip_h + 2]);

        // Rail lip undercuts
        translate([3, 5, -1])
            cube([3, 6, clip_h + 2]);
        translate([rail_w + 4, 5, -1])
            cube([3, 6, clip_h + 2]);

        // Mounting holes for enclosure
        translate([rail_w/2, 6, -1])
            cylinder(d=M4_DIA, h=clip_h + 2);
    }
}

// --- Full Assembly View ---
module enclosure_assembly() {
    color("SteelBlue")
        enclosure_box();

    color("SteelBlue", 0.4)
        translate([0, 0, INT_HEIGHT + WALL + 5])
            enclosure_lid();

    // ESP32 preview
    color("DarkGreen", 0.6)
        translate([WALL + ESP32_X, WALL + ESP32_Y, WALL + 5])
            cube([ESP32_LENGTH, ESP32_WIDTH, ESP32_HEIGHT]);

    // A4988 drivers preview
    for (i = [0:2])
        color("Purple", 0.6)
            translate([WALL + DRIVER_X + i * DRIVER_SPACING,
                       WALL + DRIVER_Y, WALL + 8])
                cube([A4988_WIDTH, A4988_LENGTH, 15]);
}

// --- Render ---
enclosure_assembly();

// Individual parts (uncomment one):
// enclosure_box();
// translate([0, 0, 5]) enclosure_lid();
// din_rail_clip();
