#pragma once

// ============================================================
// GPS Spot-Lock Trolling Motor — Configuration
// Single 12V bow-mount motor + steering servo
// Jon boat starter build — all smart features included
// ============================================================

// -- WiFi Access Point (phone connects to this) --
#define WIFI_SSID       "SpotLock"
#define WIFI_PASSWORD   "fishing123"

// -- Motor ESC PWM --
// Single trolling motor via ESC
// ESC expects standard RC PWM: 1000us (off) to 2000us (full)
#define PIN_MOTOR       25      // Motor ESC signal

// -- Steering Servo PWM --
// Waterproof servo rotates motor head 0-360 degrees
#define PIN_SERVO       26      // Steering servo signal

// PWM configuration
#define PWM_FREQ        50      // 50 Hz (standard RC servo/ESC)
#define PWM_RESOLUTION  16      // 16-bit resolution
#define PWM_MIN_US      1000    // Minimum pulse (full reverse)
#define PWM_NEUTRAL_US  1500    // Neutral (motor stopped)
#define PWM_MAX_US      2000    // Maximum pulse (full forward)

// Servo range
#define SERVO_MIN_US    500     // Servo minimum pulse
#define SERVO_MAX_US    2500    // Servo maximum pulse
#define SERVO_CENTER_US 1500    // Servo center position

// LEDC channels
#define PWM_CH_MOTOR    0
#define PWM_CH_SERVO    1

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
#define WIND_DE_RE_PIN  4       // RS485 direction control

// -- Sonar (JSN-SR04T) --
#define SONAR_TRIG_PIN  18
#define SONAR_ECHO_PIN  19

// -- Water Temperature (DS18B20 OneWire) --
#define TEMP_PIN        5

// -- Battery Voltage Monitor --
#define BATTERY_PIN     34      // ADC — voltage divider from 12V
#define VDIV_RATIO      4.0     // Voltage divider ratio (30K/10K)

// -- Buzzer / Alert --
#define BUZZER_PIN      13

// -- RPi Communication (UART for wave prediction) --
#define RPI_RX_PIN      35
#define RPI_TX_PIN      12
#define RPI_BAUD        115200

// ============================================================
// Control Parameters
// ============================================================

// -- Position Hold PID --
#define POS_KP          0.8
#define POS_KI          0.05
#define POS_KD          0.3
#define POS_DEADBAND    0.5     // Ignore errors < 0.5m (GPS noise)
#define POS_MAX_ERROR   20.0    // Clamp max error at 20m

// -- Heading Hold PID (servo steering) --
#define HDG_KP          1.5
#define HDG_KI          0.03
#define HDG_KD          0.6
#define HDG_DEADBAND    3.0     // Ignore errors < 3 degrees
#define HDG_MAX_ERROR   180.0

// -- Wind Feedforward --
#define WIND_FF_GAIN    0.15
#define WIND_FF_DRAG    0.05    // Jon boat drag coefficient

// -- Wave Prediction Feedforward --
#define WAVE_FF_GAIN    0.10
#define WAVE_CONFIDENCE_MIN 0.3

// -- Motor Limits --
#define THRUST_MAX      1.0     // Max normalized thrust (0.0 to 1.0)
#define THRUST_MIN      0.05    // Below this, motor off
#define THRUST_RAMP     0.05    // Max thrust change per cycle

// -- Control Loop Timing --
#define CONTROL_LOOP_HZ     20
#define GPS_UPDATE_HZ       10
#define SENSOR_UPDATE_HZ    5
#define DASHBOARD_UPDATE_HZ 4
#define WIND_UPDATE_HZ      10

// ============================================================
// Safety Limits
// ============================================================

#define BATTERY_MIN_VOLTS       10.5    // Low battery cutoff (12V)
#define BATTERY_WARN_VOLTS      11.0    // Low battery warning
#define MAX_DRIFT_METERS        50.0    // Kill motor if > 50m from anchor
#define MAX_TILT_DEGREES        30.0    // Kill motor if tilted > 30°
#define WATCHDOG_TIMEOUT_MS     2000
#define MOTOR_TEMP_MAX_C        80.0

// ============================================================
// Feature Flags
// ============================================================

#define ENABLE_GPS              true
#define ENABLE_IMU              true
#define ENABLE_WIND_SENSOR      true
#define ENABLE_WAVE_PREDICTION  true
#define ENABLE_SONAR            true
#define ENABLE_WATER_TEMP       true
#define ENABLE_DASHBOARD        true
#define ENABLE_DATA_LOGGING     true
