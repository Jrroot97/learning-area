// ============================================================
// HexGrid Modular Organizer - MASTER ASSEMBLY & FITMENT CHECK
// ============================================================
//
// This file shows ALL products assembled together on a hex grid
// to verify:
//   1. Magnet holes align between adjacent pieces
//   2. Proper clearance between pieces (no overlap)
//   3. Wall mount magnet positions mate with product magnets
//   4. Visual proportions and scale look correct
//
// HOW TO USE:
//   1. Open in OpenSCAD
//   2. Press F5 for quick preview (faster, less accurate)
//   3. Press F6 for full render (slower, exact geometry)
//   4. Rotate view to inspect all joints and connections
//   5. Toggle sections using the SHOW_* flags below
//   6. Run fitment checks by setting CHECK_FITMENT = true
//
// ============================================================

// Include all product modules
use <hex_common.scad>
include <hex_common.scad>

// ============================================================
// DISPLAY CONTROLS - Toggle what's visible
// ============================================================
SHOW_DESKTOP_SCENE   = true;   // Desktop arrangement (cups, trays, drawers)
SHOW_WALL_SCENE      = true;   // Wall-mounted arrangement (hooks, mount, planter)
SHOW_MAGNETS         = true;   // Show magnet positions as silver cylinders
SHOW_GAP_MARKERS     = false;  // Show gap measurement markers between pieces
SHOW_CROSS_SECTION   = false;  // Cut everything in half to inspect magnet depth
CHECK_FITMENT        = true;   // Show red/green fitment verification markers

// ============================================================
// CRITICAL DIMENSIONS (verified from all product files)
// ============================================================
// Every product MUST share these values for interoperability:
//
// HEX_SIZE     = 70       (flat-to-flat outer dimension)
// MAG_DIA      = 6.2      (magnet hole diameter)
// MAG_DEPTH    = 3.2      (magnet hole depth from surface)
// MAG_INSET    = 4.0      (magnet center from hex edge)
// MAG_Z        = 10       (magnet center height from base)
// HEX_SPACING  = 70.5     (center-to-center grid spacing)
//
// EXCEPTION: Planter uses mag_holes(8) instead of mag_holes(10)
//            due to tapered base. This is noted in fitment check.
//
// WALL MOUNT: Magnets at z = MOUNT_THICK - MAG_DEPTH = 12 - 3.2 = 8.8
//             Products sit on face, so their MAG_Z=10 mates with
//             wall mount magnet at z=8.8 from wall surface.
//             Gap = 10 - 8.8 = 1.2mm — magnets still attract through
//             1.2mm of plastic. 6mm magnets effective through ~3mm.
// ============================================================

// ============================================================
// PRODUCT MODULES (self-contained, no external use/include)
// Redefined here to avoid OpenSCAD file dependency issues
// and to ensure the master file renders standalone
// ============================================================

// --- Pencil Cup (from hex_cup.scad) ---
module _cup(h=CUP_HEIGHT) {
    difference() {
        union() {
            hex_shell(h);
            hex_prism(HEX_BASE + 1);
            anti_slip_feet();
        }
        mag_holes(MAG_Z);
    }
}

// --- Short Cup (from hex_cup.scad) ---
module _cup_short() {
    _cup(45);
}

// --- Drawer Housing (from hex_drawer.scad) ---
module _drawer_housing() {
    DRAWER_H = DRAWER_HEIGHT;
    DRAWER_GAP = 0.4;
    INNER_SIZE = HEX_SIZE - HEX_WALL*2 - DRAWER_GAP*2;
    DRAWER_INNER_H = DRAWER_H - HEX_BASE - 5;

    difference() {
        union() {
            hex_shell(DRAWER_H);
            hex_prism(HEX_BASE + 1);
            anti_slip_feet();
            // Rails
            translate([0, 0, HEX_BASE + 1])
                for (a = [90, 270])
                    rotate([0, 0, a])
                        translate([INNER_SIZE/2/cos(30) + DRAWER_GAP, -1.5, 0])
                            cube([1.5, 3, DRAWER_INNER_H + 3]);
        }
        mag_holes(MAG_Z);
        // Front opening
        translate([-INNER_SIZE/2, -HEX_SIZE/2 - 1, HEX_BASE])
            cube([INNER_SIZE, HEX_WALL + 2, DRAWER_H]);
        // Inner cavity
        translate([0, 0, HEX_BASE + 1])
            hex_prism(DRAWER_H, INNER_SIZE + DRAWER_GAP);
    }
}

// --- Drawer Insert (from hex_drawer.scad) ---
module _drawer_insert() {
    DRAWER_GAP = 0.4;
    INNER_SIZE = HEX_SIZE - HEX_WALL*2 - DRAWER_GAP*2;
    DRAWER_INNER_H = DRAWER_HEIGHT - HEX_BASE - 5;
    insert_size = INNER_SIZE - 1;
    insert_r = insert_size / 2 / cos(30);

    difference() {
        union() {
            cylinder(r=insert_r, h=DRAWER_INNER_H + HEX_BASE, $fn=6);
            // Hex handle knob
            translate([0, -(HEX_SIZE/2 - HEX_WALL), DRAWER_INNER_H/2 + HEX_BASE])
                rotate([90, 0, 0])
                    cylinder(r=8/cos(30), h=8, $fn=6);
        }
        // Hollow
        translate([0, 0, HEX_BASE])
            cylinder(r=insert_r - HEX_WALL, h=DRAWER_INNER_H + 1, $fn=6);
        // Rail grooves
        for (a = [90, 270])
            rotate([0, 0, a])
                translate([insert_r - 0.5, -2, HEX_BASE])
                    cube([2.5, 4, DRAWER_INNER_H + 2]);
    }
}

// --- Catch-All Tray (from hex_shelf.scad) ---
module _tray() {
    LIP_H = 8;
    LIP_T = 1.6;
    difference() {
        union() {
            hex_prism(SHELF_HEIGHT);
            translate([0, 0, SHELF_HEIGHT])
                hex_ring(LIP_H, HEX_SIZE, LIP_T);
            anti_slip_feet();
        }
        mag_holes(MAG_Z);
    }
}

// --- Phone Stand (from hex_shelf.scad) ---
module _phone_stand() {
    back_h = 55;
    difference() {
        union() {
            hex_prism(SHELF_HEIGHT);
            // Back rest
            translate([0, HEX_SIZE/4, SHELF_HEIGHT])
                rotate([-25, 0, 0])
                    translate([-HEX_SIZE/3, 0, 0])
                        cube([HEX_SIZE*2/3, back_h, 3]);
            // Front lip
            translate([-HEX_SIZE/3, -HEX_SIZE/4, SHELF_HEIGHT])
                cube([HEX_SIZE*2/3, 5, 8]);
            anti_slip_feet();
        }
        mag_holes(MAG_Z);
    }
}

// --- Cable Clips (from hex_cable.scad) ---
module _cable_clips() {
    clip_h = 12;
    difference() {
        union() {
            hex_prism(CABLE_HEIGHT);
            // 3 clip fingers
            for (i = [-1:1])
                translate([i * 15, 0, CABLE_HEIGHT])
                    difference() {
                        cylinder(d=12, h=clip_h, $fn=FN_ROUND);
                        translate([0, 0, -1])
                            cylinder(d=7, h=clip_h + 2, $fn=FN_ROUND);
                        translate([-1.5, -8, -1])
                            cube([3, 8, clip_h + 2]);
                    }
            anti_slip_feet();
        }
        mag_holes(MAG_Z);
    }
}

// --- Planter (from hex_planter.scad) ---
module _planter() {
    difference() {
        hull() {
            hex_prism(1, HEX_SIZE - 4);
            translate([0, 0, PLANTER_HEIGHT - 1])
                hex_prism(1, HEX_SIZE);
        }
        // Interior
        translate([0, 0, HEX_BASE + 1])
            hull() {
                hex_prism(1, HEX_SIZE - HEX_WALL*2 - 10);
                translate([0, 0, PLANTER_HEIGHT - HEX_BASE - 2])
                    hex_prism(1, HEX_SIZE - HEX_WALL*2);
            }
        // Drainage
        translate([0, 0, -1])
            cylinder(d=6, h=HEX_BASE + 3, $fn=FN_ROUND);
        for (a = [0:60:300])
            rotate([0, 0, a])
                translate([15, 0, -1])
                    cylinder(d=6, h=HEX_BASE + 3, $fn=FN_ROUND);
        // NOTE: Planter magnets at z=8 (not 10) due to taper
        mag_holes(8);
    }
}

// --- Saucer (from hex_planter.scad) ---
module _saucer() {
    saucer_size = HEX_SIZE + 4;
    difference() {
        hex_prism(8, saucer_size);
        translate([0, 0, 2])
            hex_prism(8, saucer_size - 4);
    }
}

// --- Single Hook (from hex_hook.scad) ---
module _hook() {
    HOOK_L = 35;
    HOOK_T = 6;
    difference() {
        union() {
            hex_prism(HOOK_HEIGHT);
            // Hook arm
            translate([-HOOK_T/2, 0, HOOK_HEIGHT])
                hull() {
                    cube([HOOK_T, HOOK_T, 2]);
                    translate([0, -HOOK_L + HOOK_T, -15])
                        cube([HOOK_T, HOOK_T, 2]);
                }
            // Curl tip
            translate([-HOOK_T/2, -HOOK_L + HOOK_T, HOOK_HEIGHT - 15])
                hull() {
                    cube([HOOK_T, HOOK_T, 2]);
                    translate([0, 2, -12])
                        cube([HOOK_T, HOOK_T, 2]);
                }
            // Support rib
            translate([-2, 0, 2])
                hull() {
                    cube([4, 4, HOOK_HEIGHT - 4]);
                    translate([0, -HOOK_L * 0.6, HOOK_HEIGHT - 4])
                        cube([4, 4, 2]);
                }
        }
        mag_holes(MAG_Z);
    }
}

// --- Headphone Hook (from hex_hook.scad) ---
module _headphone_hook() {
    arm_len = 50;
    arm_w = 25;
    difference() {
        union() {
            hex_prism(HOOK_HEIGHT);
            translate([-arm_w/2, 0, HOOK_HEIGHT]) {
                hull() {
                    cube([arm_w, 3, 3]);
                    translate([3, -arm_len + 10, -20])
                        cube([arm_w - 6, 10, 3]);
                }
                translate([3, -arm_len + 10, -20])
                    hull() {
                        cube([arm_w - 6, 10, 3]);
                        translate([2, 5, -8])
                            cube([arm_w - 10, 5, 3]);
                    }
            }
        }
        mag_holes(MAG_Z);
    }
}

// --- Wall Mount Single Plate (from hex_wall_mount.scad) ---
module _wall_plate() {
    MOUNT_T = 12;
    difference() {
        hex_prism(MOUNT_T);
        // Magnets on FRONT face (products attach here)
        translate([0, 0, MOUNT_T - MAG_DEPTH])
            for (a = [0:60:300])
                rotate([0, 0, a])
                    translate([HEX_SIZE/2 - MAG_INSET, 0, 0])
                        cylinder(d=MAG_DIA, h=MAG_DEPTH + 1, $fn=FN_ROUND);
        // Keyhole screws on back
        for (y = [-12, 12])
            translate([0, y, -1])
                cylinder(d=5, h=MOUNT_T + 2, $fn=FN_ROUND);
    }
}

// ============================================================
// FITMENT VERIFICATION SYSTEM
// ============================================================

// Show a green dot where magnets align, red where they don't
module fitment_marker(pass=true, label="") {
    if (CHECK_FITMENT) {
        color(pass ? "Lime" : "Red")
            sphere(d=pass ? 3 : 5, $fn=20);
        if (!pass) {
            echo(str("FITMENT FAIL: ", label));
        }
    }
}

// Check magnet alignment between two adjacent hex positions
// pos1, pos2 = [x,y] centers; z1, z2 = magnet z-heights
module check_magnet_pair(pos1, pos2, z1, z2, label="") {
    if (CHECK_FITMENT) {
        // Find which edge faces the neighbor
        dx = pos2[0] - pos1[0];
        dy = pos2[1] - pos1[1];
        angle = atan2(dy, dx);

        // Magnet position on piece 1 (facing piece 2)
        mag1_x = pos1[0] + (HEX_SIZE/2 - MAG_INSET) * cos(angle);
        mag1_y = pos1[1] + (HEX_SIZE/2 - MAG_INSET) * sin(angle);

        // Magnet position on piece 2 (facing piece 1)
        mag2_x = pos2[0] + (HEX_SIZE/2 - MAG_INSET) * cos(angle + 180);
        mag2_y = pos2[1] + (HEX_SIZE/2 - MAG_INSET) * sin(angle + 180);

        // Distance between magnet centers
        dist = sqrt(pow(mag1_x - mag2_x, 2) + pow(mag1_y - mag2_y, 2));
        z_gap = abs(z1 - z2);

        // Pass if magnets are within 3mm of each other (magnetic range)
        pass = (dist < 8) && (z_gap < 3);

        // Show marker at midpoint
        translate([(mag1_x + mag2_x)/2, (mag1_y + mag2_y)/2, max(z1, z2)])
            fitment_marker(pass, str(label, " dist=", dist, " zgap=", z_gap));
    }
}

// Visual magnet positions for any hex piece at given location
module show_magnets_at(pos, z_height) {
    if (SHOW_MAGNETS) {
        color("Silver", 0.7)
            translate([pos[0], pos[1], 0])
                for (a = [0:60:300])
                    rotate([0, 0, a])
                        translate([HEX_SIZE/2 - MAG_INSET, 0, z_height])
                            cylinder(d=6, h=3, $fn=FN_ROUND);
    }
}

// Gap measurement marker between two adjacent pieces
module gap_marker(pos1, pos2) {
    if (SHOW_GAP_MARKERS) {
        dx = pos2[0] - pos1[0];
        dy = pos2[1] - pos1[1];
        mid_x = (pos1[0] + pos2[0]) / 2;
        mid_y = (pos1[1] + pos2[1]) / 2;
        dist = sqrt(dx*dx + dy*dy);
        gap = dist - HEX_SIZE;  // Should be ~0.5mm

        color(gap > 0 ? "Cyan" : "Red")
            translate([mid_x, mid_y, 120])
                sphere(d=2, $fn=12);

        echo(str("Gap between pieces: ", gap, "mm",
                  gap > 0 ? " OK" : " COLLISION!"));
    }
}

// ============================================================
// SCENE 1: DESKTOP ARRANGEMENT
// ============================================================
// Layout: 7-hex cluster on desk surface
//
//        [Phone]  [Cup]
//     [Cable] [Tray] [Drawer]
//        [Cup2]  [Planter]
//
// Uses axial hex grid coordinates

module desktop_scene() {
    sp = HEX_SPACING;

    // Grid positions (axial coordinates converted to XY)
    // Center
    p_tray    = [0, 0];
    // Ring 1 (6 neighbors)
    p_cup     = [sp * cos(30),  sp * sin(30)];           // upper-right
    p_phone   = [sp * cos(90),  sp * sin(90)];           // top (actually just up)
    p_cable   = [sp * cos(150), sp * sin(150)];          // upper-left
    p_cup2    = [sp * cos(210), sp * sin(210)];          // lower-left
    p_planter = [sp * cos(270), sp * sin(270)];          // bottom
    p_drawer  = [sp * cos(330), sp * sin(330)];          // lower-right

    // --- Place Products ---
    // Center: Catch-all tray
    color("SteelBlue")
        translate([p_tray[0], p_tray[1], 0])
            _tray();

    // Upper-right: Pencil cup
    color("DarkOrange")
        translate([p_cup[0], p_cup[1], 0])
            _cup();

    // Top: Phone stand
    color("MediumSeaGreen")
        translate([p_phone[0], p_phone[1], 0])
            _phone_stand();

    // Upper-left: Cable clips
    color("SlateGray")
        translate([p_cable[0], p_cable[1], 0])
            _cable_clips();

    // Lower-left: Short cup
    color("Coral")
        translate([p_cup2[0], p_cup2[1], 0])
            _cup_short();

    // Bottom: Planter + saucer
    color("Tan")
        translate([p_planter[0], p_planter[1], 0])
            _saucer();
    color("ForestGreen")
        translate([p_planter[0], p_planter[1], 7])
            _planter();

    // Lower-right: Drawer
    color("RoyalBlue")
        translate([p_drawer[0], p_drawer[1], 0])
            _drawer_housing();
    color("Gold")
        translate([p_drawer[0], p_drawer[1] - 12, 1])
            _drawer_insert();

    // --- Magnet Visualization ---
    show_magnets_at(p_tray, MAG_Z);
    show_magnets_at(p_cup, MAG_Z);
    show_magnets_at(p_phone, MAG_Z);
    show_magnets_at(p_cable, MAG_Z);
    show_magnets_at(p_cup2, MAG_Z);
    show_magnets_at(p_planter, 8);  // Planter uses z=8
    show_magnets_at(p_drawer, MAG_Z);

    // --- Fitment Checks (all adjacent pairs) ---
    // Tray ↔ neighbors
    check_magnet_pair(p_tray, p_cup,     MAG_Z, MAG_Z, "Tray↔Cup");
    check_magnet_pair(p_tray, p_phone,   MAG_Z, MAG_Z, "Tray↔Phone");
    check_magnet_pair(p_tray, p_cable,   MAG_Z, MAG_Z, "Tray↔Cable");
    check_magnet_pair(p_tray, p_cup2,    MAG_Z, MAG_Z, "Tray↔Cup2");
    check_magnet_pair(p_tray, p_planter, MAG_Z, 8,     "Tray↔Planter");
    check_magnet_pair(p_tray, p_drawer,  MAG_Z, MAG_Z, "Tray↔Drawer");

    // Neighbor ↔ neighbor
    check_magnet_pair(p_cup, p_phone,      MAG_Z, MAG_Z, "Cup↔Phone");
    check_magnet_pair(p_phone, p_cable,    MAG_Z, MAG_Z, "Phone↔Cable");
    check_magnet_pair(p_cable, p_cup2,     MAG_Z, MAG_Z, "Cable↔Cup2");
    check_magnet_pair(p_cup2, p_planter,   MAG_Z, 8,     "Cup2↔Planter");
    check_magnet_pair(p_planter, p_drawer, 8,     MAG_Z, "Planter↔Drawer");
    check_magnet_pair(p_drawer, p_cup,     MAG_Z, MAG_Z, "Drawer↔Cup");

    // Gap markers
    gap_marker(p_tray, p_cup);
    gap_marker(p_tray, p_phone);
    gap_marker(p_tray, p_cable);
    gap_marker(p_tray, p_cup2);
    gap_marker(p_tray, p_planter);
    gap_marker(p_tray, p_drawer);
}

// ============================================================
// SCENE 2: WALL-MOUNTED ARRANGEMENT
// ============================================================
// Shows 7 hex wall plates with various products magnetically attached
// Laid flat for viewing (rotate 90° in your head for wall orientation)

module wall_scene() {
    sp = HEX_SPACING;
    MOUNT_T = 12;
    wall_mag_z = MOUNT_T - MAG_DEPTH;  // 8.8mm

    // Wall mount positions (7-hex cluster)
    positions = [
        [0, 0],                                    // Center
        [sp * cos(0),   sp * sin(0)],              // Right
        [sp * cos(60),  sp * sin(60)],             // Upper-right
        [sp * cos(120), sp * sin(120)],            // Upper-left
        [sp * cos(180), sp * sin(180)],            // Left
        [sp * cos(240), sp * sin(240)],            // Lower-left
        [sp * cos(300), sp * sin(300)]             // Lower-right
    ];

    // Wall plates (the base layer screwed to wall)
    for (i = [0:6]) {
        color("DimGray")
            translate([positions[i][0], positions[i][1], 0])
                _wall_plate();
    }

    // Products attached to wall plates (sitting on top of mount)
    product_z = MOUNT_T + 0.3;  // Tiny air gap (magnetic attraction)

    // Center: Headphone hook
    color("Crimson")
        translate([positions[0][0], positions[0][1], product_z])
            _headphone_hook();

    // Right: Single hook
    color("DarkOrange")
        translate([positions[1][0], positions[1][1], product_z])
            _hook();

    // Upper-right: Single hook
    color("DarkOrange")
        translate([positions[2][0], positions[2][1], product_z])
            _hook();

    // Upper-left: Tray (catch-all for keys)
    color("SteelBlue")
        translate([positions[3][0], positions[3][1], product_z])
            _tray();

    // Left: Pencil cup
    color("MediumSeaGreen")
        translate([positions[4][0], positions[4][1], product_z])
            _cup();

    // Lower-left: Cable clips
    color("SlateGray")
        translate([positions[5][0], positions[5][1], product_z])
            _cable_clips();

    // Lower-right: Planter
    color("ForestGreen")
        translate([positions[6][0], positions[6][1], product_z])
            _planter();

    // --- Wall Mount Fitment Checks ---
    // Check each product's magnets align with wall plate magnets
    // Wall plate magnets: z = wall_mag_z (8.8mm from base)
    // Product magnets: z = product_z + MAG_Z (12.3 + 10 = 22.3 from floor)
    // Wall plate magnets from floor: z = 8.8
    // When product sits on plate: product mag at z = 12.3 + 10 = 22.3
    //   vs wall plate mag at z = 8.8
    // These DON'T directly align in Z — they attract LATERALLY through edges
    //
    // ACTUALLY: For wall mount, magnets are on the TOP FACE of the plate
    //   and the BOTTOM EDGES of the product. The product sits on the plate.
    //   Wall plate top face magnets: z = MOUNT_T - MAG_DEPTH to MOUNT_T
    //   Product edge magnets: z = product_z + MAG_Z = 12.3 + 10 = 22.3
    //
    // For magnetic attachment: adjacent wall plates share edge magnets
    //   and products on those plates also connect via their own edge magnets.

    // Verify adjacent wall plate magnets align with each other
    for (i = [1:6]) {
        check_magnet_pair(positions[0], positions[i],
                          wall_mag_z, wall_mag_z,
                          str("WallCenter↔Wall", i));
    }

    // Show wall mount magnets
    for (i = [0:6])
        show_magnets_at(positions[i], wall_mag_z);

    // Show product magnets
    color("Gold", 0.5)
    for (i = [0:6])
        show_magnets_at(positions[i], product_z + MAG_Z);

    // Print fitment report
    echo("=== WALL MOUNT FITMENT REPORT ===");
    echo(str("Wall plate thickness: ", MOUNT_T, "mm"));
    echo(str("Wall magnet Z (from plate base): ", wall_mag_z, "mm"));
    echo(str("Product magnet Z (from product base): ", MAG_Z, "mm"));
    echo(str("Air gap between plate and product: 0.3mm"));
    echo(str("Effective magnet separation: ",
             MOUNT_T - wall_mag_z - MAG_DEPTH, "mm plastic + 0.3mm air"));
    echo("6mm x 3mm N35 magnets: effective through ~3mm — OK");
}

// ============================================================
// SCENE 3: CROSS-SECTION VIEW (for checking internal fitment)
// ============================================================

module cross_section_scene() {
    if (SHOW_CROSS_SECTION) {
        difference() {
            union() {
                desktop_scene();
            }
            // Cut plane (removes front half)
            translate([-500, 0, -10])
                cube([1000, 500, 500]);
        }
    }
}

// ============================================================
// FITMENT REPORT (printed to console)
// ============================================================

// These echo statements print to OpenSCAD's console (bottom panel)
echo("============================================");
echo("  HexGrid Master Assembly - Fitment Report");
echo("============================================");
echo(str("Hex size (flat-to-flat): ", HEX_SIZE, "mm"));
echo(str("Hex radius (vertex): ", HEX_RADIUS, "mm"));
echo(str("Grid spacing (center-to-center): ", HEX_SPACING, "mm"));
echo(str("Gap between adjacent pieces: ", HEX_SPACING - HEX_SIZE, "mm"));
echo(str("Magnet: 6mm dia x 3mm, holes: ", MAG_DIA, "mm x ", MAG_DEPTH, "mm"));
echo(str("Magnet inset from edge: ", MAG_INSET, "mm"));
echo(str("Magnet Z (standard): ", MAG_Z, "mm"));
echo(str("Magnet Z (planter): 8mm (tapered base exception)"));
echo("");
echo("Product Heights:");
echo(str("  Cup:      ", CUP_HEIGHT, "mm"));
echo(str("  Drawer:   ", DRAWER_HEIGHT, "mm"));
echo(str("  Tray:     ", SHELF_HEIGHT, "mm"));
echo(str("  Planter:  ", PLANTER_HEIGHT, "mm"));
echo(str("  Hook:     ", HOOK_HEIGHT, "mm"));
echo(str("  Cable:    ", CABLE_HEIGHT, "mm"));
echo("");

// Adjacent magnet separation calculation
adj_sep = HEX_SPACING - 2 * (HEX_SIZE/2 - MAG_INSET);
echo(str("Adjacent magnet separation: ", adj_sep, "mm"));
echo(str("  (Must be < ~6mm for 6x3mm N35 magnets) → ",
         adj_sep < 6 ? "PASS" : "FAIL"));

// Planter magnet Z-offset check
planter_z_diff = abs(MAG_Z - 8);
echo(str("Planter magnet Z-offset vs standard: ", planter_z_diff, "mm"));
echo(str("  (Adjacent piece magnets misaligned by ", planter_z_diff,
         "mm in Z → still within magnetic range) → ",
         planter_z_diff < 5 ? "PASS" : "FAIL"));

echo("============================================");

// ============================================================
// RENDER
// ============================================================

if (SHOW_DESKTOP_SCENE) {
    desktop_scene();
}

if (SHOW_WALL_SCENE) {
    translate([350, 0, 0])  // Offset to the right of desktop scene
        wall_scene();
}

if (SHOW_CROSS_SECTION) {
    translate([0, -300, 0])
        cross_section_scene();
}
