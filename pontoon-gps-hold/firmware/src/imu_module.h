#pragma once
#include <Arduino.h>
#include <Adafruit_BNO055.h>
#include <Adafruit_Sensor.h>
#include "config.h"

// ============================================================
// IMU / Compass Module — BNO055
// Provides heading, tilt detection, and wave motion data
// ============================================================

struct ImuData {
    float heading;          // Compass heading 0-360 degrees (magnetic north)
    float pitch;            // Forward/back tilt in degrees
    float roll;             // Left/right tilt in degrees
    float accel_x;          // Acceleration X (m/s²)
    float accel_y;          // Acceleration Y (m/s²)
    float accel_z;          // Acceleration Z (m/s²)
    float gyro_x;           // Angular velocity X (rad/s)
    float gyro_y;           // Angular velocity Y (rad/s)
    float gyro_z;           // Angular velocity Z (rad/s)
    uint8_t calibration;    // 0 (uncalibrated) to 3 (fully calibrated)
    bool valid;
};

class ImuModule {
public:
    bool begin();
    void update();

    ImuData getData() const { return _data; }
    float getHeading() const { return _data.heading; }
    bool isCalibrated() const { return _data.calibration >= 2; }
    bool isTilted() const;
    float getWaveIntensity() const;

    // Heading lock
    void setHeadingLock();
    void setHeadingLock(float heading);
    void clearHeadingLock();
    bool isHeadingLocked() const { return _headingLocked; }
    float getHeadingError() const;
    float getLockedHeading() const { return _lockedHeading; }

private:
    Adafruit_BNO055 _bno = Adafruit_BNO055(55, 0x28);
    ImuData _data = {};
    bool _initialized = false;

    // Heading lock
    bool _headingLocked = false;
    float _lockedHeading = 0;

    // Wave intensity tracking
    float _accelHistory[20] = {};
    int _accelHistIdx = 0;

    float normalizeAngle(float angle);
};
