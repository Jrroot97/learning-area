#include "gps_module.h"

void GpsModule::begin() {
    Serial2.begin(GPS_BAUD, SERIAL_8N1, GPS_RX_PIN, GPS_TX_PIN);
    Serial.println("[GPS] Module initialized on Serial2");
}

void GpsModule::update() {
    while (Serial2.available() > 0) {
        _gps.encode(Serial2.read());
    }

    if (_gps.location.isUpdated()) {
        _position.lat = _gps.location.lat();
        _position.lng = _gps.location.lng();
        _position.valid = _gps.location.isValid();
        _position.age_ms = _gps.location.age();
    }

    if (_gps.altitude.isUpdated()) {
        _position.altitude = _gps.altitude.meters();
    }

    if (_gps.speed.isUpdated()) {
        _position.speed_mps = _gps.speed.mps();
    }

    if (_gps.course.isUpdated()) {
        _position.course_deg = _gps.course.deg();
    }

    if (_gps.hdop.isUpdated()) {
        _position.hdop = _gps.hdop.hdop();
    }

    if (_gps.satellites.isUpdated()) {
        _position.satellites = _gps.satellites.value();
    }
}

void GpsModule::setAnchor() {
    if (!hasFix()) {
        Serial.println("[GPS] Cannot set anchor — no fix");
        return;
    }
    _anchor = _position;
    _anchored = true;
    Serial.printf("[GPS] Anchor set at %.7f, %.7f (%d sats, HDOP %.1f)\n",
                  _anchor.lat, _anchor.lng, _anchor.satellites, _anchor.hdop);
}

void GpsModule::setAnchor(double lat, double lng) {
    _anchor.lat = lat;
    _anchor.lng = lng;
    _anchor.valid = true;
    _anchored = true;
    Serial.printf("[GPS] Anchor set at %.7f, %.7f (manual)\n", lat, lng);
}

void GpsModule::clearAnchor() {
    _anchored = false;
    Serial.println("[GPS] Anchor cleared");
}

AnchorError GpsModule::getAnchorError() const {
    AnchorError err = {};

    if (!_anchored || !_position.valid) return err;

    err.distance_m = distanceBetween(_position.lat, _position.lng,
                                     _anchor.lat, _anchor.lng);
    err.bearing_deg = bearingTo(_position.lat, _position.lng,
                                _anchor.lat, _anchor.lng);

    // Decompose into north/east components for PID
    float bearing_rad = err.bearing_deg * PI / 180.0f;
    err.north_error_m = err.distance_m * cos(bearing_rad);
    err.east_error_m  = err.distance_m * sin(bearing_rad);

    return err;
}

bool GpsModule::saveSpot(const char* name) {
    if (!hasFix()) return false;

    for (int i = 0; i < MAX_SAVED_SPOTS; i++) {
        if (!_savedSpots[i].used) {
            strncpy(_savedSpots[i].name, name, 31);
            _savedSpots[i].name[31] = '\0';
            _savedSpots[i].lat = _position.lat;
            _savedSpots[i].lng = _position.lng;
            _savedSpots[i].used = true;
            Serial.printf("[GPS] Saved spot '%s' at %.7f, %.7f\n",
                          name, _position.lat, _position.lng);
            return true;
        }
    }
    Serial.println("[GPS] No room for more saved spots");
    return false;
}

int GpsModule::getSavedSpotCount() const {
    int count = 0;
    for (int i = 0; i < MAX_SAVED_SPOTS; i++) {
        if (_savedSpots[i].used) count++;
    }
    return count;
}

GpsModule::SavedSpot GpsModule::getSavedSpot(int index) const {
    if (index >= 0 && index < MAX_SAVED_SPOTS) {
        return _savedSpots[index];
    }
    return {};
}

void GpsModule::navigateToSpot(int index) {
    if (index >= 0 && index < MAX_SAVED_SPOTS && _savedSpots[index].used) {
        setAnchor(_savedSpots[index].lat, _savedSpots[index].lng);
        Serial.printf("[GPS] Navigating to '%s'\n", _savedSpots[index].name);
    }
}

float GpsModule::distanceBetween(double lat1, double lng1, double lat2, double lng2) {
    // Haversine formula
    double dLat = radians(lat2 - lat1);
    double dLng = radians(lng2 - lng1);
    double a = sin(dLat / 2.0) * sin(dLat / 2.0) +
               cos(radians(lat1)) * cos(radians(lat2)) *
               sin(dLng / 2.0) * sin(dLng / 2.0);
    double c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a));
    return (float)(6371000.0 * c); // Earth radius in meters
}

float GpsModule::bearingTo(double lat1, double lng1, double lat2, double lng2) {
    double dLng = radians(lng2 - lng1);
    double y = sin(dLng) * cos(radians(lat2));
    double x = cos(radians(lat1)) * sin(radians(lat2)) -
               sin(radians(lat1)) * cos(radians(lat2)) * cos(dLng);
    float bearing = (float)(degrees(atan2(y, x)));
    return fmod(bearing + 360.0f, 360.0f);
}
