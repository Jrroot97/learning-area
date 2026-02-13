#include "motor_control.h"

void MotorControl::begin() {
    // Configure LEDC PWM channels for each motor ESC
    ledcSetup(PWM_CH_FL, PWM_FREQ, PWM_RESOLUTION);
    ledcSetup(PWM_CH_FR, PWM_FREQ, PWM_RESOLUTION);
    ledcSetup(PWM_CH_RL, PWM_FREQ, PWM_RESOLUTION);
    ledcSetup(PWM_CH_RR, PWM_FREQ, PWM_RESOLUTION);

    // Attach pins to channels
    ledcAttachPin(PIN_MOTOR_FL, PWM_CH_FL);
    ledcAttachPin(PIN_MOTOR_FR, PWM_CH_FR);
    ledcAttachPin(PIN_MOTOR_RL, PWM_CH_RL);
    ledcAttachPin(PIN_MOTOR_RR, PWM_CH_RR);

    // Start at neutral (motors off)
    stopAll();

    Serial.println("[MOTORS] 4-motor differential thrust initialized");
}

void MotorControl::setMotors(const MotorOutputs& output) {
    if (_killed) return;

    _target = output;

    // Clamp targets
    _target.front_left  = constrain(_target.front_left,  -THRUST_MAX, THRUST_MAX);
    _target.front_right = constrain(_target.front_right, -THRUST_MAX, THRUST_MAX);
    _target.rear_left   = constrain(_target.rear_left,   -THRUST_MAX, THRUST_MAX);
    _target.rear_right  = constrain(_target.rear_right,  -THRUST_MAX, THRUST_MAX);

    // Ramp toward targets for smooth transitions
    _current.front_left  = rampValue(_current.front_left,  _target.front_left,  THRUST_RAMP);
    _current.front_right = rampValue(_current.front_right, _target.front_right, THRUST_RAMP);
    _current.rear_left   = rampValue(_current.rear_left,   _target.rear_left,   THRUST_RAMP);
    _current.rear_right  = rampValue(_current.rear_right,  _target.rear_right,  THRUST_RAMP);

    // Apply minimum thrust deadband (motors buzz at very low power)
    float fl = (fabs(_current.front_left)  < THRUST_MIN) ? 0.0f : _current.front_left;
    float fr = (fabs(_current.front_right) < THRUST_MIN) ? 0.0f : _current.front_right;
    float rl = (fabs(_current.rear_left)   < THRUST_MIN) ? 0.0f : _current.rear_left;
    float rr = (fabs(_current.rear_right)  < THRUST_MIN) ? 0.0f : _current.rear_right;

    // Write PWM to ESCs
    writeMotor(PWM_CH_FL, fl);
    writeMotor(PWM_CH_FR, fr);
    writeMotor(PWM_CH_RL, rl);
    writeMotor(PWM_CH_RR, rr);
}

void MotorControl::stopAll() {
    _target = {0, 0, 0, 0};
    _current = {0, 0, 0, 0};
    writeMotor(PWM_CH_FL, 0);
    writeMotor(PWM_CH_FR, 0);
    writeMotor(PWM_CH_RL, 0);
    writeMotor(PWM_CH_RR, 0);
}

void MotorControl::emergencyStop() {
    _killed = true;
    // Bypass ramping — immediate stop
    _target = {0, 0, 0, 0};
    _current = {0, 0, 0, 0};
    writeMotor(PWM_CH_FL, 0);
    writeMotor(PWM_CH_FR, 0);
    writeMotor(PWM_CH_RL, 0);
    writeMotor(PWM_CH_RR, 0);
    Serial.println("[MOTORS] EMERGENCY STOP ACTIVATED");
}

float MotorControl::getTotalCurrentDraw() const {
    // Estimate total current draw from thrust levels
    // Rough approximation: 30A max per motor at full thrust
    float total = 0;
    total += fabs(_current.front_left)  * 30.0f;
    total += fabs(_current.front_right) * 30.0f;
    total += fabs(_current.rear_left)   * 30.0f;
    total += fabs(_current.rear_right)  * 30.0f;
    return total;
}

void MotorControl::writeMotor(uint8_t channel, float value) {
    uint32_t pulseUs = thrustToPulseWidth(value);

    // Convert microseconds to LEDC duty cycle
    // At 50Hz, period = 20000us. With 16-bit resolution (65536 ticks):
    // duty = (pulseUs / 20000) * 65536
    uint32_t duty = (uint32_t)((float)pulseUs / 20000.0f * 65536.0f);
    ledcWrite(channel, duty);
}

float MotorControl::rampValue(float current, float target, float maxStep) {
    float diff = target - current;
    if (fabs(diff) <= maxStep) return target;
    return current + (diff > 0 ? maxStep : -maxStep);
}

uint32_t MotorControl::thrustToPulseWidth(float thrust) {
    // Map -1.0..+1.0 to PWM_MIN_US..PWM_MAX_US
    // 0.0 = neutral (PWM_NEUTRAL_US)
    // +1.0 = full forward (PWM_MAX_US)
    // -1.0 = full reverse (PWM_MIN_US)
    thrust = constrain(thrust, -1.0f, 1.0f);
    return (uint32_t)(PWM_NEUTRAL_US + thrust * (PWM_MAX_US - PWM_NEUTRAL_US));
}
