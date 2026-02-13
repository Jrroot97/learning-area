// ============================================================
// FBA PREP MACHINE - 3D PRINT GUIDE & FULL ASSEMBLY
// ============================================================
//
// PRINTER: Any FDM printer with 220x220mm+ bed (Ender 3, etc)
// SLICER:  Cura, PrusaSlicer, or OrcaSlicer
//
// ============================================================
// PRINT SETTINGS PER PART:
// ============================================================
//
// PART                    | MATERIAL | WALLS | INFILL | SUPPORTS | QTY
// ----------------------- | -------- | ----- | ------ | -------- | ---
// bottle_chute section    | PLA/PETG | 3     | 20%    | No       | 4-6
// chute stop_gate         | PETG     | 3     | 30%    | Yes      | 3
// chute gate_blade        | PETG     | 4     | 50%    | No       | 3
// chute riser_block       | PLA      | 3     | 20%    | No       | 4-6
// turntable_base          | PETG     | 4     | 30%    | Yes      | 1
// turntable_disk          | PETG     | 4     | 40%    | No       | 1
// centering_guide         | PLA      | 3     | 20%    | Yes      | 1
// scanner_arm             | PETG     | 4     | 30%    | Yes      | 1
// label_press_arm         | PETG     | 3     | 30%    | Yes      | 1
// peel_bar                | PETG     | 4     | 50%    | No       | 4
// roll_spindle            | PETG     | 4     | 40%    | No       | 4
// takeup_spool            | PETG     | 3     | 30%    | No       | 4
// side_plate              | PETG     | 4     | 30%    | No       | 8
// tension_guide           | PLA      | 3     | 20%    | No       | 4
// label_guide             | PLA      | 3     | 20%    | No       | 4
// lower_jaw               | PETG     | 4     | 50%    | No       | 1
// upper_jaw               | PETG     | 4     | 50%    | No       | 1
// tube_guide              | PLA      | 3     | 20%    | No       | 1
// cutter_bar              | PETG     | 4     | 40%    | No       | 1
// sealer_servo_mount      | PETG     | 3     | 30%    | Yes      | 1
// enclosure_box           | PLA      | 3     | 20%    | Yes      | 1
// enclosure_lid           | PLA      | 3     | 20%    | No       | 1
// ir_emitter_bracket      | PLA      | 3     | 30%    | No       | 2
// ir_receiver_bracket     | PLA      | 3     | 30%    | No       | 2
// funnel_half_left        | PETG     | 3     | 20%    | Yes      | 1
// funnel_half_right       | PETG     | 3     | 20%    | Yes      | 1
// anti_jam_ramp           | PLA      | 3     | 30%    | No       | 1
// chute_adapter           | PLA      | 3     | 20%    | No       | 1
// singulator_gate         | PETG     | 3     | 30%    | Yes      | 1
// singulator_blade        | PETG     | 4     | 50%    | No       | 1
// forming_collar          | PETG     | 3     | 30%    | Yes      | 1
// feed_roller             | PETG     | 4     | 40%    | No       | 2
// roller_mount            | PETG     | 4     | 30%    | Yes      | 2
// pusher_plate            | PETG     | 3     | 30%    | No       | 1
// tube_roll_holder        | PLA      | 3     | 20%    | No       | 1
//
// ============================================================
// ESTIMATED PRINT TIME: ~45-60 hours total
// ESTIMATED FILAMENT: ~1.5 kg PETG + ~0.5 kg PLA
// ============================================================
//
// ASSEMBLY ORDER:
// 1. Print all parts
// 2. Assemble hopper funnel (join halves, add anti-jam ramp)
// 3. Build chute sections (snap together, add riser blocks for slope)
// 4. Install singulator gate at funnel→chute transition
// 5. Build turntable station (mount NEMA17, disk, centering guide)
// 6. Install barcode scanner arm + blank label press arm
// 7. Build 4x label dispensers (FNSKU, suffocation, sold-as-set, blank)
// 8. Assemble poly bagger (roll holder, forming collar, feed roller)
// 9. Build heat sealer (nichrome wire in lower jaw, PTFE tape)
// 10. Install cutter bar after sealer
// 11. Wire up electronics in enclosure
// 12. Mount IR sensor brackets at counting points
// 13. Connect all stop gates to servos
// 14. Test each station individually before running full line
//
// ============================================================
// HOW TO EXPORT STL FROM THIS FILE:
// 1. Open desired .scad file in OpenSCAD
// 2. Uncomment the individual part you want to print
// 3. Comment out the assembly view
// 4. Press F6 (Render) then F7 (Export STL)
// 5. Import STL into your slicer
// ============================================================

use <common.scad>
include <common.scad>
use <bottle_chute.scad>
use <turntable_station.scad>
use <label_dispenser.scad>
use <heat_sealer.scad>
use <electronics_enclosure.scad>
use <sensor_bracket.scad>
use <hopper_funnel.scad>
use <poly_bagger.scad>

// ============================================================
// FULL MACHINE LAYOUT (top-down view)
// ============================================================
//
//   [HOPPER] → [SINGULATOR] → [COUNTER] → [TURNTABLE/BARCODE]
//                                              ↓
//   [OUTPUT] ← [CUTTER] ← [SEALER] ← [BAGGER] ← [LABELS x3]
//
// Total machine footprint: ~1.2m x 0.5m
// ============================================================

// Full machine preview (uncomment to see entire layout)
// WARNING: This is complex and may be slow to render

module full_machine() {
    station_spacing = 300;

    // Station 1: Hopper + Singulator
    translate([0, 0, 0])
        hopper_assembly();

    // Station 2: Bottle Counter (IR sensors on chute)
    translate([0, 300, 0]) {
        // Chute section
        chute_section();
        // Sensors clipped on
        translate([30, 0, 0])
            sensor_assembly();
    }

    // Station 3: Turntable Barcode Scanner
    translate([0, 550, 0])
        turntable_assembly();

    // Station 4: Label Dispensers (blank cover applied at turntable)
    // FNSKU, suffocation, sold-as-set applied here
    translate([200, 550, 0])
        dispenser_assembly();
    translate([200, 700, 0])
        dispenser_assembly();
    translate([200, 850, 0])
        dispenser_assembly();

    // Station 5: Poly Bagger
    translate([0, 900, 0])
        bagger_assembly();

    // Station 6: Heat Sealer + Cutter
    translate([0, 1100, 0])
        sealer_assembly();

    // Electronics (mounted to side)
    translate([300, 400, 0])
        enclosure_assembly();
}

// Uncomment to preview full machine:
// full_machine();

// Default: show the print guide text
echo("=== FBA Prep Machine 3D Print Files ===");
echo("See comments above for print settings and assembly order");
echo("Open individual .scad files to export STL parts");
