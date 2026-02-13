#pragma once
#include <Arduino.h>

// ============================================================
// PID Controller — Generic, reusable for position and heading
// Includes anti-windup, deadband, and output clamping
// ============================================================

class PidController {
public:
    PidController(float kp, float ki, float kd,
                  float deadband = 0, float maxOutput = 1.0,
                  float maxIntegral = 10.0);

    float compute(float error, float dt);
    void reset();
    void setGains(float kp, float ki, float kd);
    void setDeadband(float deadband) { _deadband = deadband; }

    // Getters for dashboard display
    float getP() const { return _lastP; }
    float getI() const { return _lastI; }
    float getD() const { return _lastD; }
    float getOutput() const { return _lastOutput; }

private:
    float _kp, _ki, _kd;
    float _deadband;
    float _maxOutput;
    float _maxIntegral;

    float _integral = 0;
    float _prevError = 0;
    bool _firstRun = true;

    // For debugging/dashboard
    float _lastP = 0, _lastI = 0, _lastD = 0, _lastOutput = 0;
};
