#include "web_dashboard.h"

void WebDashboard::begin() {
    WiFi.softAP(WIFI_SSID, WIFI_PASSWORD);
    Serial.printf("[DASH] WiFi AP started: %s (IP: %s)\n",
                  WIFI_SSID, WiFi.softAPIP().toString().c_str());

    setupRoutes();
    _server.addHandler(&_events);
    _server.begin();
    Serial.println("[DASH] Web dashboard running on port 80");
}

void WebDashboard::update(GpsModule& gps, ImuModule& imu, WindSensor& wind,
                          Sensors& sensors, MotorControl& motor) {
    unsigned long now = millis();
    unsigned long interval = 1000 / DASHBOARD_UPDATE_HZ;

    if (now - _lastPush < interval) return;
    _lastPush = now;

    String json = buildStatusJson(gps, imu, wind, sensors, motor);
    _events.send(json.c_str(), "status", millis());
}

void WebDashboard::setupRoutes() {
    // Serve main page
    _server.on("/", HTTP_GET, [](AsyncWebServerRequest *request) {
        request->send(200, "text/html", getPageHtml());
    });

    // API: Set anchor (spot-lock)
    _server.on("/api/anchor", HTTP_POST, [this](AsyncWebServerRequest *request) {
        if (_onAnchor) _onAnchor();
        request->send(200, "application/json", "{\"ok\":true}");
    });

    // API: Clear anchor
    _server.on("/api/anchor/clear", HTTP_POST, [this](AsyncWebServerRequest *request) {
        if (_onClearAnchor) _onClearAnchor();
        request->send(200, "application/json", "{\"ok\":true}");
    });

    // API: Lock heading
    _server.on("/api/heading/lock", HTTP_POST, [this](AsyncWebServerRequest *request) {
        if (_onHeadingLock) _onHeadingLock();
        request->send(200, "application/json", "{\"ok\":true}");
    });

    // API: Clear heading lock
    _server.on("/api/heading/clear", HTTP_POST, [this](AsyncWebServerRequest *request) {
        if (_onClearHeadingLock) _onClearHeadingLock();
        request->send(200, "application/json", "{\"ok\":true}");
    });

    // API: Emergency stop
    _server.on("/api/stop", HTTP_POST, [this](AsyncWebServerRequest *request) {
        if (_onStop) _onStop();
        request->send(200, "application/json", "{\"ok\":true}");
    });

    // API: Save current spot
    _server.on("/api/spot/save", HTTP_POST, [this](AsyncWebServerRequest *request) {
        String name = request->hasParam("name", true) ?
                      request->getParam("name", true)->value() : "Spot";
        if (_onSaveSpot) _onSaveSpot(name.c_str());
        request->send(200, "application/json", "{\"ok\":true}");
    });
}

String WebDashboard::buildStatusJson(GpsModule& gps, ImuModule& imu,
                                     WindSensor& wind, Sensors& sensors,
                                     MotorControl& motor) {
    JsonDocument doc;

    // GPS
    GpsPosition pos = gps.getPosition();
    doc["gps"]["lat"] = pos.lat;
    doc["gps"]["lng"] = pos.lng;
    doc["gps"]["sats"] = pos.satellites;
    doc["gps"]["hdop"] = pos.hdop;
    doc["gps"]["fix"] = gps.hasFix();

    // Anchor
    doc["anchor"]["active"] = gps.isAnchored();
    if (gps.isAnchored()) {
        AnchorError err = gps.getAnchorError();
        doc["anchor"]["dist_m"] = err.distance_m;
        doc["anchor"]["dist_ft"] = err.distance_m * 3.281f;
        doc["anchor"]["bearing"] = err.bearing_deg;
    }

    // Heading
    ImuData imuData = imu.getData();
    doc["heading"]["current"] = imuData.heading;
    doc["heading"]["locked"] = imu.isHeadingLocked();
    doc["heading"]["target"] = imu.getLockedHeading();
    doc["heading"]["error"] = imu.getHeadingError();
    doc["heading"]["pitch"] = imuData.pitch;
    doc["heading"]["roll"] = imuData.roll;
    doc["heading"]["calibration"] = imuData.calibration;

    // Wind
    WindData windData = wind.getData();
    doc["wind"]["speed_mph"] = windData.speed_mph;
    doc["wind"]["speed_mps"] = windData.speed_mps;
    doc["wind"]["direction"] = windData.direction_deg;
    doc["wind"]["gust_mph"] = windData.gust_mps * 2.237f;
    doc["wind"]["valid"] = wind.isValid();
    doc["wind"]["increasing"] = wind.isIncreasing();
    doc["wind"]["gusting"] = wind.isGusting();

    // Motor
    doc["motor"]["thrust"] = motor.getCurrentThrust();
    doc["motor"]["angle"] = motor.getCurrentAngle();
    doc["motor"]["current_a"] = motor.getEstimatedCurrentDraw();
    doc["motor"]["killed"] = motor.isKilled();

    // Sensors
    SonarData sonar = sensors.getSonar();
    doc["depth"]["ft"] = sonar.depth_ft;
    doc["depth"]["m"] = sonar.depth_m;
    doc["depth"]["valid"] = sonar.valid;

    doc["water_temp"]["f"] = sensors.getWaterTempF();
    doc["water_temp"]["c"] = sensors.getWaterTempC();

    BatteryStatus batt = sensors.getBattery();
    doc["battery"]["voltage"] = batt.voltage;
    doc["battery"]["percent"] = batt.percentage;
    doc["battery"]["hours_left"] = batt.estimatedHoursLeft;
    doc["battery"]["low"] = batt.low;
    doc["battery"]["critical"] = batt.critical;

    // Wave intensity
    doc["waves"]["intensity"] = imu.getWaveIntensity();

    String output;
    serializeJson(doc, output);
    return output;
}

const char* WebDashboard::getPageHtml() {
    static const char html[] PROGMEM = R"rawliteral(
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1,user-scalable=no">
<title>Spot-Lock</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,sans-serif;background:#0a1628;color:#e0e6f0;min-height:100vh;padding:12px}
.hdr{text-align:center;padding:8px 0 12px;font-size:20px;font-weight:700;color:#4fc3f7}
.grid{display:grid;grid-template-columns:1fr 1fr;gap:10px;max-width:500px;margin:0 auto}
.card{background:#1a2744;border-radius:12px;padding:14px;border:1px solid #2a3f5f}
.card.full{grid-column:1/-1}
.card h3{font-size:11px;text-transform:uppercase;letter-spacing:1px;color:#78909c;margin-bottom:8px}
.val{font-size:28px;font-weight:700;color:#fff}
.val.sm{font-size:18px}
.unit{font-size:12px;color:#78909c;margin-left:4px}
.sub{font-size:12px;color:#90a4ae;margin-top:4px}
.row{display:flex;justify-content:space-between;align-items:center}
.tag{display:inline-block;padding:3px 8px;border-radius:6px;font-size:11px;font-weight:600}
.tag.green{background:#1b5e20;color:#66bb6a}
.tag.red{background:#b71c1c;color:#ef5350}
.tag.yellow{background:#f57f17;color:#fdd835}
.tag.blue{background:#0d47a1;color:#42a5f5}
.btn{width:100%;padding:14px;border:none;border-radius:10px;font-size:16px;font-weight:700;cursor:pointer;margin-top:6px;transition:opacity .2s}
.btn:active{opacity:.7}
.btn-anchor{background:#1b5e20;color:#66bb6a}
.btn-anchor.active{background:#b71c1c;color:#ef5350}
.btn-heading{background:#0d47a1;color:#42a5f5}
.btn-heading.active{background:#b71c1c;color:#ef5350}
.btn-stop{background:#d32f2f;color:#fff;font-size:20px;padding:18px}
.btn-save{background:#1a237e;color:#7c4dff}
.compass{width:80px;height:80px;border-radius:50%;border:2px solid #2a3f5f;margin:0 auto;position:relative}
.compass .needle{position:absolute;top:50%;left:50%;width:2px;height:35px;background:#f44336;transform-origin:bottom center;margin-left:-1px;margin-top:-35px;border-radius:1px}
.compass .dot{position:absolute;top:50%;left:50%;width:6px;height:6px;background:#4fc3f7;border-radius:50%;margin:-3px}
.batt-bar{height:8px;background:#1a2744;border-radius:4px;border:1px solid #2a3f5f;overflow:hidden;margin-top:6px}
.batt-fill{height:100%;border-radius:3px;transition:width .5s}
</style>
</head>
<body>
<div class="hdr">SPOT-LOCK</div>
<div class="grid">

<div class="card full">
 <div class="row">
  <div>
   <h3>Anchor Drift</h3>
   <div class="val" id="drift">--</div>
   <div class="sub" id="drift-sub">GPS searching...</div>
  </div>
  <div id="anchor-tag"></div>
 </div>
</div>

<div class="card">
 <h3>Heading</h3>
 <div class="compass"><div class="needle" id="needle"></div><div class="dot"></div></div>
 <div class="sub" style="text-align:center;margin-top:6px" id="hdg-text">--</div>
</div>

<div class="card">
 <h3>Wind</h3>
 <div class="val sm" id="wind-speed">--</div>
 <div class="sub" id="wind-dir">--</div>
 <div class="sub" id="wind-gust"></div>
</div>

<div class="card">
 <h3>Depth</h3>
 <div class="val sm" id="depth">--</div>
</div>

<div class="card">
 <h3>Water Temp</h3>
 <div class="val sm" id="wtemp">--</div>
</div>

<div class="card">
 <h3>Motor</h3>
 <div class="val sm" id="motor-thrust">0%</div>
 <div class="sub" id="motor-current">0.0 A</div>
</div>

<div class="card">
 <h3>Battery</h3>
 <div class="val sm" id="batt-v">--</div>
 <div class="batt-bar"><div class="batt-fill" id="batt-fill" style="width:0%;background:#66bb6a"></div></div>
 <div class="sub" id="batt-time">-- hrs left</div>
</div>

<div class="card full">
 <h3>Waves</h3>
 <div class="row">
  <div class="val sm" id="wave-int">Calm</div>
  <span class="tag blue" id="wave-tag">Calm</span>
 </div>
</div>

<div class="card full">
 <button class="btn btn-anchor" id="btn-anchor" onclick="toggleAnchor()">DROP ANCHOR</button>
</div>
<div class="card full">
 <button class="btn btn-heading" id="btn-heading" onclick="toggleHeading()">LOCK HEADING</button>
</div>
<div class="card full">
 <button class="btn btn-stop" onclick="emergencyStop()">EMERGENCY STOP</button>
</div>
<div class="card full">
 <button class="btn btn-save" onclick="saveSpot()">SAVE THIS SPOT</button>
</div>

</div>

<script>
let anchored=false,headingLocked=false;
const es=new EventSource('/events');
es.addEventListener('status',e=>{
 const d=JSON.parse(e.data);

 // Anchor drift
 if(d.anchor.active){
  const ft=(d.anchor.dist_m*3.281).toFixed(1);
  document.getElementById('drift').textContent=ft+' ft';
  document.getElementById('drift-sub').textContent=
   d.anchor.dist_m.toFixed(1)+'m | bearing '+d.anchor.bearing.toFixed(0)+'°';
  document.getElementById('anchor-tag').innerHTML=
   '<span class="tag green">LOCKED</span>';
 }else{
  document.getElementById('drift').textContent='--';
  document.getElementById('drift-sub').textContent=
   d.gps.fix?d.gps.sats+' sats | HDOP '+d.gps.hdop.toFixed(1):'GPS searching...';
  document.getElementById('anchor-tag').innerHTML=
   '<span class="tag yellow">FREE</span>';
 }
 anchored=d.anchor.active;
 const ab=document.getElementById('btn-anchor');
 ab.textContent=anchored?'RELEASE ANCHOR':'DROP ANCHOR';
 ab.className='btn btn-anchor'+(anchored?' active':'');

 // Heading
 document.getElementById('needle').style.transform=
  'rotate('+d.heading.current+'deg)';
 let ht=d.heading.current.toFixed(0)+'°';
 if(d.heading.locked)ht+=' → '+d.heading.target.toFixed(0)+'° (err '+
  d.heading.error.toFixed(1)+'°)';
 document.getElementById('hdg-text').textContent=ht;
 headingLocked=d.heading.locked;
 const hb=document.getElementById('btn-heading');
 hb.textContent=headingLocked?'UNLOCK HEADING':'LOCK HEADING';
 hb.className='btn btn-heading'+(headingLocked?' active':'');

 // Wind
 if(d.wind.valid){
  document.getElementById('wind-speed').textContent=
   d.wind.speed_mph.toFixed(1)+' mph';
  document.getElementById('wind-dir').textContent=
   'From '+d.wind.direction.toFixed(0)+'°';
  document.getElementById('wind-gust').textContent=
   d.wind.gusting?'Gusting '+d.wind.gust_mph.toFixed(1)+' mph':'';
 }else{
  document.getElementById('wind-speed').textContent='N/A';
  document.getElementById('wind-dir').textContent='No signal';
 }

 // Depth
 document.getElementById('depth').textContent=
  d.depth.valid?d.depth.ft.toFixed(1)+' ft':'--';

 // Water temp
 document.getElementById('wtemp').textContent=d.water_temp.f.toFixed(1)+'°F';

 // Motor
 document.getElementById('motor-thrust').textContent=
  (Math.abs(d.motor.thrust)*100).toFixed(0)+'%';
 document.getElementById('motor-current').textContent=
  d.motor.current_a.toFixed(1)+' A draw';

 // Battery
 document.getElementById('batt-v').textContent=
  d.battery.voltage.toFixed(1)+'V';
 const bp=d.battery.percent;
 const bf=document.getElementById('batt-fill');
 bf.style.width=bp+'%';
 bf.style.background=bp>50?'#66bb6a':bp>20?'#fdd835':'#ef5350';
 document.getElementById('batt-time').textContent=
  d.battery.hours_left<90?d.battery.hours_left.toFixed(1)+' hrs left':'--';

 // Waves
 const wi=d.waves.intensity;
 let wl='Calm',wc='blue';
 if(wi>2){wl='Heavy';wc='red';}
 else if(wi>1){wl='Moderate';wc='yellow';}
 else if(wi>0.3){wl='Light';wc='green';}
 document.getElementById('wave-int').textContent=wl+' ('+wi.toFixed(2)+' m/s²)';
 const wt=document.getElementById('wave-tag');
 wt.textContent=wl;wt.className='tag '+wc;
});

function toggleAnchor(){
 fetch(anchored?'/api/anchor/clear':'/api/anchor',{method:'POST'});
}
function toggleHeading(){
 fetch(headingLocked?'/api/heading/clear':'/api/heading/lock',{method:'POST'});
}
function emergencyStop(){
 fetch('/api/stop',{method:'POST'});
}
function saveSpot(){
 const n=prompt('Spot name:');
 if(n)fetch('/api/spot/save',{method:'POST',
  headers:{'Content-Type':'application/x-www-form-urlencoded'},
  body:'name='+encodeURIComponent(n)});
}
</script>
</body>
</html>
)rawliteral";
    return html;
}
