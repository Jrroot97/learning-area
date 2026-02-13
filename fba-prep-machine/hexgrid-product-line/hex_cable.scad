// ============================================================
// HexGrid Product: Cable Management Organizer
// SKU: HG-CBL-020 (desktop cable clips)
// SKU: HG-CBL-USB (charging dock)
// Print time: ~1 hr | Filament: ~15g ($0.30) | Sell: $8-12
// ============================================================

use <hex_common.scad>
include <hex_common.scad>

// --- Cable Parameters ---
CABLE_H        = CABLE_HEIGHT;   // 20mm base height
NUM_SLOTS      = 3;              // Number of cable slots
SLOT_DIA       = 7;              // Cable slot diameter (fits USB-C, Lightning)
SLOT_OPENING   = 3;              // Slot entry gap (cable snaps in)
SLOT_SPACING   = 15;             // Distance between slots

// USB dock variant
USB_SLOT_W     = 14;             // Width for USB-C/Lightning connector
USB_SLOT_D     = 8;              // Depth for connector
USB_SLOT_H     = 20;             // How tall the phone rests

// Weighted base
WEIGHT_POCKET  = true;           // Pocket for coins/washers (adds weight)
WEIGHT_DIA     = 25;
WEIGHT_DEPTH   = 8;

// --- Desktop Cable Clip Organizer ---
module hex_cable_clips() {
    difference() {
        union() {
            // Hex base
            hex_prism(CABLE_H);

            // Cable clip fingers
            for (i = [0:NUM_SLOTS-1]) {
                x_pos = (i - (NUM_SLOTS-1)/2) * SLOT_SPACING;
                translate([x_pos, 0, CABLE_H])
                    cable_clip_finger();
            }

            // Anti-slip feet
            anti_slip_feet();
        }

        // Magnet holes
        mag_holes(MAG_Z);

        // Weight pocket (for stability)
        if (WEIGHT_POCKET)
            translate([0, 0, HEX_BASE])
                cylinder(d=WEIGHT_DIA, h=WEIGHT_DEPTH, $fn=FN_ROUND);

        // Brand text
        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();

        // Cable routing channels (grooves in top surface)
        for (i = [0:NUM_SLOTS-1]) {
            x_pos = (i - (NUM_SLOTS-1)/2) * SLOT_SPACING;
            translate([x_pos, -HEX_SIZE/2, CABLE_H - 2])
                rotate([-90, 0, 0])
                    cylinder(d=SLOT_DIA + 2, h=HEX_SIZE/2, $fn=FN_ROUND);
        }
    }
}

// --- Individual Cable Clip Finger ---
module cable_clip_finger() {
    $fn = FN_ROUND;
    clip_h = 12;
    clip_outer = SLOT_DIA + 5;

    difference() {
        // Outer cylinder
        cylinder(d=clip_outer, h=clip_h);

        // Cable hole
        translate([0, 0, -1])
            cylinder(d=SLOT_DIA, h=clip_h + 2);

        // Entry slot (snap-in opening)
        translate([-SLOT_OPENING/2, -clip_outer/2 - 1, -1])
            cube([SLOT_OPENING, clip_outer/2 + 1, clip_h + 2]);

        // Tapered entry (easier to push cable in)
        translate([0, -clip_outer/2, clip_h/2])
            rotate([0, 0, 0])
                hull() {
                    translate([-SLOT_OPENING/2, 0, 0])
                        cube([SLOT_OPENING, 1, clip_h/2]);
                    translate([-SLOT_OPENING - 1, -3, 0])
                        cube([SLOT_OPENING + 2, 1, clip_h/2]);
                }
    }
}

// --- Charging Dock (Phone + Watch) ---
module hex_charging_dock() {
    phone_angle = 70;  // Degrees from horizontal
    watch_pillow_h = 20;

    difference() {
        union() {
            // Hex base
            hex_prism(CABLE_H + 5);

            // Phone rest (angled back)
            translate([-20, 5, CABLE_H + 5])
                rotate([-90 + phone_angle, 0, 0])
                    rounded_phone_rest();

            // Watch charger pad area
            translate([15, -10, CABLE_H + 5])
                cylinder(d=35, h=3, $fn=FN_ROUND);

            anti_slip_feet();
        }

        // Phone connector slot (USB-C / Lightning)
        translate([-USB_SLOT_W/2, -5, CABLE_H])
            cube([USB_SLOT_W, USB_SLOT_D, 8]);

        // Cable exit underneath
        translate([0, 0, HEX_BASE])
            cylinder(d=12, h=CABLE_H, $fn=FN_ROUND);

        // Watch charger cable hole
        translate([15, -10, CABLE_H])
            cylinder(d=8, h=10, $fn=FN_ROUND);

        // Magnet holes
        mag_holes(MAG_Z);

        // Weight pocket
        if (WEIGHT_POCKET)
            translate([-15, 10, HEX_BASE])
                cylinder(d=WEIGHT_DIA, h=WEIGHT_DEPTH, $fn=FN_ROUND);

        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();
    }
}

module rounded_phone_rest() {
    $fn = FN_ROUND;
    hull() {
        cube([40, 3, 2]);
        translate([2, 0, 50])
            cube([36, 3, 2]);
    }
}

// --- Multi-Cable Tidy (wrap excess cable) ---
module hex_cable_tidy() {
    spool_h = 30;
    spool_dia = HEX_SIZE - HEX_WALL*2 - 8;
    slot_w = 5;

    difference() {
        union() {
            hex_prism(CABLE_H);

            // Central spool for wrapping cables
            translate([0, 0, CABLE_H])
                cylinder(d=spool_dia, h=spool_h, $fn=FN_ROUND);

            // Top and bottom flanges on spool
            translate([0, 0, CABLE_H])
                cylinder(d=spool_dia + 10, h=3, $fn=FN_ROUND);
            translate([0, 0, CABLE_H + spool_h - 3])
                cylinder(d=spool_dia + 10, h=3, $fn=FN_ROUND);

            anti_slip_feet();
        }

        // Cable entry slots (2 slots, opposite sides)
        for (a = [0, 180])
            rotate([0, 0, a])
                translate([-slot_w/2, 0, CABLE_H + 3])
                    cube([slot_w, spool_dia, spool_h - 6]);

        // Hollow spool center (save filament + route cable)
        translate([0, 0, CABLE_H - 1])
            cylinder(d=spool_dia - 10, h=spool_h + 2, $fn=FN_ROUND);

        // Base cable exit
        translate([0, -HEX_SIZE/3, HEX_BASE])
            cube([8, HEX_SIZE/3, CABLE_H]);

        mag_holes(MAG_Z);

        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();
    }
}

// --- Render ---
hex_cable_clips();
mag_preview();

// Variants (uncomment one):
// hex_charging_dock();
// hex_cable_tidy();
