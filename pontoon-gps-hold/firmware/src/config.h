#pragma once

// ============================================================
// Pontoon GPS Hold System — Configuration
// 12V 4-Motor Differential Thrust with Smart Sensors
// ============================================================

// -- WiFi Access Point (phone connects to this) --
#define WIFI_SSID       "PontoonGPS"
#define WIFI_PASSWORD   "fishing123"

// -- Motor ESC PWM Pins --
// Each motor gets one PWM pin to its ESC
// ESC expects standard RC PWM: 1000us (off) to 2000us (full)
#define PIN_MOTOR_FL    25   // Front Left
#define PIN_MOTOR_FR    26   // Front Right
#define PIN_MOTOR_RL    27   // Rear Left
#define PIN_MOTOR_RR    14   // Rear Right

// PWM configuration
#define PWM_FREQ        50      // 50 Hz (standard RC servo/ESC)
#define PWM_RESOLUTION  16      // 16-bit resolution
#define PWM_MIN_US      1000    // Minimum pulse width (motor off / full reverse)
#define PWM_NEUTRAL_US  1500    // Neutral (motor stopped)
#define PWM_MAX_US      2000    // Maximum pulse width (full forward)

// Motor PWM channels (ESP32 has 16 LEDC channels)
#define PWM_CH_FL       0
#define PWM_CH_FR       1
#define PWM_CH_RL       2
#define PWM_CH_RR       3

// -- GPS (Serial2) --
#define GPS_RX_PIN      16
#define GPS_TX_PIN      17
#define GPS_BAUD        9600

// -- IMU / Compass (I2C) --
// BNO055 uses default I2C: SDA=21, SCL=22
#define IMU_SDA_PIN     21
#define IMU_SCL_PIN     22

// -- Wind Sensor (RS485 via Serial1) --
#define WIND_RX_PIN     32
#define WIND_TX_PIN     33
#define WIND_BAUD       9600
#define WIND_DE_RE_PIN  4    // RS485 direction control (DE+RE tied together)

// -- Sonar (JSN-SR04T) --
#define SONAR_TRIG_PIN  18
#define SONAR_ECHO_PIN  19

// -- Water Temperature (DS18B20 OneWire) --
#define TEMP_PIN        5

// -- Bite Detection (Piezo vibration sensors) --
#define BITE_SENSOR_1   36   // ADC1 (VP) — Rod 1
#define BITE_SENSOR_2   39   // ADC1 (VN) — Rod 2

// -- Battery Voltage Monitor --
#define BATTERY_PIN     34   // ADC — voltage divider from 12V
#define VDIV_RATIO      4.0  // Voltage divider ratio (e.g., 30K/10K)

// -- Buzzer / Alert --
#define BUZZER_PIN      13

// -- RPi Communication (UART for wave prediction data) --
#define RPI_RX_PIN      35
#define RPI_TX_PIN      12
#define RPI_BAUD        115200

// ============================================================
// Boat Geometry — 10ft Wide Pontoon
// ============================================================

// Distance from boat center to each motor (meters)
// Pontoon tubes ~90" apart center-to-center = ~2.286m
#define MOTOR_HALF_WIDTH    1.143   // Half of tube spacing (meters)

// Distance from boat center to front/rear motor pairs (meters)
// Adjust based on your pontoon length and motor placement
#define MOTOR_FRONT_DIST    3.0     // Front motors ahead of center (meters)
#define MOTOR_REAR_DIST     3.0     // Rear motors behind center (meters)

// ============================================================
// Control Parameters
// ============================================================

// -- Position Hold PID --
#define POS_KP          0.8     // Proportional gain
#define POS_KI          0.05    // Integral gain
#define POS_KD          0.3     // Derivative gain
#define POS_DEADBAND    0.5     // Ignore errors < 0.5m (GPS noise)
#define POS_MAX_ERROR   20.0    // Clamp max error at 20m

// -- Heading Hold PID --
#define HDG_KP          1.2     // Proportional gain
#define HDG_KI          0.02    // Integral gain
#define HDG_KD          0.5     // Derivative gain
#define HDG_DEADBAND    2.0     // Ignore errors < 2 degrees
#define HDG_MAX_ERROR   180.0   // Max heading error

// -- Wind Feedforward --
#define WIND_FF_GAIN    0.15    // How much wind input affects thrust
#define WIND_FF_DRAG    0.08    // Pontoon drag coefficient (high for pontoons)

// -- Wave Prediction Feedforward --
#define WAVE_FF_GAIN    0.10    // How much wave prediction affects thrust
#define WAVE_CONFIDENCE_MIN 0.3 // Ignore wave data below this confidence

// -- Motor Limits --
#define THRUST_MAX      1.0     // Maximum normalized thrust (0.0 to 1.0)
#define THRUST_MIN      0.05    // Minimum thrust (below this, motor off)
#define THRUST_RAMP     0.05    // Max thrust change per cycle (smoothing)

// -- Control Loop Timing --
#define CONTROL_LOOP_HZ     20      // Main control loop frequency
#define GPS_UPDATE_HZ       10      // GPS read rate
#define SENSOR_UPDATE_HZ    5       // Fishing sensors read rate
#define DASHBOARD_UPDATE_HZ 4       // Phone dashboard push rate
#define WIND_UPDATE_HZ      10      // Wind sensor read rate

// ============================================================
// Safety Limits
// ============================================================

#define BATTERY_MIN_VOLTS       10.5    // Low battery cutoff (12V system)
#define BATTERY_WARN_VOLTS      11.0    // Low battery warning
#define MAX_DRIFT_METERS        50.0    // Kill motors if > 50m from anchor
#define MAX_TILT_DEGREES        30.0    // Kill motors if boat tilts > 30°
#define WATCHDOG_TIMEOUT_MS     2000    // Watchdog timer
#define MOTOR_TEMP_MAX_C        80.0    // Motor temperature cutoff

// ============================================================
// Feature Flags — Enable/disable modules
// ============================================================

#define ENABLE_GPS              true
#define ENABLE_IMU              true
#define ENABLE_WIND_SENSOR      true
#define ENABLE_WAVE_PREDICTION  true
#define ENABLE_SONAR            true
#define ENABLE_WATER_TEMP       true
#define ENABLE_BITE_DETECTION   true
#define ENABLE_DASHBOARD        true
#define ENABLE_DATA_LOGGING     true
