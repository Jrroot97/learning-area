#include "motor_control.h"

void MotorControl::begin() {
    // Motor ESC channel
    ledcSetup(PWM_CH_MOTOR, PWM_FREQ, PWM_RESOLUTION);
    ledcAttachPin(PIN_MOTOR, PWM_CH_MOTOR);

    // Steering servo channel
    ledcSetup(PWM_CH_SERVO, PWM_FREQ, PWM_RESOLUTION);
    ledcAttachPin(PIN_SERVO, PWM_CH_SERVO);

    stopAll();
    Serial.println("[MOTOR] Single motor + steering servo initialized");
}

void MotorControl::setThrust(float thrust) {
    if (_killed) return;

    _targetThrust = constrain(thrust, -THRUST_MAX, THRUST_MAX);

    // Ramp for smooth transitions
    _currentThrust = rampValue(_currentThrust, _targetThrust, THRUST_RAMP);

    // Deadband — don't buzz the motor at very low power
    float output = (fabs(_currentThrust) < THRUST_MIN) ? 0.0f : _currentThrust;
    writeThrust(output);
}

void MotorControl::setSteeringAngle(float angleDeg) {
    if (_killed) return;

    // Normalize to 0-360
    _targetAngle = fmod(angleDeg + 360.0f, 360.0f);
    _currentAngle = _targetAngle;  // Servo moves directly (no ramping needed)
    writeServo(_currentAngle);
}

void MotorControl::stopAll() {
    _targetThrust = 0;
    _currentThrust = 0;
    writeThrust(0);
    // Leave servo at current position — don't swing on stop
    Serial.println("[MOTOR] Motors stopped");
}

void MotorControl::emergencyStop() {
    _killed = true;
    _targetThrust = 0;
    _currentThrust = 0;
    writeThrust(0);
    Serial.println("[MOTOR] EMERGENCY STOP ACTIVATED");
}

float MotorControl::getEstimatedCurrentDraw() const {
    // Rough estimate: 30A at full thrust for a 55lb 12V motor
    return fabs(_currentThrust) * 30.0f;
}

void MotorControl::writeThrust(float value) {
    uint32_t pulseUs = thrustToPulseWidth(value);
    uint32_t duty = (uint32_t)((float)pulseUs / 20000.0f * 65536.0f);
    ledcWrite(PWM_CH_MOTOR, duty);
}

void MotorControl::writeServo(float angleDeg) {
    uint32_t pulseUs = angleToPulseWidth(angleDeg);
    uint32_t duty = (uint32_t)((float)pulseUs / 20000.0f * 65536.0f);
    ledcWrite(PWM_CH_SERVO, duty);
}

float MotorControl::rampValue(float current, float target, float maxStep) {
    float diff = target - current;
    if (fabs(diff) <= maxStep) return target;
    return current + (diff > 0 ? maxStep : -maxStep);
}

uint32_t MotorControl::thrustToPulseWidth(float thrust) {
    // Map -1.0..+1.0 to PWM_MIN_US..PWM_MAX_US
    // 0.0 = neutral (stopped)
    thrust = constrain(thrust, -1.0f, 1.0f);
    return (uint32_t)(PWM_NEUTRAL_US + thrust * (PWM_MAX_US - PWM_NEUTRAL_US));
}

uint32_t MotorControl::angleToPulseWidth(float angleDeg) {
    // Map 0-360 degrees to SERVO_MIN_US..SERVO_MAX_US
    // For a continuous rotation servo or 360-degree servo
    angleDeg = fmod(angleDeg + 360.0f, 360.0f);
    float fraction = angleDeg / 360.0f;
    return (uint32_t)(SERVO_MIN_US + fraction * (SERVO_MAX_US - SERVO_MIN_US));
}
