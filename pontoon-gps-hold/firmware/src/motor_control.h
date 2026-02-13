#pragma once
#include <Arduino.h>
#include "config.h"

// ============================================================
// Single Motor + Steering Servo Control
// One trolling motor for thrust, one servo for direction
// ============================================================

class MotorControl {
public:
    void begin();

    // Set thrust: -1.0 (full reverse) to +1.0 (full forward)
    void setThrust(float thrust);

    // Set steering angle: 0-360 degrees (compass-style)
    // 0/360 = straight ahead, 90 = full right, 270 = full left
    void setSteeringAngle(float angleDeg);

    void stopAll();
    void emergencyStop();
    bool isKilled() const { return _killed; }
    void resetKill() { _killed = false; }

    float getCurrentThrust() const { return _currentThrust; }
    float getCurrentAngle() const { return _currentAngle; }
    float getEstimatedCurrentDraw() const;

private:
    void writeThrust(float value);
    void writeServo(float angleDeg);
    float rampValue(float current, float target, float maxStep);
    uint32_t thrustToPulseWidth(float thrust);
    uint32_t angleToPulseWidth(float angleDeg);

    float _currentThrust = 0;
    float _targetThrust = 0;
    float _currentAngle = 0;    // Current servo angle in degrees
    float _targetAngle = 0;
    bool _killed = false;
};
