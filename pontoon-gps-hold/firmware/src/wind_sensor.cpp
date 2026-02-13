#include "wind_sensor.h"

// Modbus RTU request to read wind speed + direction
// Address 0x01, Function 0x03 (Read Holding Registers), Start 0x0000, Count 0x0002
static const uint8_t MODBUS_REQUEST[] = {0x01, 0x03, 0x00, 0x00, 0x00, 0x02, 0xC4, 0x0B};

void WindSensor::begin() {
    Serial1.begin(WIND_BAUD, SERIAL_8N1, WIND_RX_PIN, WIND_TX_PIN);
    pinMode(WIND_DE_RE_PIN, OUTPUT);
    digitalWrite(WIND_DE_RE_PIN, LOW);  // Start in receive mode
    Serial.println("[WIND] RS485 ultrasonic anemometer initialized");
}

void WindSensor::update() {
    unsigned long now = millis();
    unsigned long interval = 1000 / WIND_UPDATE_HZ;

    if (now - _lastRead < interval) return;
    _lastRead = now;

    sendModbusRequest();
    delay(50);  // Wait for response

    if (parseModbusResponse()) {
        _data.valid = true;
        _data.age_ms = 0;
        _lastValid = now;

        // Convert to mph
        _data.speed_mph = _data.speed_mps * 2.237f;

        // Track gusts
        _recentSpeeds[_speedIdx] = _data.speed_mps;
        _speedIdx = (_speedIdx + 1) % 10;
        _data.gust_mps = 0;
        for (int i = 0; i < 10; i++) {
            if (_recentSpeeds[i] > _data.gust_mps) {
                _data.gust_mps = _recentSpeeds[i];
            }
        }

        // Track trend
        _speedHistory[_histIdx] = _data.speed_mps;
        _histIdx = (_histIdx + 1) % 30;
    } else {
        _data.age_ms = now - _lastValid;
    }
}

void WindSensor::sendModbusRequest() {
    // Switch to transmit mode
    digitalWrite(WIND_DE_RE_PIN, HIGH);
    delayMicroseconds(100);

    Serial1.write(MODBUS_REQUEST, sizeof(MODBUS_REQUEST));
    Serial1.flush();

    // Switch back to receive mode
    delayMicroseconds(100);
    digitalWrite(WIND_DE_RE_PIN, LOW);
}

bool WindSensor::parseModbusResponse() {
    // Expected response: addr(1) + func(1) + byteCount(1) + data(4) + crc(2) = 9 bytes
    if (Serial1.available() < 9) return false;

    uint8_t buf[9];
    Serial1.readBytes(buf, 9);

    // Verify address and function code
    if (buf[0] != 0x01 || buf[1] != 0x03 || buf[2] != 0x04) return false;

    // Parse wind direction (register 0) — 0.1 degree resolution
    uint16_t dirRaw = (buf[3] << 8) | buf[4];
    _data.direction_deg = dirRaw / 10.0f;

    // Parse wind speed (register 1) — 0.1 m/s resolution
    uint16_t speedRaw = (buf[5] << 8) | buf[6];
    _data.speed_mps = speedRaw / 10.0f;

    return true;
}

WindForce WindSensor::getForceRelativeToHeading(float boatHeading) const {
    WindForce force = {};
    if (!isValid()) return force;

    // Wind force is proportional to speed squared (aerodynamic drag)
    float windForce = _data.speed_mps * _data.speed_mps * WIND_FF_DRAG;

    // Angle between wind direction and boat heading
    float relativeAngle = _data.direction_deg - boatHeading;
    float relRad = relativeAngle * PI / 180.0f;

    // Decompose into forward and lateral components
    // Wind "from" 0° (north) hitting a boat heading 0° = headwind = negative forward force
    force.force_forward = -windForce * cos(relRad);
    force.force_lateral = -windForce * sin(relRad);
    force.force_magnitude = windForce;

    return force;
}

float WindSensor::getCounterThrust() const {
    if (!isValid()) return 0;
    // More wind = more thrust needed to hold position
    float force = _data.speed_mps * _data.speed_mps * WIND_FF_DRAG * WIND_FF_GAIN;
    return constrain(force, 0.0f, THRUST_MAX * 0.5f);  // Cap at 50% thrust for feedforward
}

float WindSensor::getCounterAngle(float boatHeading) const {
    if (!isValid()) return boatHeading;
    // Point motor into the wind to counter it
    // Wind comes FROM direction_deg, so motor should point AT direction_deg
    return _data.direction_deg;
}

bool WindSensor::isIncreasing() const {
    // Compare first half of history to second half
    float firstHalf = 0, secondHalf = 0;
    for (int i = 0; i < 15; i++) {
        firstHalf += _speedHistory[i];
        secondHalf += _speedHistory[i + 15];
    }
    return (secondHalf / 15.0f) > (firstHalf / 15.0f) + 0.5f;
}

bool WindSensor::isGusting() const {
    // Gust = recent max is 50%+ higher than average
    if (!isValid()) return false;
    float avg = 0;
    for (int i = 0; i < 10; i++) avg += _recentSpeeds[i];
    avg /= 10.0f;
    return (avg > 0.5f) && (_data.gust_mps > avg * 1.5f);
}
