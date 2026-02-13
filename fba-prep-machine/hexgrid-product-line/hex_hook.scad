// ============================================================
// HexGrid Product: Wall Hook (Keys / Headphones / Bags)
// SKU: HG-HK1-030 (single hook)
// SKU: HG-HK2-030 (double hook)
// SKU: HG-HKH-030 (headphone hook)
// Print time: ~1 hr | Filament: ~18g ($0.36) | Sell: $8-12
// ============================================================

use <hex_common.scad>
include <hex_common.scad>

// --- Hook Parameters ---
HOOK_H         = HOOK_HEIGHT;    // 30mm base depth
HOOK_LENGTH    = 35;             // How far hook sticks out from wall
HOOK_THICK     = 6;              // Hook arm thickness
HOOK_TIP_CURL  = 12;             // Upward curl at tip (prevents falling off)
HOOK_STYLE     = "single";       // "single", "double", "headphone", "bag"

// Wall mount screw holes
SCREW_DIA      = 5;              // #8 or #10 screw clearance
SCREW_HEAD_DIA = 10;             // Screw head / drywall anchor

// Weight capacity improvers
SUPPORT_RIB    = true;           // Triangular support rib underneath

// --- Single Hook ---
module hex_hook_single() {
    difference() {
        union() {
            // Hex base (flush against wall)
            hex_prism(HOOK_H);

            // Hook arm
            translate([-HOOK_THICK/2, 0, HOOK_H])
                hook_arm();

            // Support rib
            if (SUPPORT_RIB)
                translate([0, 0, 0])
                    hook_support_rib();
        }

        // Magnet holes (for connecting to other hex pieces on wall)
        mag_holes(MAG_Z);

        // Wall mount screw holes (keyhole slots)
        translate([0, -12, -1])
            keyhole_slot();
        translate([0, 12, -1])
            keyhole_slot();

        // Brand text (on face)
        translate([0, 0, HOOK_H - 0.5])
            brand_text("HG", 4);
    }
}

// --- Hook Arm Shape ---
module hook_arm() {
    $fn = FN_ROUND;

    // Arm extending outward
    hull() {
        cube([HOOK_THICK, HOOK_THICK, 2]);
        translate([0, -HOOK_LENGTH + HOOK_THICK, -15])
            cube([HOOK_THICK, HOOK_THICK, 2]);
    }

    // Upward curl at tip
    translate([0, -HOOK_LENGTH + HOOK_THICK, -15])
        hull() {
            cube([HOOK_THICK, HOOK_THICK, 2]);
            translate([0, 2, -HOOK_TIP_CURL])
                cube([HOOK_THICK, HOOK_THICK, 2]);
        }

    // Rounded tip
    translate([HOOK_THICK/2, -HOOK_LENGTH + HOOK_THICK + 2, -15 - HOOK_TIP_CURL])
        sphere(d=HOOK_THICK + 2, $fn=FN_ROUND);
}

// --- Support Rib (triangular) ---
module hook_support_rib() {
    translate([-2, 0, 2]) {
        hull() {
            // Base on wall
            cube([4, 4, HOOK_H - 4]);
            // Tip under hook arm
            translate([0, -HOOK_LENGTH * 0.6, HOOK_H - 4])
                cube([4, 4, 2]);
        }
    }
}

// --- Keyhole Screw Slot ---
module keyhole_slot() {
    $fn = FN_ROUND;
    // Large hole for screw head
    cylinder(d=SCREW_HEAD_DIA, h=4);
    // Slot for screw shaft (slide down to lock)
    translate([0, -7, 0])
        hull() {
            cylinder(d=SCREW_DIA, h=HOOK_H + 2);
            translate([0, 7, 0])
                cylinder(d=SCREW_DIA, h=HOOK_H + 2);
        }
    // Counter-sink the head area
    cylinder(d=SCREW_HEAD_DIA, h=3);
}

// --- Double Hook ---
module hex_hook_double() {
    difference() {
        union() {
            hex_prism(HOOK_H);

            // Two hooks, angled outward
            translate([-HOOK_THICK/2, -8, HOOK_H])
                rotate([0, 0, -20])
                    hook_arm();
            translate([-HOOK_THICK/2, 8, HOOK_H])
                rotate([0, 0, 20])
                    hook_arm();

            // Support ribs
            translate([0, -8, 0])
                rotate([0, 0, -20])
                    hook_support_rib();
            translate([0, 8, 0])
                rotate([0, 0, 20])
                    hook_support_rib();
        }

        mag_holes(MAG_Z);

        translate([0, -12, -1])
            keyhole_slot();
        translate([0, 12, -1])
            keyhole_slot();

        translate([0, 0, HOOK_H - 0.5])
            brand_text("HG", 4);
    }
}

// --- Headphone Hook ---
module hex_hook_headphone() {
    arm_length = 50;  // Longer arm for headphone band
    arm_width  = 25;  // Wide enough for headband

    difference() {
        union() {
            hex_prism(HOOK_H);

            // Wide flat arm
            translate([-arm_width/2, 0, HOOK_H]) {
                // Extending outward and slightly down
                hull() {
                    cube([arm_width, 3, 3]);
                    translate([3, -arm_length + 10, -20])
                        cube([arm_width - 6, 10, 3]);
                }

                // Upward anti-slip lip at end
                translate([3, -arm_length + 10, -20])
                    hull() {
                        cube([arm_width - 6, 10, 3]);
                        translate([2, 5, -8])
                            cube([arm_width - 10, 5, 3]);
                    }
            }

            // Cable notch holder (on top of arm)
            translate([-3, -20, HOOK_H])
                cube([6, 10, 8]);

            // Support rib (centered)
            hook_support_rib();
        }

        // Cable channel through notch
        translate([0, -15, HOOK_H + 3])
            rotate([0, 90, 0])
                cylinder(d=5, h=20, center=true, $fn=FN_ROUND);

        mag_holes(MAG_Z);

        translate([0, -12, -1])
            keyhole_slot();
        translate([0, 12, -1])
            keyhole_slot();

        translate([0, 0, HOOK_H - 0.5])
            brand_text("HG", 4);
    }
}

// --- Heavy Duty Bag Hook ---
module hex_hook_bag() {
    // Stronger, thicker hook for coats/bags (up to 15 lbs)
    bag_thick = 10;
    bag_length = 45;

    difference() {
        union() {
            hex_prism(HOOK_H);

            // Thick hook arm
            translate([-bag_thick/2, 0, HOOK_H]) {
                hull() {
                    cube([bag_thick, bag_thick, 3]);
                    translate([0, -bag_length + bag_thick, -25])
                        cube([bag_thick, bag_thick, 3]);
                }

                // Upward curl
                translate([0, -bag_length + bag_thick, -25])
                    hull() {
                        cube([bag_thick, bag_thick, 3]);
                        translate([0, 5, -15])
                            cube([bag_thick, bag_thick, 3]);
                    }

                // Rounded tip
                translate([bag_thick/2, -bag_length + bag_thick + 5, -40])
                    sphere(d=bag_thick + 4, $fn=FN_ROUND);
            }

            // Double support ribs
            translate([0, -5, 0]) hook_support_rib();
            translate([0, 5, 0]) hook_support_rib();
        }

        mag_holes(MAG_Z);

        // 3 keyhole slots for heavy load
        for (y = [-15, 0, 15])
            translate([0, y, -1])
                keyhole_slot();

        translate([0, 0, HOOK_H - 0.5])
            brand_text("HG", 4);
    }
}

// --- Render ---
hex_hook_single();
mag_preview();

// Variants (uncomment one):
// hex_hook_double();
// hex_hook_headphone();
// hex_hook_bag();
