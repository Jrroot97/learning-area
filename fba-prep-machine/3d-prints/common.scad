// ============================================================
// FBA Prep Machine - Common Parameters
// All dimensions in millimeters
// ============================================================

// --- Texjoy Bottle Dimensions (16oz) ---
BOTTLE_WIDTH   = 65;    // X dimension (front-to-back)
BOTTLE_DEPTH   = 65;    // Y dimension (side-to-side)
BOTTLE_HEIGHT  = 170;   // Z dimension (cap to base)
BOTTLE_CLEARANCE = 3;   // Extra gap per side for easy sliding

// Derived chute dimensions
CHUTE_WIDTH    = BOTTLE_WIDTH + BOTTLE_CLEARANCE * 2;   // 71mm
CHUTE_DEPTH    = BOTTLE_DEPTH + BOTTLE_CLEARANCE * 2;   // 71mm
CHUTE_WALL     = 3;     // Wall thickness
CHUTE_HEIGHT   = 50;    // Wall height (doesn't need to be full bottle height)

// --- Hardware Dimensions ---
// NEMA 17 Stepper Motor
NEMA17_SIZE     = 42.3;
NEMA17_HOLE_SPACING = 31;
NEMA17_SHAFT_DIA    = 5;
NEMA17_BOSS_DIA     = 22;
NEMA17_SCREW_DIA    = 3.2;  // M3 clearance

// A4988 Stepper Driver
A4988_WIDTH  = 20.5;
A4988_LENGTH = 15.5;

// ESP32 DevKit V1
ESP32_WIDTH  = 28;
ESP32_LENGTH = 52;
ESP32_HEIGHT = 8;

// GM65 Barcode Scanner Module
GM65_WIDTH   = 20.5;
GM65_LENGTH  = 34;
GM65_HEIGHT  = 18;

// IR LED / Photodiode (5mm)
IR_LED_DIA   = 5.2;

// Servo (SG90/MG90S)
SERVO_WIDTH  = 12.5;
SERVO_LENGTH = 23;
SERVO_HEIGHT = 22;
SERVO_TAB_WIDTH = 32.5;
SERVO_SCREW_SPACING = 28;

// Nichrome Wire
NICHROME_DIA = 1.0;

// --- Fastener Dimensions ---
M3_DIA       = 3.2;
M3_HEAD_DIA  = 5.8;
M3_NUT_W     = 5.5;
M3_NUT_H     = 2.4;

M4_DIA       = 4.2;
M4_HEAD_DIA  = 7.2;

// --- Snap-Fit Parameters ---
SNAP_WIDTH     = 8;
SNAP_HEIGHT    = 4;
SNAP_DEPTH     = 2;
SNAP_TOLERANCE = 0.3;

// --- Print Settings ---
LAYER_HEIGHT  = 0.2;
NOZZLE_DIA    = 0.4;
$fn = 40;  // Circle resolution

// --- Helper Modules ---

// Rounded rectangle
module rounded_rect(w, d, h, r=2) {
    hull() {
        for (x = [r, w-r])
            for (y = [r, d-r])
                translate([x, y, 0])
                    cylinder(h=h, r=r);
    }
}

// M3 screw hole (through)
module m3_hole(h=10) {
    cylinder(d=M3_DIA, h=h);
}

// M3 counterbore
module m3_counterbore(h=10, cb_depth=3) {
    cylinder(d=M3_DIA, h=h);
    cylinder(d=M3_HEAD_DIA, h=cb_depth);
}

// M3 nut trap (hexagonal)
module m3_nut_trap(h=M3_NUT_H) {
    cylinder(d=M3_NUT_W / cos(30), h=h, $fn=6);
}

// Snap-fit tab (male)
module snap_tab() {
    // Tapered tab for snap-fit connection
    hull() {
        cube([SNAP_WIDTH, SNAP_DEPTH * 0.5, SNAP_HEIGHT]);
        translate([0, SNAP_DEPTH, SNAP_HEIGHT * 0.3])
            cube([SNAP_WIDTH, 0.1, SNAP_HEIGHT * 0.4]);
    }
}

// Snap-fit slot (female)
module snap_slot() {
    cube([SNAP_WIDTH + SNAP_TOLERANCE*2,
          SNAP_DEPTH + SNAP_TOLERANCE,
          SNAP_HEIGHT + SNAP_TOLERANCE*2]);
}
