#include "sensors.h"

void Sensors::begin() {
    if (ENABLE_SONAR) {
        pinMode(SONAR_TRIG_PIN, OUTPUT);
        pinMode(SONAR_ECHO_PIN, INPUT);
        Serial.println("[SENSORS] Sonar initialized");
    }

    if (ENABLE_WATER_TEMP) {
        _tempSensor.begin();
        _tempSensor.setResolution(12);
        Serial.println("[SENSORS] Water temp sensor initialized");
    }

    pinMode(BATTERY_PIN, INPUT);
    pinMode(BUZZER_PIN, OUTPUT);
    digitalWrite(BUZZER_PIN, LOW);

    Serial.println("[SENSORS] All sensors initialized");
}

void Sensors::update() {
    unsigned long now = millis();
    unsigned long sensorInterval = 1000 / SENSOR_UPDATE_HZ;

    if (ENABLE_SONAR && (now - _lastSonarRead >= sensorInterval)) {
        updateSonar();
        _lastSonarRead = now;
    }

    if (ENABLE_WATER_TEMP && (now - _lastTempRead >= 2000)) {
        updateWaterTemp();
        _lastTempRead = now;
    }

    if (now - _lastBatteryRead >= 1000) {
        updateBattery(0);
        _lastBatteryRead = now;
    }
}

void Sensors::updateSonar() {
    digitalWrite(SONAR_TRIG_PIN, LOW);
    delayMicroseconds(2);
    digitalWrite(SONAR_TRIG_PIN, HIGH);
    delayMicroseconds(10);
    digitalWrite(SONAR_TRIG_PIN, LOW);

    long duration = pulseIn(SONAR_ECHO_PIN, HIGH, 30000);

    if (duration > 0) {
        _sonar.depth_m = (duration * 0.000343f) / 2.0f;
        _sonar.depth_ft = _sonar.depth_m * 3.281f;
        _sonar.valid = (_sonar.depth_m > 0.1f && _sonar.depth_m < 50.0f);
    } else {
        _sonar.valid = false;
    }
}

void Sensors::updateWaterTemp() {
    _tempSensor.requestTemperatures();
    float temp = _tempSensor.getTempCByIndex(0);
    if (temp != DEVICE_DISCONNECTED_C && temp > -10.0f && temp < 50.0f) {
        _waterTempC = temp;
    }
}

void Sensors::updateBattery(float currentDraw) {
    int raw = analogRead(BATTERY_PIN);
    float measuredV = (raw / 4095.0f) * 3.3f * VDIV_RATIO;

    _battery.voltage = (_battery.voltage * 0.9f) + (measuredV * 0.1f);

    // Lead acid 12V: 10.5V (empty) to 12.8V (full)
    _battery.percentage = constrain(
        map((long)(_battery.voltage * 100), 1050, 1280, 0, 100), 0, 100);

    if (currentDraw > 0.1f) {
        float ahRemaining = (100.0f * _battery.percentage / 100.0f);
        _battery.estimatedHoursLeft = ahRemaining / currentDraw;
    } else {
        _battery.estimatedHoursLeft = 99.0f;
    }

    _battery.low = _battery.voltage < BATTERY_WARN_VOLTS;
    _battery.critical = _battery.voltage < BATTERY_MIN_VOLTS;
}

void Sensors::buzzerAlert(int durationMs) {
    digitalWrite(BUZZER_PIN, HIGH);
    delay(durationMs);
    digitalWrite(BUZZER_PIN, LOW);
}
