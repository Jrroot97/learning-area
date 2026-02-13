"""
Wave Data Collector — Runs on Raspberry Pi Zero 2W
Captures camera frames + IMU/GPS data from ESP32 for ML training.
Also runs trained model for real-time wave predictions.

Usage:
    Collect training data:  python3 wave_collector.py --collect
    Run predictions:        python3 wave_collector.py --predict
"""

import argparse
import json
import os
import time
from datetime import datetime
from pathlib import Path

import cv2
import numpy as np
import serial

# ============================================================
# Configuration
# ============================================================

CAMERA_INDEX = 0            # CSI camera = 0
FRAME_WIDTH = 320
FRAME_HEIGHT = 240
FPS = 15
SERIAL_PORT = "/dev/ttyS0"  # UART to ESP32
SERIAL_BAUD = 115200
DATA_DIR = Path("/home/pi/wave_data")

# ============================================================
# Data Collector — Records frames + boat motion for training
# ============================================================

class WaveDataCollector:
    def __init__(self):
        self.cap = None
        self.ser = None
        self.session_dir = None
        self.frame_count = 0

    def start(self):
        """Start camera and serial connection."""
        # Camera
        self.cap = cv2.VideoCapture(CAMERA_INDEX)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, FRAME_WIDTH)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_HEIGHT)
        self.cap.set(cv2.CAP_PROP_FPS, FPS)

        if not self.cap.isOpened():
            raise RuntimeError("Cannot open camera")

        # Serial to ESP32
        try:
            self.ser = serial.Serial(SERIAL_PORT, SERIAL_BAUD, timeout=0.1)
            print(f"[SERIAL] Connected to ESP32 on {SERIAL_PORT}")
        except serial.SerialException as e:
            print(f"[SERIAL] Warning: {e} — collecting frames only")
            self.ser = None

        # Session directory
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        self.session_dir = DATA_DIR / f"session_{timestamp}"
        self.session_dir.mkdir(parents=True, exist_ok=True)
        (self.session_dir / "frames").mkdir(exist_ok=True)

        print(f"[COLLECTOR] Session: {self.session_dir}")
        print(f"[COLLECTOR] Camera: {FRAME_WIDTH}x{FRAME_HEIGHT} @ {FPS}fps")
        print("[COLLECTOR] Recording... Press Ctrl+C to stop\n")

    def collect_loop(self):
        """Main collection loop — run until Ctrl+C."""
        metadata = []

        try:
            while True:
                loop_start = time.time()

                # Capture frame
                ret, frame = self.cap.read()
                if not ret:
                    continue

                # Convert to grayscale (smaller files, ML doesn't need color)
                gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)

                # Save frame
                frame_path = self.session_dir / "frames" / f"{self.frame_count:06d}.jpg"
                cv2.imwrite(str(frame_path), gray,
                           [cv2.IMWRITE_JPEG_QUALITY, 85])

                # Read boat state from ESP32
                boat_state = self._read_esp32_state()

                # Record metadata
                entry = {
                    "frame": self.frame_count,
                    "timestamp": time.time(),
                    "boat": boat_state
                }
                metadata.append(entry)
                self.frame_count += 1

                # Status update every 100 frames
                if self.frame_count % 100 == 0:
                    print(f"  Frames: {self.frame_count} | "
                          f"GPS: {'yes' if boat_state.get('gps_valid') else 'no'} | "
                          f"Wind: {boat_state.get('wind_mph', 'N/A')} mph")

                # Maintain target FPS
                elapsed = time.time() - loop_start
                sleep_time = (1.0 / FPS) - elapsed
                if sleep_time > 0:
                    time.sleep(sleep_time)

        except KeyboardInterrupt:
            print(f"\n[COLLECTOR] Stopped. {self.frame_count} frames captured.")

        # Save metadata
        meta_path = self.session_dir / "metadata.json"
        with open(meta_path, "w") as f:
            json.dump(metadata, f)
        print(f"[COLLECTOR] Metadata saved to {meta_path}")

        self.stop()

    def _read_esp32_state(self):
        """Read JSON state from ESP32 via UART."""
        if not self.ser:
            return {}

        try:
            if self.ser.in_waiting > 0:
                line = self.ser.readline().decode("utf-8", errors="ignore").strip()
                if line.startswith("{"):
                    return json.loads(line)
        except (json.JSONDecodeError, UnicodeDecodeError):
            pass
        return {}

    def stop(self):
        if self.cap:
            self.cap.release()
        if self.ser:
            self.ser.close()


# ============================================================
# Wave Predictor — Runs trained model, sends predictions to ESP32
# ============================================================

class WavePredictor:
    def __init__(self, model_path="model/wave_model.tflite"):
        self.model_path = model_path
        self.cap = None
        self.ser = None
        self.interpreter = None
        self.frame_buffer = []
        self.buffer_size = 5  # 5 consecutive frames as input

    def start(self):
        """Load model and start camera."""
        # Try to load TFLite model (for Coral TPU or CPU)
        try:
            import tflite_runtime.interpreter as tflite
            # Try Coral TPU first
            try:
                delegate = tflite.load_delegate("libedgetpu.so.1")
                self.interpreter = tflite.Interpreter(
                    model_path=self.model_path,
                    experimental_delegates=[delegate])
                print("[MODEL] Loaded on Coral TPU")
            except (ValueError, OSError):
                self.interpreter = tflite.Interpreter(model_path=self.model_path)
                print("[MODEL] Loaded on CPU (no Coral TPU found)")

            self.interpreter.allocate_tensors()
        except ImportError:
            print("[MODEL] tflite_runtime not installed — prediction disabled")
            print("[MODEL] Install: pip3 install tflite-runtime")
            self.interpreter = None

        # Camera
        self.cap = cv2.VideoCapture(CAMERA_INDEX)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, FRAME_WIDTH)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, FRAME_HEIGHT)
        self.cap.set(cv2.CAP_PROP_FPS, FPS)

        # Serial to ESP32
        try:
            self.ser = serial.Serial(SERIAL_PORT, SERIAL_BAUD, timeout=0.1)
        except serial.SerialException:
            self.ser = None

        print("[PREDICTOR] Running. Press Ctrl+C to stop.\n")

    def predict_loop(self):
        """Main prediction loop."""
        try:
            while True:
                loop_start = time.time()

                ret, frame = self.cap.read()
                if not ret:
                    continue

                gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
                resized = cv2.resize(gray, (160, 160))
                normalized = resized.astype(np.float32) / 255.0

                self.frame_buffer.append(normalized)
                if len(self.frame_buffer) > self.buffer_size:
                    self.frame_buffer.pop(0)

                # Need full buffer to predict
                if len(self.frame_buffer) < self.buffer_size:
                    continue

                if self.interpreter:
                    prediction = self._run_inference()
                    self._send_prediction(prediction)

                elapsed = time.time() - loop_start
                sleep_time = (1.0 / FPS) - elapsed
                if sleep_time > 0:
                    time.sleep(sleep_time)

        except KeyboardInterrupt:
            print("\n[PREDICTOR] Stopped.")
            self.stop()

    def _run_inference(self):
        """Run the TFLite model on current frame buffer."""
        input_details = self.interpreter.get_input_details()
        output_details = self.interpreter.get_output_details()

        # Stack frames: (1, 5, 160, 160)
        input_data = np.array(self.frame_buffer).reshape(1, self.buffer_size, 160, 160)
        input_data = input_data.astype(np.float32)

        self.interpreter.set_tensor(input_details[0]["index"], input_data)
        self.interpreter.invoke()

        output = self.interpreter.get_tensor(output_details[0]["index"])
        # Output: [dx, dy, confidence]
        return {
            "dx": float(output[0][0]),
            "dy": float(output[0][1]),
            "conf": float(output[0][2]) if len(output[0]) > 2 else 0.5
        }

    def _send_prediction(self, pred):
        """Send prediction to ESP32 via UART."""
        if not self.ser:
            return

        msg = json.dumps(pred) + "\n"
        self.ser.write(msg.encode("utf-8"))

    def stop(self):
        if self.cap:
            self.cap.release()
        if self.ser:
            self.ser.close()


# ============================================================
# Main
# ============================================================

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Wave Data Collector / Predictor")
    parser.add_argument("--collect", action="store_true", help="Collect training data")
    parser.add_argument("--predict", action="store_true", help="Run wave predictions")
    args = parser.parse_args()

    if args.collect:
        collector = WaveDataCollector()
        collector.start()
        collector.collect_loop()
    elif args.predict:
        predictor = WavePredictor()
        predictor.start()
        predictor.predict_loop()
    else:
        print("Usage:")
        print("  python3 wave_collector.py --collect   (record training data)")
        print("  python3 wave_collector.py --predict   (run wave predictions)")
