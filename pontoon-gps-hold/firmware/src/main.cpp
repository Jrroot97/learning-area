#include <Arduino.h>
#include "config.h"
#include "motor_control.h"
#include "gps_module.h"
#include "imu_module.h"
#include "pid_controller.h"
#include "wind_sensor.h"
#include "sensors.h"
#include "web_dashboard.h"

// ============================================================
// GPS Spot-Lock Trolling Motor — Main Control Loop
// Single 12V motor + steering servo on a jon boat
// ============================================================

// -- Modules --
MotorControl motor;
GpsModule gps;
ImuModule imu;
WindSensor wind;
Sensors sensors;
WebDashboard dashboard;

// -- PID Controllers --
// Position PID: outputs desired thrust magnitude (0 to 1.0)
PidController posPid(POS_KP, POS_KI, POS_KD, POS_DEADBAND, THRUST_MAX, POS_MAX_ERROR);
// Heading PID: outputs steering correction (-1.0 to +1.0)
PidController hdgPid(HDG_KP, HDG_KI, HDG_KD, HDG_DEADBAND, 1.0, HDG_MAX_ERROR);

// -- Wave prediction from RPi (optional) --
struct WavePrediction {
    float dx_predicted;     // Predicted displacement X (meters)
    float dy_predicted;     // Predicted displacement Y (meters)
    float confidence;       // 0.0 to 1.0
    unsigned long timestamp;
};
WavePrediction wavePred = {};

// -- Timing --
unsigned long lastControlLoop = 0;
unsigned long lastWatchdog = 0;

// -- System state --
enum SystemMode {
    MODE_IDLE,          // Motors off, monitoring only
    MODE_SPOT_LOCK,     // Holding position (anchor set)
    MODE_NAVIGATE       // Moving to a saved spot
};
SystemMode mode = MODE_IDLE;

// ============================================================
// Safety Supervisor — runs every cycle regardless of mode
// ============================================================
bool safetyCheck() {
    // Battery critical — shut down
    BatteryStatus batt = sensors.getBattery();
    if (batt.critical) {
        Serial.println("[SAFETY] Battery critical — shutting down motors");
        motor.emergencyStop();
        sensors.buzzerAlert(1000);
        return false;
    }

    // Tilt detection
    if (imu.isTilted()) {
        Serial.println("[SAFETY] Excessive tilt detected — emergency stop");
        motor.emergencyStop();
        return false;
    }

    // Excessive drift (GPS may have lost fix, or something is very wrong)
    if (gps.isAnchored() && gps.hasFix()) {
        AnchorError err = gps.getAnchorError();
        if (err.distance_m > MAX_DRIFT_METERS) {
            Serial.printf("[SAFETY] Drift %.1fm exceeds limit — stopping\n", err.distance_m);
            motor.emergencyStop();
            return false;
        }
    }

    // Watchdog — ensure control loop is running
    if (millis() - lastWatchdog > WATCHDOG_TIMEOUT_MS) {
        Serial.println("[SAFETY] Watchdog timeout — emergency stop");
        motor.emergencyStop();
        return false;
    }

    return true;
}

// ============================================================
// Read wave prediction from RPi (UART)
// ============================================================
void readWavePrediction() {
    if (!ENABLE_WAVE_PREDICTION) return;

    // RPi sends JSON: {"dx":0.1,"dy":-0.05,"conf":0.8}
    static String rpiBuffer = "";

    while (Serial2.available() > 0) {
        // Note: RPi uses a separate UART — would need SoftwareSerial
        // or reassign Serial2 if GPS uses it. For now, placeholder.
    }
}

// ============================================================
// Spot-Lock Control — the main hold algorithm
// ============================================================
void runSpotLock(float dt) {
    if (!gps.hasFix() || !gps.isAnchored()) return;

    AnchorError posErr = gps.getAnchorError();
    float heading = imu.getHeading();

    // -- Step 1: Calculate desired thrust from GPS position error --
    float thrustMagnitude = posPid.compute(posErr.distance_m, dt);

    // -- Step 2: Calculate desired motor direction --
    // Point the motor toward the anchor point
    float desiredAngle = posErr.bearing_deg;

    // -- Step 3: Add wind feedforward --
    if (ENABLE_WIND_SENSOR && wind.isValid()) {
        WindForce windForce = wind.getForceRelativeToHeading(heading);

        // Add wind counter-thrust
        thrustMagnitude += wind.getCounterThrust();

        // Blend motor angle between GPS correction and wind compensation
        // Weight: more wind = more wind influence, less drift = less GPS influence
        float windWeight = constrain(windForce.force_magnitude * 2.0f, 0.0f, 0.6f);
        float gpsWeight = 1.0f - windWeight;

        if (posErr.distance_m < POS_DEADBAND) {
            // In deadband — point purely into wind
            desiredAngle = wind.getCounterAngle(heading);
        } else {
            // Blend GPS correction with wind compensation
            // Simple weighted blend (not perfect for angle wrapping but functional)
            float windAngle = wind.getCounterAngle(heading);
            desiredAngle = desiredAngle * gpsWeight + windAngle * windWeight;
        }
    }

    // -- Step 4: Add wave prediction feedforward --
    if (ENABLE_WAVE_PREDICTION && wavePred.confidence > WAVE_CONFIDENCE_MIN) {
        unsigned long age = millis() - wavePred.timestamp;
        if (age < 2000) {  // Only use predictions < 2 sec old
            float waveMagnitude = sqrt(wavePred.dx_predicted * wavePred.dx_predicted +
                                       wavePred.dy_predicted * wavePred.dy_predicted);
            thrustMagnitude += waveMagnitude * WAVE_FF_GAIN * wavePred.confidence;
        }
    }

    // -- Step 5: Heading hold (if locked) --
    if (imu.isHeadingLocked()) {
        float headingErr = imu.getHeadingError();
        float hdgCorrection = hdgPid.compute(headingErr, dt);
        // Blend heading correction into the steering angle
        desiredAngle += hdgCorrection * 30.0f;  // Scale to degrees
    }

    // -- Step 6: Clamp and apply --
    thrustMagnitude = constrain(thrustMagnitude, 0.0f, THRUST_MAX);

    // Normalize angle to 0-360
    desiredAngle = fmod(desiredAngle + 360.0f, 360.0f);

    motor.setSteeringAngle(desiredAngle);
    motor.setThrust(thrustMagnitude);
}

// ============================================================
// Dashboard command callbacks
// ============================================================
void onAnchorDrop() {
    gps.setAnchor();
    imu.setHeadingLock();
    posPid.reset();
    hdgPid.reset();
    mode = MODE_SPOT_LOCK;
    Serial.println("[MAIN] Spot-lock engaged");
}

void onAnchorClear() {
    gps.clearAnchor();
    imu.clearHeadingLock();
    motor.stopAll();
    mode = MODE_IDLE;
    Serial.println("[MAIN] Spot-lock released");
}

void onHeadingLock() {
    imu.setHeadingLock();
    hdgPid.reset();
    Serial.println("[MAIN] Heading locked");
}

void onHeadingClear() {
    imu.clearHeadingLock();
    Serial.println("[MAIN] Heading unlocked");
}

void onEmergencyStop() {
    motor.emergencyStop();
    gps.clearAnchor();
    imu.clearHeadingLock();
    mode = MODE_IDLE;
    Serial.println("[MAIN] Emergency stop — all systems halted");
}

void onSaveSpot(const char* name) {
    gps.saveSpot(name);
}

// ============================================================
// Setup
// ============================================================
void setup() {
    Serial.begin(115200);
    Serial.println("\n========================================");
    Serial.println("  GPS Spot-Lock Trolling Motor v1.0");
    Serial.println("  Single 12V Motor — Jon Boat Edition");
    Serial.println("========================================\n");

    motor.begin();
    gps.begin();

    if (!imu.begin()) {
        Serial.println("[WARN] IMU failed — heading hold disabled");
    }

    if (ENABLE_WIND_SENSOR) wind.begin();
    sensors.begin();

    if (ENABLE_DASHBOARD) {
        dashboard.begin();
        dashboard.onAnchor(onAnchorDrop);
        dashboard.onClearAnchor(onAnchorClear);
        dashboard.onHeadingLock(onHeadingLock);
        dashboard.onClearHeadingLock(onHeadingClear);
        dashboard.onStop(onEmergencyStop);
        dashboard.onSaveSpot(onSaveSpot);
    }

    lastWatchdog = millis();
    Serial.println("\n[MAIN] System ready. Connect to WiFi: " WIFI_SSID);
    Serial.printf("[MAIN] Dashboard: http://%s\n", WiFi.softAPIP().toString().c_str());
}

// ============================================================
// Main Loop
// ============================================================
void loop() {
    unsigned long now = millis();
    unsigned long controlInterval = 1000 / CONTROL_LOOP_HZ;

    // Update sensors every loop pass (they self-throttle internally)
    gps.update();
    imu.update();
    if (ENABLE_WIND_SENSOR) wind.update();
    sensors.update();
    readWavePrediction();

    // Control loop at fixed rate
    if (now - lastControlLoop >= controlInterval) {
        float dt = (now - lastControlLoop) / 1000.0f;
        lastControlLoop = now;
        lastWatchdog = now;  // Feed watchdog

        // Safety first — always
        if (!safetyCheck()) {
            mode = MODE_IDLE;
            return;
        }

        // Battery warning
        BatteryStatus batt = sensors.getBattery();
        if (batt.low && !batt.critical) {
            static unsigned long lastWarn = 0;
            if (now - lastWarn > 30000) {
                sensors.buzzerAlert(100);
                Serial.printf("[WARN] Low battery: %.1fV\n", batt.voltage);
                lastWarn = now;
            }
        }

        // Run mode-specific control
        switch (mode) {
            case MODE_SPOT_LOCK:
                runSpotLock(dt);
                break;
            case MODE_NAVIGATE:
                // Navigate uses same logic as spot-lock (moving anchor)
                runSpotLock(dt);
                break;
            case MODE_IDLE:
            default:
                // Do nothing — motors already stopped
                break;
        }
    }

    // Push dashboard updates
    if (ENABLE_DASHBOARD) {
        dashboard.update(gps, imu, wind, sensors, motor);
    }
}
