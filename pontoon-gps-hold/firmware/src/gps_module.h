#pragma once
#include <Arduino.h>
#include <TinyGPSPlus.h>
#include "config.h"

// ============================================================
// GPS Module — Position tracking and anchor hold
// Supports NEO-M9N (standard) or ZED-F9P (RTK)
// ============================================================

struct GpsPosition {
    double lat;
    double lng;
    double altitude;
    float speed_mps;      // Speed in meters per second
    float course_deg;     // Course over ground in degrees
    float hdop;           // Horizontal dilution of precision
    uint32_t satellites;
    bool valid;
    unsigned long age_ms; // Age of last fix
};

struct AnchorError {
    float distance_m;     // Distance from anchor point in meters
    float bearing_deg;    // Bearing TO anchor point in degrees
    float north_error_m;  // North/south error in meters (+N / -S)
    float east_error_m;   // East/west error in meters (+E / -W)
};

class GpsModule {
public:
    void begin();
    void update();

    GpsPosition getPosition() const { return _position; }
    bool hasFix() const { return _position.valid && _position.satellites >= 4; }

    // Anchor (spot-lock) functions
    void setAnchor();
    void setAnchor(double lat, double lng);
    void clearAnchor();
    bool isAnchored() const { return _anchored; }
    AnchorError getAnchorError() const;
    GpsPosition getAnchorPosition() const { return _anchor; }

    // Saved spots
    struct SavedSpot {
        char name[32];
        double lat;
        double lng;
        bool used;
    };
    bool saveSpot(const char* name);
    int getSavedSpotCount() const;
    SavedSpot getSavedSpot(int index) const;
    void navigateToSpot(int index);

    // Utilities
    static float distanceBetween(double lat1, double lng1, double lat2, double lng2);
    static float bearingTo(double lat1, double lng1, double lat2, double lng2);

private:
    TinyGPSPlus _gps;
    GpsPosition _position = {};
    GpsPosition _anchor = {};
    bool _anchored = false;
    unsigned long _lastRead = 0;

    static const int MAX_SAVED_SPOTS = 50;
    SavedSpot _savedSpots[MAX_SAVED_SPOTS] = {};
};
