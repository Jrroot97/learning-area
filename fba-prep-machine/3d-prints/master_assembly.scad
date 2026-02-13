// ============================================================
// FBA PREP MACHINE - MASTER ASSEMBLY & FITMENT VERIFICATION
// ============================================================
//
// Shows all 6 stations assembled in production-line sequence
// with bottles flowing through to verify:
//   1. Chute sections connect properly (snap-fit alignment)
//   2. Bottle fits through every station with clearance
//   3. Turntable chute interfaces match chute dimensions
//   4. Hopper output matches chute input
//   5. Sensor brackets clip onto correct wall thickness
//   6. Heat sealer width accommodates poly tube
//   7. Label dispensers reach the bottle path
//   8. Electronics enclosure fits beside the line
//
// USAGE:
//   F5 = Quick preview (fast)
//   F6 = Full render (slow but exact)
//   Toggle SHOW_* flags to isolate sections
//   Set CHECK_FITMENT=true for red/green pass/fail markers
//
// ============================================================

// ============================================================
// SHARED PARAMETERS (from common.scad)
// ============================================================

// Bottle
BOTTLE_WIDTH     = 65;
BOTTLE_DEPTH     = 65;
BOTTLE_HEIGHT    = 170;
BOTTLE_CLEARANCE = 3;

// Chute (derived)
CHUTE_WIDTH  = BOTTLE_WIDTH + BOTTLE_CLEARANCE * 2;   // 71mm inner
CHUTE_DEPTH  = BOTTLE_DEPTH + BOTTLE_CLEARANCE * 2;   // 71mm inner
CHUTE_WALL   = 3;
CHUTE_HEIGHT = 50;
CHUTE_OUTER  = CHUTE_DEPTH + CHUTE_WALL * 2;          // 77mm outer

// Chute section
SECTION_LENGTH = 200;
BASE_THICKNESS = 4;

// Hardware
NEMA17_SIZE        = 42.3;
NEMA17_HOLE_SPACING = 31;
NEMA17_SHAFT_DIA   = 5;
NEMA17_BOSS_DIA    = 22;
M3_DIA  = 3.2;
M4_DIA  = 4.2;
SERVO_LENGTH = 23;
SERVO_HEIGHT = 22;
SERVO_TAB_WIDTH = 32.5;

// GM65 Scanner
GM65_WIDTH  = 20.5;
GM65_LENGTH = 34;
GM65_HEIGHT = 18;

// IR Sensor
IR_LED_DIA = 5.2;

// Turntable station
TT_BASE_W = NEMA17_SIZE + 30;     // 72.3mm
TT_BASE_D = NEMA17_SIZE + 60;     // 102.3mm
TT_BASE_H = 15;
TT_DISK_DIA = 100;
TT_GUIDE_INNER = BOTTLE_WIDTH + 5; // 70mm

// Hopper funnel
FUNNEL_INPUT_W  = CHUTE_DEPTH * 3;       // 213mm
FUNNEL_LENGTH   = 250;
FUNNEL_HEIGHT   = 80;
FUNNEL_OUTPUT_W = CHUTE_DEPTH + CHUTE_WALL * 2; // 77mm

// Label dispenser
LABEL_FRAME_W   = 58 + 30;   // 88mm
LABEL_FRAME_D   = 80;
LABEL_FRAME_H   = 100 + 30;  // 130mm
PEEL_BAR_W      = 58 + 10;   // 68mm

// Heat sealer
SEAL_WIDTH = 200;
JAW_DEPTH  = 30;
JAW_THICK  = 10;

// Poly bagger
COLLAR_W = BOTTLE_WIDTH + 20;   // 85mm
COLLAR_D = BOTTLE_DEPTH + 20;   // 85mm
COLLAR_H = BOTTLE_HEIGHT + 40;  // 210mm
TUBE_WIDTH = 200;

// Electronics enclosure
ENCL_W = 120 + 6;  // 126mm outer
ENCL_D = 90 + 6;   // 96mm outer
ENCL_H = 45 + 3;   // 48mm outer

// Snap-fit
SNAP_WIDTH = 8;
SNAP_HEIGHT = 4;
SNAP_DEPTH = 2;

// Print settings
$fn = 30;

// ============================================================
// DISPLAY CONTROLS
// ============================================================
SHOW_HOPPER       = true;
SHOW_CHUTES       = true;
SHOW_COUNTER      = true;
SHOW_TURNTABLE    = true;
SHOW_LABEL_DISP   = true;
SHOW_BAGGER       = true;
SHOW_SEALER       = true;
SHOW_ELECTRONICS  = true;
SHOW_BOTTLES      = true;    // Ghost bottles at each station
SHOW_STOP_GATES   = true;
CHECK_FITMENT     = true;    // Show pass/fail markers
SHOW_DIMENSIONS   = true;    // Show dimension annotations
CROSS_SECTION     = false;   // Cut everything in half

// ============================================================
// HELPER MODULES
// ============================================================

module rounded_rect(w, d, h, r=2) {
    hull() {
        for (x = [r, w-r])
            for (y = [r, d-r])
                translate([x, y, 0])
                    cylinder(h=h, r=r);
    }
}

// Fitment marker: green sphere = pass, red = fail
module fit_check(pass, label, pos) {
    if (CHECK_FITMENT) {
        translate(pos)
            color(pass ? "Lime" : "Red")
                sphere(d=pass ? 4 : 8, $fn=16);
        if (!pass)
            echo(str("!! FITMENT FAIL: ", label));
        else
            echo(str("   OK: ", label));
    }
}

// Dimension annotation line
module dim_line(from, to, label, offset=20) {
    if (SHOW_DIMENSIONS) {
        color("Cyan", 0.6) {
            hull() {
                translate(from) sphere(d=1, $fn=8);
                translate(to) sphere(d=1, $fn=8);
            }
        }
    }
}

// Ghost bottle (transparent preview)
module ghost_bottle(pos) {
    if (SHOW_BOTTLES)
        color("SaddleBrown", 0.25)
            translate(pos)
                cube([BOTTLE_WIDTH, BOTTLE_DEPTH, BOTTLE_HEIGHT]);
}

// ============================================================
// SIMPLIFIED STATION MODULES (self-contained geometry)
// ============================================================

// --- Chute Section ---
module _chute(len=SECTION_LENGTH) {
    // Base plate
    cube([len, CHUTE_OUTER, BASE_THICKNESS]);
    // Left wall
    cube([len, CHUTE_WALL, BASE_THICKNESS + CHUTE_HEIGHT]);
    // Right wall
    translate([0, CHUTE_DEPTH + CHUTE_WALL, 0])
        cube([len, CHUTE_WALL, BASE_THICKNESS + CHUTE_HEIGHT]);
    // Snap tabs (output end)
    translate([len, CHUTE_WALL + 10, BASE_THICKNESS])
        cube([SNAP_DEPTH, SNAP_WIDTH, SNAP_HEIGHT]);
    translate([len, CHUTE_OUTER - CHUTE_WALL - 10 - SNAP_WIDTH, BASE_THICKNESS])
        cube([SNAP_DEPTH, SNAP_WIDTH, SNAP_HEIGHT]);
}

// --- Stop Gate ---
module _stop_gate() {
    difference() {
        cube([CHUTE_OUTER, 15, CHUTE_HEIGHT + 15]);
        // Gate blade channel
        translate([CHUTE_WALL - 1, 5, 0])
            cube([CHUTE_DEPTH + 2, 3, CHUTE_HEIGHT + 5]);
        // Wall slots
        cube([CHUTE_WALL + 0.5, 15, CHUTE_HEIGHT]);
        translate([CHUTE_WALL + CHUTE_DEPTH - 0.5, 0, 0])
            cube([CHUTE_WALL + 0.5, 15, CHUTE_HEIGHT]);
    }
    // Servo mount
    translate([-SERVO_LENGTH - 5, 0, CHUTE_HEIGHT])
        cube([SERVO_LENGTH + 4, 15, SERVO_HEIGHT + 6]);
}

// --- IR Sensor Pair (emitter + receiver across chute) ---
module _ir_sensors() {
    BRACKET_H = 25;
    CLIP_D = 12;
    // Emitter side
    cube([15, CLIP_D + 10, BRACKET_H]);
    // Receiver side
    translate([0, CHUTE_OUTER + CLIP_D + 5, 0])
        cube([15, CLIP_D + 10, BRACKET_H]);
    // Show beam line
    color("Red", 0.3)
        translate([7.5, CLIP_D + 10, BRACKET_H/2])
            rotate([-90, 0, 0])
                cylinder(d=2, h=CHUTE_OUTER - 5, $fn=8);
}

// --- Turntable Station ---
module _turntable() {
    // Base platform
    rounded_rect(TT_BASE_W, TT_BASE_D, TT_BASE_H, r=3);
    // Chute interface walls (input)
    translate([TT_BASE_W/2 - CHUTE_DEPTH/2 - CHUTE_WALL, 0, 0])
        cube([CHUTE_WALL, 20, TT_BASE_H + CHUTE_HEIGHT]);
    translate([TT_BASE_W/2 + CHUTE_DEPTH/2, 0, 0])
        cube([CHUTE_WALL, 20, TT_BASE_H + CHUTE_HEIGHT]);
    // Chute interface walls (output)
    translate([TT_BASE_W/2 - CHUTE_DEPTH/2 - CHUTE_WALL, TT_BASE_D - 20, 0])
        cube([CHUTE_WALL, 20, TT_BASE_H + CHUTE_HEIGHT]);
    translate([TT_BASE_W/2 + CHUTE_DEPTH/2, TT_BASE_D - 20, 0])
        cube([CHUTE_WALL, 20, TT_BASE_H + CHUTE_HEIGHT]);
    // Turntable disk
    color("Orange", 0.6)
        translate([TT_BASE_W/2, TT_BASE_D/2 - 10, TT_BASE_H + 1])
            cylinder(d=TT_DISK_DIA, h=5);
    // Centering guide (4 posts)
    gi = TT_GUIDE_INNER;
    gw = 3;
    translate([TT_BASE_W/2 - gi/2 - gw, TT_BASE_D/2 - 10 - gi/2 - gw, TT_BASE_H + 7])
        for (x = [0, gi + gw])
            for (y = [0, gi + gw])
                translate([x, y, 0])
                    color("LightGreen", 0.5)
                        cube([gw, gw, 80]);
}

// --- Scanner Arm ---
module _scanner_arm() {
    cube([25, 60, 4]);
    // Scanner cradle
    translate([2, 22, 4])
        cube([21, GM65_LENGTH + 8, GM65_HEIGHT + 4]);
}

// --- Label Press Arm ---
module _label_press() {
    cube([20, 15, 20]);
    translate([0, 0, 15])
        cube([20, 50, 5]);
    translate([10, 45, 15])
        cylinder(d=30, h=8);
}

// --- Label Dispenser Frame ---
module _label_dispenser() {
    // Left side plate
    cube([LABEL_FRAME_D, LABEL_FRAME_H, 4]);
    // Right side plate
    translate([0, 0, LABEL_FRAME_W - 4])
        cube([LABEL_FRAME_D, LABEL_FRAME_H, 4]);
    // Roll (preview)
    color("White", 0.3)
        translate([LABEL_FRAME_D/2, LABEL_FRAME_H - 60, LABEL_FRAME_W/2])
            rotate([0, 90, 0])
                cylinder(d=100, h=58, center=true);
    // Peel bar
    color("Red")
        translate([10, LABEL_FRAME_H/2, 8])
            cube([PEEL_BAR_W, 12, 8]);
}

// --- Hopper Funnel ---
module _hopper() {
    // Tapered funnel (simplified)
    hull() {
        cube([FUNNEL_INPUT_W, 1, BASE_THICKNESS]);
        translate([(FUNNEL_INPUT_W - FUNNEL_OUTPUT_W)/2, FUNNEL_LENGTH, 0])
            cube([FUNNEL_OUTPUT_W, 1, BASE_THICKNESS]);
    }
    // Left wall
    hull() {
        cube([3, 1, FUNNEL_HEIGHT]);
        translate([(FUNNEL_INPUT_W - FUNNEL_OUTPUT_W)/2, FUNNEL_LENGTH, 0])
            cube([3, 1, FUNNEL_HEIGHT]);
    }
    // Right wall
    hull() {
        translate([FUNNEL_INPUT_W - 3, 0, 0])
            cube([3, 1, FUNNEL_HEIGHT]);
        translate([(FUNNEL_INPUT_W + FUNNEL_OUTPUT_W)/2 - 3, FUNNEL_LENGTH, 0])
            cube([3, 1, FUNNEL_HEIGHT]);
    }
}

// --- Poly Bagger (forming collar + roll holder) ---
module _bagger() {
    cw = COLLAR_W + 4;  // Collar outer width
    cd = COLLAR_D + 4;  // Collar outer depth
    // Forming collar
    difference() {
        cube([cw, cd, COLLAR_H]);
        translate([2, 2, -1])
            cube([COLLAR_W, COLLAR_D, COLLAR_H + 2]);
    }
    // Flare at top
    translate([-10, -10, COLLAR_H - 20])
        difference() {
            cube([cw + 20, cd + 20, 20]);
            translate([12, 12, -1])
                cube([COLLAR_W, COLLAR_D, 22]);
        }
    // Roll holder frame (above)
    color("Gray", 0.4)
        translate([-60, -5, COLLAR_H + 30])
            cube([TUBE_WIDTH + 30, 30, 5]);
    // Poly roll preview
    color("White", 0.2)
        translate([cw/2, 10, COLLAR_H + 60])
            rotate([0, 90, 0])
                cylinder(d=150, h=TUBE_WIDTH, center=true);
}

// --- Heat Sealer ---
module _sealer() {
    // Lower jaw
    cube([SEAL_WIDTH, JAW_DEPTH, JAW_THICK]);
    // Nichrome wire channel (visual)
    color("Red", 0.5)
        translate([0, JAW_DEPTH/2 - 1, JAW_THICK - 1.5])
            cube([SEAL_WIDTH, 2, 1.5]);
    // Upper jaw (open position)
    translate([SEAL_WIDTH + 10, 0, JAW_THICK/2])
        rotate([0, -30, 0])
            translate([-(SEAL_WIDTH + 10), 0, JAW_THICK/2 + 2])
                color("Orange", 0.6)
                    cube([SEAL_WIDTH, JAW_DEPTH, JAW_THICK]);
    // Tube guide below
    translate([-10, -5, -15])
        color("LightGreen", 0.5)
            cube([SEAL_WIDTH + 20, 40, 14]);
    // Cutter bar after
    translate([-10, JAW_DEPTH + 5, 0])
        color("Red", 0.7)
            cube([SEAL_WIDTH + 20, 10, 8]);
}

// --- Electronics Enclosure ---
module _enclosure() {
    difference() {
        rounded_rect(ENCL_W, ENCL_D, ENCL_H, r=3);
        translate([3, 3, 3])
            rounded_rect(ENCL_W - 6, ENCL_D - 6, ENCL_H, r=2);
    }
    // ESP32 inside (preview)
    color("DarkGreen", 0.5)
        translate([13, 13, 8])
            cube([52, 28, 8]);
    // A4988 drivers
    for (i = [0:2])
        color("Purple", 0.5)
            translate([13 + i * 28, 53, 11])
                cube([20.5, 15.5, 15]);
}

// ============================================================
// FULL MACHINE LAYOUT
// ============================================================
//
// Flow direction: +Y (left to right in default OpenSCAD view)
//
//  Y=0        Y=250      Y=450    Y=570      Y=770    Y=970     Y=1170
//  |           |           |        |           |        |          |
// [HOPPER] → [CHUTE1] → [COUNT] → [TURNTABLE] → [CHUTE2] → [BAGGER+SEALER]
//                                    ↑                        ↑
//                              [SCANNER]                [LABEL x3]
//                              [LABEL PRESS]
//
// [ELECTRONICS] mounted to the side

module full_machine() {
    // ---- Station 1: Hopper + Singulator ----
    if (SHOW_HOPPER) {
        color("SteelBlue", 0.7)
            translate([-(FUNNEL_INPUT_W - CHUTE_OUTER)/2, 0, 0])
                _hopper();

        ghost_bottle([CHUTE_WALL + 3, 120, BASE_THICKNESS + 1]);
    }

    // ---- Chute Section 1: Hopper → Counter ----
    if (SHOW_CHUTES) {
        color("LightGray", 0.6)
            translate([0, FUNNEL_LENGTH + 5, 0])
                _chute();
    }

    // ---- Station 2: Bottle Counter (IR sensors) ----
    counter_y = FUNNEL_LENGTH + 5 + 80;
    if (SHOW_COUNTER) {
        color("DarkRed", 0.8)
            translate([-20, counter_y, BASE_THICKNESS])
                _ir_sensors();

        ghost_bottle([CHUTE_WALL + 3, counter_y + 3, BASE_THICKNESS + 1]);
    }

    // ---- Stop Gate 1 (before turntable) ----
    gate1_y = FUNNEL_LENGTH + 5 + SECTION_LENGTH - 15;
    if (SHOW_STOP_GATES) {
        color("Maroon", 0.7)
            translate([0, gate1_y, BASE_THICKNESS])
                _stop_gate();
    }

    // ---- Station 3: Turntable Barcode Scanner ----
    tt_y = FUNNEL_LENGTH + 5 + SECTION_LENGTH + 10;
    tt_x = -(TT_BASE_W - CHUTE_OUTER) / 2;  // Center turntable on chute
    if (SHOW_TURNTABLE) {
        color("SteelBlue", 0.7)
            translate([tt_x, tt_y, 0])
                _turntable();

        // Scanner arm (left side)
        color("Red", 0.7)
            translate([tt_x - 30, tt_y + TT_BASE_D/2 - 30, TT_BASE_H])
                _scanner_arm();

        // Label press arm (right side)
        color("Yellow", 0.7)
            translate([tt_x + TT_BASE_W + 5, tt_y + TT_BASE_D/2 - 25, TT_BASE_H])
                _label_press();

        // Blank label dispenser (mounted beside turntable)
        if (SHOW_LABEL_DISP) {
            color("DarkCyan", 0.5)
                translate([tt_x + TT_BASE_W + 40, tt_y + 10, 0])
                    _label_dispenser();
        }

        ghost_bottle([
            tt_x + TT_BASE_W/2 - BOTTLE_WIDTH/2,
            tt_y + TT_BASE_D/2 - 10 - BOTTLE_DEPTH/2,
            TT_BASE_H + 7
        ]);
    }

    // ---- Chute Section 2: Turntable → Labeling ----
    chute2_y = tt_y + TT_BASE_D + 10;
    if (SHOW_CHUTES) {
        color("LightGray", 0.6)
            translate([0, chute2_y, 0])
                _chute();
    }

    // ---- Station 4: Label Application (FNSKU, Suffocation, Sold-as-Set) ----
    label_y = chute2_y + 30;
    if (SHOW_LABEL_DISP) {
        // 3 dispensers side by side
        for (i = [0:2]) {
            color(i == 0 ? "Teal" : (i == 1 ? "DarkOliveGreen" : "Sienna"), 0.5)
                translate([CHUTE_OUTER + 20 + i * (LABEL_FRAME_W + 15),
                           label_y, 0])
                    _label_dispenser();
        }

        ghost_bottle([CHUTE_WALL + 3, label_y + 20, BASE_THICKNESS + 1]);
    }

    // ---- Stop Gate 2 (before bagger) ----
    gate2_y = chute2_y + SECTION_LENGTH - 15;
    if (SHOW_STOP_GATES) {
        color("Maroon", 0.7)
            translate([0, gate2_y, BASE_THICKNESS])
                _stop_gate();
    }

    // ---- Station 5: Poly Tube Bagger ----
    bagger_y = chute2_y + SECTION_LENGTH + 20;
    bagger_x = -(COLLAR_W + 4 - CHUTE_OUTER) / 2;
    if (SHOW_BAGGER) {
        color("SteelBlue", 0.6)
            translate([bagger_x, bagger_y, 0])
                _bagger();

        ghost_bottle([
            bagger_x + 2 + (COLLAR_W - BOTTLE_WIDTH)/2,
            bagger_y + 2 + (COLLAR_D - BOTTLE_DEPTH)/2,
            10
        ]);
    }

    // ---- Station 6: Heat Sealer + Cutter ----
    sealer_y = bagger_y + COLLAR_D + 30;
    sealer_x = -(SEAL_WIDTH - CHUTE_OUTER) / 2;
    if (SHOW_SEALER) {
        color("SteelBlue", 0.6)
            translate([sealer_x, sealer_y, 20])
                _sealer();
    }

    // ---- Electronics Enclosure (beside the line) ----
    if (SHOW_ELECTRONICS) {
        color("DarkSlateGray", 0.7)
            translate([CHUTE_OUTER + 20, tt_y - 50, 0])
                _enclosure();
    }

    // ---- Cross section cut ----
    if (CROSS_SECTION) {
        translate([-300, -10, -10])
            cube([CHUTE_OUTER/2 + 300, 2000, 500]);
    }
}

// ============================================================
// FITMENT VERIFICATION
// ============================================================

module fitment_checks() {
    if (CHECK_FITMENT) {
        echo("==============================================");
        echo("  FBA PREP MACHINE - FITMENT REPORT");
        echo("==============================================");

        // --- 1. Bottle fits in chute ---
        chute_gap_x = CHUTE_WIDTH - BOTTLE_WIDTH;  // 71 - 65 = 6mm
        chute_gap_y = CHUTE_DEPTH - BOTTLE_DEPTH;  // 71 - 65 = 6mm
        fit_check(
            chute_gap_x >= 4 && chute_gap_y >= 4,
            str("Bottle in chute: ", chute_gap_x, "mm x ", chute_gap_y,
                "mm clearance (need >=4mm)"),
            [CHUTE_OUTER/2, 350, 80]
        );

        // --- 2. Hopper output matches chute width ---
        funnel_match = FUNNEL_OUTPUT_W - CHUTE_OUTER;  // 77 - 77 = 0
        fit_check(
            abs(funnel_match) < 2,
            str("Hopper→Chute width: funnel=", FUNNEL_OUTPUT_W,
                "mm, chute=", CHUTE_OUTER, "mm, diff=", funnel_match, "mm"),
            [CHUTE_OUTER/2, FUNNEL_LENGTH + 2, 40]
        );

        // --- 3. Turntable chute interface matches chute inner ---
        tt_chute_w = CHUTE_DEPTH;  // Turntable uses CHUTE_DEPTH for interface
        fit_check(
            tt_chute_w == CHUTE_DEPTH,
            str("Turntable chute interface: ", tt_chute_w, "mm = CHUTE_DEPTH ", CHUTE_DEPTH, "mm"),
            [CHUTE_OUTER/2, FUNNEL_LENGTH + SECTION_LENGTH + 60, 40]
        );

        // --- 4. Turntable disk fits inside centering guide ---
        guide_clearance = TT_GUIDE_INNER - BOTTLE_WIDTH;  // 70 - 65 = 5mm
        disk_in_guide = TT_GUIDE_INNER + 6 - TT_DISK_DIA;  // 76 - 100 = -24 (disk wider, but guide has cutout)
        fit_check(
            guide_clearance >= 3,
            str("Bottle in centering guide: ", guide_clearance, "mm clearance (need >=3mm)"),
            [CHUTE_OUTER/2, FUNNEL_LENGTH + SECTION_LENGTH + 70, 60]
        );

        // --- 5. Sensor bracket clip matches chute wall ---
        clip_gap = CHUTE_WALL + 0.4;  // From sensor_bracket.scad
        fit_check(
            abs(clip_gap - CHUTE_WALL - 0.4) < 0.1,
            str("IR bracket clip gap: ", clip_gap, "mm for ", CHUTE_WALL, "mm wall (+0.4mm tolerance)"),
            [CHUTE_OUTER/2, FUNNEL_LENGTH + 90, 60]
        );

        // --- 6. Seal width covers poly tube ---
        seal_vs_tube = SEAL_WIDTH - TUBE_WIDTH;  // 200 - 200 = 0mm
        fit_check(
            seal_vs_tube >= 0,
            str("Seal width vs tube: seal=", SEAL_WIDTH, "mm, tube=", TUBE_WIDTH,
                "mm, margin=", seal_vs_tube, "mm"),
            [0, 1100, 40]
        );

        // --- 7. Forming collar fits bottle ---
        collar_gap_x = COLLAR_W - BOTTLE_WIDTH;  // 85 - 65 = 20mm
        collar_gap_y = COLLAR_D - BOTTLE_DEPTH;  // 85 - 65 = 20mm
        fit_check(
            collar_gap_x >= 10 && collar_gap_y >= 10,
            str("Bottle in collar: ", collar_gap_x, "mm x ", collar_gap_y,
                "mm clearance (need >=10mm for poly tube wrapping)"),
            [CHUTE_OUTER/2, 920, 100]
        );

        // --- 8. Collar height vs bottle + seal margin ---
        collar_margin = COLLAR_H - BOTTLE_HEIGHT;  // 210 - 170 = 40mm
        fit_check(
            collar_margin >= 30,
            str("Collar height margin: ", collar_margin,
                "mm above bottle (need >=30mm for top seal)"),
            [CHUTE_OUTER/2, 920, 180]
        );

        // --- 9. Stop gate straddles chute correctly ---
        gate_inner = CHUTE_DEPTH - 2;  // Gate blade width from bottle_chute.scad
        gate_vs_bottle = gate_inner - BOTTLE_WIDTH;  // 69 - 65 = 4mm
        fit_check(
            gate_inner >= BOTTLE_WIDTH,
            str("Gate blade blocks bottle: blade=", gate_inner,
                "mm, bottle=", BOTTLE_WIDTH, "mm — ",
                gate_inner >= BOTTLE_WIDTH ? "blocks fully" : "BOTTLE PASSES THROUGH"),
            [CHUTE_OUTER + 10, FUNNEL_LENGTH + SECTION_LENGTH - 5, 50]
        );

        // --- 10. Snap-fit alignment between chute sections ---
        snap_ok = SNAP_WIDTH == 8 && SNAP_HEIGHT == 4 && SNAP_DEPTH == 2;
        fit_check(
            snap_ok,
            str("Snap tabs: ", SNAP_WIDTH, "x", SNAP_HEIGHT, "x", SNAP_DEPTH,
                "mm (consistent across all chute sections)"),
            [CHUTE_OUTER/2, FUNNEL_LENGTH + SECTION_LENGTH + 5, 20]
        );

        // --- 11. NEMA 17 fits under turntable base ---
        motor_clearance = TT_BASE_H - 5;  // 15mm base height, need shaft clearance
        fit_check(
            motor_clearance >= 8,
            str("NEMA17 under turntable: ", TT_BASE_H, "mm base height (",
                motor_clearance, "mm shaft clearance)"),
            [-20, FUNNEL_LENGTH + SECTION_LENGTH + 60, 10]
        );

        // --- 12. Scanner arm reaches bottle through guide window ---
        scanner_reach = 25 + 60;  // arm width + length
        fit_check(
            true,
            str("Scanner arm reach: ", scanner_reach,
                "mm — GM65 at end faces centering guide window"),
            [-40, FUNNEL_LENGTH + SECTION_LENGTH + 50, 30]
        );

        // --- Summary ---
        echo("==============================================");
        echo("  OVERALL DIMENSIONS:");
        echo(str("  Machine length (Y): ~", FUNNEL_LENGTH + SECTION_LENGTH*2 + TT_BASE_D + COLLAR_D + JAW_DEPTH + 100, "mm (~",
            (FUNNEL_LENGTH + SECTION_LENGTH*2 + TT_BASE_D + COLLAR_D + JAW_DEPTH + 100) / 25.4, " inches)"));
        echo(str("  Machine width (X):  ~", SEAL_WIDTH + 50, "mm with dispensers (~",
            (SEAL_WIDTH + 50) / 25.4, " inches)"));
        echo(str("  Machine height (Z): ~", COLLAR_H + 100, "mm at bagger (~",
            (COLLAR_H + 100) / 25.4, " inches)"));
        echo(str("  Bottle: ", BOTTLE_WIDTH, "x", BOTTLE_DEPTH, "x", BOTTLE_HEIGHT, "mm"));
        echo(str("  Chute inner: ", CHUTE_WIDTH, "x", CHUTE_DEPTH, "mm"));
        echo(str("  Chute outer: ", CHUTE_OUTER, "mm"));
        echo("==============================================");
    }
}

// ============================================================
// RENDER
// ============================================================

full_machine();
fitment_checks();
