#pragma once
#include <Arduino.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include "config.h"

// ============================================================
// Fishing Sensors — Sonar, Water Temp, Battery
// ============================================================

struct SonarData {
    float depth_ft;
    float depth_m;
    bool valid;
};

struct BatteryStatus {
    float voltage;
    float percentage;           // 0-100%
    float estimatedHoursLeft;
    bool low;
    bool critical;
};

class Sensors {
public:
    void begin();
    void update();

    SonarData getSonar() const { return _sonar; }
    float getWaterTempF() const { return _waterTempC * 9.0f / 5.0f + 32.0f; }
    float getWaterTempC() const { return _waterTempC; }
    BatteryStatus getBattery() const { return _battery; }

    void buzzerAlert(int durationMs = 200);

private:
    void updateSonar();
    void updateWaterTemp();
    void updateBattery(float currentDraw);

    SonarData _sonar = {};
    unsigned long _lastSonarRead = 0;

    OneWire _oneWire = OneWire(TEMP_PIN);
    DallasTemperature _tempSensor = DallasTemperature(&_oneWire);
    float _waterTempC = 0;
    unsigned long _lastTempRead = 0;

    BatteryStatus _battery = {};
    unsigned long _lastBatteryRead = 0;
};
