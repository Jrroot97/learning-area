#include "imu_module.h"

bool ImuModule::begin() {
    Wire.begin(IMU_SDA_PIN, IMU_SCL_PIN);

    if (!_bno.begin()) {
        Serial.println("[IMU] BNO055 not detected — check wiring");
        return false;
    }

    _bno.setExtCrystalUse(true);
    _initialized = true;
    Serial.println("[IMU] BNO055 initialized");
    return true;
}

void ImuModule::update() {
    if (!_initialized) return;

    // Get orientation (Euler angles)
    sensors_event_t orientEvent;
    _bno.getEvent(&orientEvent, Adafruit_BNO055::VECTOR_EULER);
    _data.heading = orientEvent.orientation.x;  // 0-360 degrees
    _data.pitch   = orientEvent.orientation.z;
    _data.roll    = orientEvent.orientation.y;

    // Get linear acceleration (gravity removed)
    sensors_event_t accelEvent;
    _bno.getEvent(&accelEvent, Adafruit_BNO055::VECTOR_LINEARACCEL);
    _data.accel_x = accelEvent.acceleration.x;
    _data.accel_y = accelEvent.acceleration.y;
    _data.accel_z = accelEvent.acceleration.z;

    // Get gyroscope
    sensors_event_t gyroEvent;
    _bno.getEvent(&gyroEvent, Adafruit_BNO055::VECTOR_GYROSCOPE);
    _data.gyro_x = gyroEvent.gyro.x;
    _data.gyro_y = gyroEvent.gyro.y;
    _data.gyro_z = gyroEvent.gyro.z;

    // Get calibration status
    uint8_t sys, gyro, accel, mag;
    _bno.getCalibration(&sys, &gyro, &accel, &mag);
    _data.calibration = min(min(sys, gyro), min(accel, mag));
    _data.valid = _initialized;

    // Track acceleration magnitude for wave intensity
    float accelMag = sqrt(_data.accel_x * _data.accel_x +
                          _data.accel_y * _data.accel_y +
                          _data.accel_z * _data.accel_z);
    _accelHistory[_accelHistIdx] = accelMag;
    _accelHistIdx = (_accelHistIdx + 1) % 20;
}

bool ImuModule::isTilted() const {
    return (fabs(_data.pitch) > MAX_TILT_DEGREES ||
            fabs(_data.roll) > MAX_TILT_DEGREES);
}

float ImuModule::getWaveIntensity() const {
    // Calculate standard deviation of recent acceleration magnitudes
    float sum = 0, sumSq = 0;
    for (int i = 0; i < 20; i++) {
        sum += _accelHistory[i];
        sumSq += _accelHistory[i] * _accelHistory[i];
    }
    float mean = sum / 20.0f;
    float variance = (sumSq / 20.0f) - (mean * mean);
    return sqrt(max(0.0f, variance));  // Standard deviation in m/s²
}

void ImuModule::setHeadingLock() {
    _lockedHeading = _data.heading;
    _headingLocked = true;
    Serial.printf("[IMU] Heading locked at %.1f°\n", _lockedHeading);
}

void ImuModule::setHeadingLock(float heading) {
    _lockedHeading = fmod(heading + 360.0f, 360.0f);
    _headingLocked = true;
    Serial.printf("[IMU] Heading locked at %.1f° (manual)\n", _lockedHeading);
}

void ImuModule::clearHeadingLock() {
    _headingLocked = false;
    Serial.println("[IMU] Heading lock cleared");
}

float ImuModule::getHeadingError() const {
    if (!_headingLocked) return 0;
    return normalizeAngle(_lockedHeading - _data.heading);
}

float ImuModule::normalizeAngle(float angle) {
    // Normalize to -180..+180
    while (angle > 180.0f)  angle -= 360.0f;
    while (angle < -180.0f) angle += 360.0f;
    return angle;
}
