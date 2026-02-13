#pragma once
#include <Arduino.h>
#include "config.h"

// ============================================================
// 4-Motor Differential Thrust Control
// Controls 4 trolling motors via ESC PWM signals
// No steering servos — direction via differential thrust
// ============================================================

struct MotorOutputs {
    float front_left;   // -1.0 (full reverse) to +1.0 (full forward)
    float front_right;
    float rear_left;
    float rear_right;
};

class MotorControl {
public:
    void begin();
    void setMotors(const MotorOutputs& output);
    void stopAll();
    void emergencyStop();
    bool isKilled() const { return _killed; }
    void resetKill() { _killed = false; }
    MotorOutputs getCurrentOutputs() const { return _current; }
    float getTotalCurrentDraw() const;

private:
    void writeMotor(uint8_t channel, float value);
    float rampValue(float current, float target, float maxStep);
    uint32_t thrustToPulseWidth(float thrust);

    MotorOutputs _current = {0, 0, 0, 0};
    MotorOutputs _target = {0, 0, 0, 0};
    bool _killed = false;
    unsigned long _lastUpdate = 0;
};
