#include "pid_controller.h"

PidController::PidController(float kp, float ki, float kd,
                             float deadband, float maxOutput,
                             float maxIntegral)
    : _kp(kp), _ki(ki), _kd(kd),
      _deadband(deadband), _maxOutput(maxOutput), _maxIntegral(maxIntegral) {}

float PidController::compute(float error, float dt) {
    if (dt <= 0) return _lastOutput;

    // Apply deadband — ignore small errors (GPS noise, compass jitter)
    if (fabs(error) < _deadband) {
        error = 0;
        // Slowly decay integral when in deadband
        _integral *= 0.95f;
    }

    // Proportional
    _lastP = _kp * error;

    // Integral with anti-windup
    _integral += error * dt;
    _integral = constrain(_integral, -_maxIntegral, _maxIntegral);
    _lastI = _ki * _integral;

    // Derivative (skip first run to avoid spike)
    if (_firstRun) {
        _lastD = 0;
        _firstRun = false;
    } else {
        float derivative = (error - _prevError) / dt;
        _lastD = _kd * derivative;
    }
    _prevError = error;

    // Sum and clamp output
    _lastOutput = _lastP + _lastI + _lastD;
    _lastOutput = constrain(_lastOutput, -_maxOutput, _maxOutput);

    return _lastOutput;
}

void PidController::reset() {
    _integral = 0;
    _prevError = 0;
    _firstRun = true;
    _lastP = _lastI = _lastD = _lastOutput = 0;
}

void PidController::setGains(float kp, float ki, float kd) {
    _kp = kp;
    _ki = ki;
    _kd = kd;
}
