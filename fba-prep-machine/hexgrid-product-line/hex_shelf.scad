// ============================================================
// HexGrid Product: Catch-All Tray / Phone Stand Shelf
// SKU: HG-TRY-025 (25mm tall flat tray)
// SKU: HG-TRY-ANG (angled phone/tablet stand)
// Print time: ~1.5 hrs | Filament: ~25g ($0.50) | Sell: $10-14
// Great for: keys, wallet, phone, watch, coins, EDC
// ============================================================

use <hex_common.scad>
include <hex_common.scad>

// --- Tray Parameters ---
TRAY_H       = SHELF_HEIGHT;   // 25mm
LIP_HEIGHT   = 8;              // Raised edge to keep items in
LIP_THICK    = 1.6;            // Lip wall thickness
PHONE_ANGLE  = 65;             // Phone stand angle (degrees from horizontal)
PHONE_SLOT_W = 14;             // Width of phone slot
PHONE_SLOT_D = 4;              // Depth of phone slot groove

// Felt/rubber pad recess
PAD_DEPTH    = 0.8;
PAD_DIA      = 50;

// --- Flat Catch-All Tray ---
module hex_tray() {
    difference() {
        union() {
            // Solid hex base
            hex_prism(TRAY_H);

            // Raised lip around edge
            translate([0, 0, TRAY_H])
                hex_ring(LIP_HEIGHT, HEX_SIZE, LIP_THICK);

            // Anti-slip feet
            anti_slip_feet();
        }

        // Scoop interior (slightly concave for easy item pickup)
        translate([0, 0, TRAY_H + 0.5])
            scale([1, 1, 0.15])
                sphere(r=HEX_SIZE/2 - HEX_WALL - 2, $fn=FN_ROUND);

        // Magnet holes
        mag_holes(MAG_Z);

        // Soft-touch pad recess in base of tray
        translate([0, 0, TRAY_H - PAD_DEPTH])
            cylinder(d=PAD_DIA, h=PAD_DEPTH + 1, $fn=FN_ROUND);

        // Brand text
        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();
    }
}

// --- Phone/Tablet Stand Tray ---
module hex_phone_stand() {
    back_height = 55;  // Back wall holds phone up

    difference() {
        union() {
            // Base hex
            hex_prism(TRAY_H);

            // Angled back rest
            translate([0, HEX_SIZE/4, TRAY_H])
                rotate([-90 + PHONE_ANGLE, 0, 0])
                    translate([-HEX_SIZE/3, 0, 0])
                        cube([HEX_SIZE*2/3, back_height, 3]);

            // Front lip (phone rests against this)
            translate([-HEX_SIZE/3, -HEX_SIZE/4, TRAY_H])
                cube([HEX_SIZE*2/3, 5, 8]);

            // Side supports
            for (x = [-HEX_SIZE/3, HEX_SIZE/3 - 3]) {
                translate([x, -HEX_SIZE/4, TRAY_H])
                    hull() {
                        cube([3, 5, 8]);
                        translate([0, HEX_SIZE/4, 0])
                            rotate([-90 + PHONE_ANGLE, 0, 0])
                                cube([3, back_height * 0.3, 3]);
                    }
            }

            anti_slip_feet();
        }

        // Phone slot groove (prevents sliding)
        translate([-HEX_SIZE/3 + 5, -HEX_SIZE/4 + 1, TRAY_H - PHONE_SLOT_D])
            cube([HEX_SIZE*2/3 - 10, PHONE_SLOT_W, PHONE_SLOT_D + 1]);

        // Charging cable channel (center of phone slot)
        translate([-5, -HEX_SIZE/4 - 1, TRAY_H - PHONE_SLOT_D - 3])
            cube([10, 8, PHONE_SLOT_D + 4]);

        // Magnet holes
        mag_holes(MAG_Z);

        // Brand text
        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();
    }
}

// --- Watch Stand Tray ---
module hex_watch_stand() {
    pillow_w = 30;
    pillow_d = 20;

    difference() {
        union() {
            // Base hex
            hex_prism(TRAY_H);

            // Watch pillow (raised cushion to drape watch band over)
            translate([0, 0, TRAY_H])
                scale([1, 0.7, 1])
                    cylinder(d=pillow_w, h=15, $fn=FN_ROUND);

            // Lip
            translate([0, 0, TRAY_H])
                hex_ring(LIP_HEIGHT, HEX_SIZE, LIP_THICK);

            anti_slip_feet();
        }

        // Watch band channels (2 slots for band to drape)
        translate([-pillow_w/2 - 5, -3, TRAY_H + 5])
            cube([pillow_w + 10, 6, 12]);

        // Hollow pillow (save filament)
        translate([0, 0, TRAY_H + 2])
            scale([1, 0.7, 1])
                cylinder(d=pillow_w - 4, h=12, $fn=FN_ROUND);

        // Magnet holes
        mag_holes(MAG_Z);

        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();
    }
}

// --- Deep Tray Variant (for coins, pills, etc) ---
module hex_deep_tray() {
    deep_h = 40;
    difference() {
        union() {
            hex_shell(deep_h);
            hex_prism(HEX_BASE + 1);
            anti_slip_feet();
        }
        mag_holes(MAG_Z);

        // Rounded interior bottom
        translate([0, 0, HEX_BASE + 5])
            scale([1, 1, 0.3])
                sphere(r=HEX_SIZE/2 - HEX_WALL - 1, $fn=FN_ROUND);

        translate([0, 0, -0.1])
            mirror([0, 0, 1])
                translate([0, 0, -0.7])
                    brand_text();
    }
}

// --- Render ---
hex_tray();
mag_preview();

// Variants (uncomment one):
// hex_phone_stand();
// hex_watch_stand();
// hex_deep_tray();
