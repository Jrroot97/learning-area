#pragma once
#include <Arduino.h>
#include "config.h"

// ============================================================
// Wind Sensor Module — RS485 Ultrasonic Anemometer
// Reads wind speed and direction for feedforward compensation
// Supports Renke-style RS485 Modbus ultrasonic anemometers
// ============================================================

struct WindData {
    float speed_mps;        // Wind speed in meters per second
    float speed_mph;        // Wind speed in mph
    float direction_deg;    // Wind direction 0-360 (where wind comes FROM)
    float gust_mps;         // Recent gust (max over last 10 readings)
    bool valid;
    unsigned long age_ms;
};

// Wind force decomposed into boat-relative components
struct WindForce {
    float force_forward;    // Force pushing boat forward/back
    float force_lateral;    // Force pushing boat left/right
    float force_magnitude;  // Total force magnitude
};

class WindSensor {
public:
    void begin();
    void update();

    WindData getData() const { return _data; }
    bool isValid() const { return _data.valid && _data.age_ms < 5000; }

    // Get wind force relative to boat heading
    WindForce getForceRelativeToHeading(float boatHeading) const;

    // Get feedforward thrust and steering to counter wind
    float getCounterThrust() const;
    float getCounterAngle(float boatHeading) const;

    // Trend detection
    bool isIncreasing() const;
    bool isGusting() const;

private:
    WindData _data = {};
    unsigned long _lastRead = 0;
    unsigned long _lastValid = 0;

    // Modbus request/response
    void sendModbusRequest();
    bool parseModbusResponse();

    // Gust tracking
    float _recentSpeeds[10] = {};
    int _speedIdx = 0;

    // Trend tracking
    float _speedHistory[30] = {};   // 30 readings ~ 3 seconds at 10Hz
    int _histIdx = 0;
};
