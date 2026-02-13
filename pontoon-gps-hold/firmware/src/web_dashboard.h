#pragma once
#include <Arduino.h>
#include <WiFi.h>
#include <ESPAsyncWebServer.h>
#include <ArduinoJson.h>
#include "config.h"
#include "gps_module.h"
#include "imu_module.h"
#include "wind_sensor.h"
#include "sensors.h"
#include "motor_control.h"

// ============================================================
// Phone Dashboard — ESP32 WiFi Access Point + Web Server
// Serves a mobile-friendly UI for monitoring and control
// ============================================================

// Callback types for dashboard commands
typedef void (*AnchorCallback)();
typedef void (*HeadingLockCallback)();
typedef void (*StopCallback)();
typedef void (*SaveSpotCallback)(const char* name);

class WebDashboard {
public:
    void begin();
    void update(GpsModule& gps, ImuModule& imu, WindSensor& wind,
                Sensors& sensors, MotorControl& motor);

    void onAnchor(AnchorCallback cb) { _onAnchor = cb; }
    void onClearAnchor(AnchorCallback cb) { _onClearAnchor = cb; }
    void onHeadingLock(HeadingLockCallback cb) { _onHeadingLock = cb; }
    void onClearHeadingLock(HeadingLockCallback cb) { _onClearHeadingLock = cb; }
    void onStop(StopCallback cb) { _onStop = cb; }
    void onSaveSpot(SaveSpotCallback cb) { _onSaveSpot = cb; }

private:
    AsyncWebServer _server = AsyncWebServer(80);
    AsyncEventSource _events = AsyncEventSource("/events");
    unsigned long _lastPush = 0;

    AnchorCallback _onAnchor = nullptr;
    AnchorCallback _onClearAnchor = nullptr;
    HeadingLockCallback _onHeadingLock = nullptr;
    HeadingLockCallback _onClearHeadingLock = nullptr;
    StopCallback _onStop = nullptr;
    SaveSpotCallback _onSaveSpot = nullptr;

    void setupRoutes();
    String buildStatusJson(GpsModule& gps, ImuModule& imu, WindSensor& wind,
                           Sensors& sensors, MotorControl& motor);
    static const char* getPageHtml();
};
