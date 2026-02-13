"""
Wave Prediction Model — Training Pipeline
Runs on your gaming PC (RTX 3050) to train the wave prediction model.

Takes camera frames + boat motion data collected on the water,
learns to predict boat displacement from wave patterns.

Usage:
    python train_wave_model.py --data /path/to/wave_data --epochs 50
    python train_wave_model.py --export  (export trained model to TFLite)
"""

import argparse
import json
from pathlib import Path

import cv2
import numpy as np
import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import Dataset, DataLoader


# ============================================================
# Dataset — Loads frame sequences + boat motion labels
# ============================================================

class WaveDataset(Dataset):
    """
    Each sample: 5 consecutive grayscale frames → boat displacement 1-2 sec later.
    Input:  (5, 160, 160) grayscale frames
    Output: (dx, dy) displacement in meters
    """

    def __init__(self, data_dir, sequence_len=5, predict_ahead=15):
        """
        Args:
            data_dir: Path to wave_data directory containing session folders
            sequence_len: Number of consecutive frames as input
            predict_ahead: Frames ahead to predict displacement (15 frames @ 15fps = 1 sec)
        """
        self.sequence_len = sequence_len
        self.predict_ahead = predict_ahead
        self.samples = []

        data_path = Path(data_dir)
        sessions = sorted(data_path.glob("session_*"))
        print(f"Found {len(sessions)} recording sessions")

        for session in sessions:
            meta_path = session / "metadata.json"
            if not meta_path.exists():
                continue

            with open(meta_path) as f:
                metadata = json.load(f)

            frames_dir = session / "frames"
            num_frames = len(metadata)

            # Create samples: each is (start_idx, session_path, metadata)
            for i in range(num_frames - sequence_len - predict_ahead):
                # Only use samples where we have GPS data for the label
                future_idx = i + sequence_len + predict_ahead
                current_boat = metadata[i + sequence_len - 1].get("boat", {})
                future_boat = metadata[future_idx].get("boat", {})

                if current_boat.get("gps_valid") and future_boat.get("gps_valid"):
                    self.samples.append({
                        "start_idx": i,
                        "frames_dir": frames_dir,
                        "current_boat": current_boat,
                        "future_boat": future_boat
                    })

        print(f"Total training samples: {len(self.samples)}")

    def __len__(self):
        return len(self.samples)

    def __getitem__(self, idx):
        sample = self.samples[idx]

        # Load frame sequence
        frames = []
        for i in range(self.sequence_len):
            frame_idx = sample["start_idx"] + i
            path = sample["frames_dir"] / f"{frame_idx:06d}.jpg"
            img = cv2.imread(str(path), cv2.IMREAD_GRAYSCALE)
            if img is None:
                img = np.zeros((160, 160), dtype=np.uint8)
            img = cv2.resize(img, (160, 160))
            frames.append(img.astype(np.float32) / 255.0)

        frames = np.stack(frames)  # (5, 160, 160)

        # Calculate displacement label (meters)
        curr = sample["current_boat"]
        future = sample["future_boat"]
        dx = future.get("lat", 0) - curr.get("lat", 0)
        dy = future.get("lng", 0) - curr.get("lng", 0)

        # Convert rough lat/lng diff to meters
        # 1 degree lat ≈ 111,139 meters, 1 degree lng ≈ 111,139 * cos(lat)
        lat_rad = curr.get("lat", 35.0) * np.pi / 180.0
        dx_m = dx * 111139.0
        dy_m = dy * 111139.0 * np.cos(lat_rad)

        label = np.array([dx_m, dy_m], dtype=np.float32)

        return torch.tensor(frames), torch.tensor(label)


# ============================================================
# Model — Lightweight CNN + Temporal for wave prediction
# ============================================================

class WaveNet(nn.Module):
    """
    Input: (batch, 5, 160, 160) — 5 grayscale frames
    Output: (batch, 2) — predicted dx, dy displacement in meters

    Small enough to run on RPi + Coral TPU after conversion.
    ~800K parameters.
    """

    def __init__(self, num_frames=5):
        super().__init__()
        self.num_frames = num_frames

        # Per-frame feature extractor (shared weights across frames)
        self.frame_encoder = nn.Sequential(
            nn.Conv2d(1, 16, 5, stride=2, padding=2),  # 160→80
            nn.BatchNorm2d(16),
            nn.ReLU(),
            nn.Conv2d(16, 32, 3, stride=2, padding=1),  # 80→40
            nn.BatchNorm2d(32),
            nn.ReLU(),
            nn.Conv2d(32, 64, 3, stride=2, padding=1),  # 40→20
            nn.BatchNorm2d(64),
            nn.ReLU(),
            nn.Conv2d(64, 64, 3, stride=2, padding=1),  # 20→10
            nn.BatchNorm2d(64),
            nn.ReLU(),
            nn.AdaptiveAvgPool2d(4),                      # 10→4
            nn.Flatten(),                                  # 64*4*4 = 1024
        )

        # Temporal model — processes sequence of frame features
        self.temporal = nn.Sequential(
            nn.Linear(1024 * num_frames, 256),
            nn.ReLU(),
            nn.Dropout(0.3),
            nn.Linear(256, 64),
            nn.ReLU(),
            nn.Dropout(0.2),
        )

        # Prediction head
        self.predictor = nn.Sequential(
            nn.Linear(64, 32),
            nn.ReLU(),
            nn.Linear(32, 2),   # dx, dy
        )

    def forward(self, x):
        batch_size = x.shape[0]

        # Process each frame through shared encoder
        frame_features = []
        for t in range(self.num_frames):
            frame = x[:, t:t+1, :, :]  # (batch, 1, 160, 160)
            feat = self.frame_encoder(frame)  # (batch, 1024)
            frame_features.append(feat)

        # Concatenate temporal features
        combined = torch.cat(frame_features, dim=1)  # (batch, 5*1024)

        # Temporal processing
        temporal_out = self.temporal(combined)

        # Predict displacement
        prediction = self.predictor(temporal_out)
        return prediction


# ============================================================
# Training Loop
# ============================================================

def train(data_dir, epochs=50, batch_size=16, lr=0.001):
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Training device: {device}")
    if device.type == "cuda":
        print(f"GPU: {torch.cuda.get_device_name(0)}")

    # Dataset
    dataset = WaveDataset(data_dir)
    if len(dataset) == 0:
        print("No training data found. Collect data on the water first.")
        print("  1. Copy wave_data sessions from RPi SD card to this machine")
        print("  2. Run: python train_wave_model.py --data /path/to/wave_data")
        return

    # Split 80/20 train/val
    train_size = int(0.8 * len(dataset))
    val_size = len(dataset) - train_size
    train_set, val_set = torch.utils.data.random_split(dataset, [train_size, val_size])

    train_loader = DataLoader(train_set, batch_size=batch_size, shuffle=True,
                              num_workers=2, pin_memory=True)
    val_loader = DataLoader(val_set, batch_size=batch_size, shuffle=False,
                            num_workers=2, pin_memory=True)

    print(f"Training samples: {train_size} | Validation: {val_size}")

    # Model
    model = WaveNet().to(device)
    total_params = sum(p.numel() for p in model.parameters())
    print(f"Model parameters: {total_params:,}")

    optimizer = optim.Adam(model.parameters(), lr=lr, weight_decay=1e-4)
    scheduler = optim.lr_scheduler.ReduceLROnPlateau(optimizer, patience=5, factor=0.5)
    criterion = nn.MSELoss()

    best_val_loss = float("inf")

    for epoch in range(epochs):
        # Train
        model.train()
        train_loss = 0
        for frames, labels in train_loader:
            frames = frames.to(device)
            labels = labels.to(device)

            pred = model(frames)
            loss = criterion(pred, labels)

            optimizer.zero_grad()
            loss.backward()
            optimizer.step()

            train_loss += loss.item()

        train_loss /= len(train_loader)

        # Validate
        model.eval()
        val_loss = 0
        with torch.no_grad():
            for frames, labels in val_loader:
                frames = frames.to(device)
                labels = labels.to(device)
                pred = model(frames)
                val_loss += criterion(pred, labels).item()

        val_loss /= len(val_loader)
        scheduler.step(val_loss)

        # Save best
        if val_loss < best_val_loss:
            best_val_loss = val_loss
            torch.save(model.state_dict(), "model/wave_model_best.pth")
            marker = " *saved*"
        else:
            marker = ""

        print(f"Epoch {epoch+1:3d}/{epochs} | "
              f"Train: {train_loss:.6f} | Val: {val_loss:.6f} | "
              f"LR: {optimizer.param_groups[0]['lr']:.6f}{marker}")

    print(f"\nTraining complete. Best val loss: {best_val_loss:.6f}")
    print("Model saved to model/wave_model_best.pth")


# ============================================================
# Export to TFLite (for RPi / Coral TPU deployment)
# ============================================================

def export_tflite():
    print("Exporting model to TFLite format...")

    model = WaveNet()
    model.load_state_dict(torch.load("model/wave_model_best.pth",
                                     map_location="cpu"))
    model.eval()

    # Export to ONNX first
    dummy = torch.randn(1, 5, 160, 160)
    onnx_path = "model/wave_model.onnx"
    torch.onnx.export(model, dummy, onnx_path,
                      input_names=["frames"],
                      output_names=["displacement"],
                      opset_version=13)
    print(f"ONNX exported to {onnx_path}")

    # Convert ONNX to TFLite
    try:
        import onnx
        from onnx_tf.backend import prepare
        import tensorflow as tf

        onnx_model = onnx.load(onnx_path)
        tf_rep = prepare(onnx_model)
        tf_rep.export_graph("model/wave_model_tf")

        converter = tf.lite.TFLiteConverter.from_saved_model("model/wave_model_tf")
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        tflite_model = converter.convert()

        tflite_path = "model/wave_model.tflite"
        with open(tflite_path, "wb") as f:
            f.write(tflite_model)
        print(f"TFLite exported to {tflite_path}")
        print("Copy this file to RPi: scp model/wave_model.tflite pi@<rpi-ip>:~/model/")

    except ImportError:
        print("\nTo convert to TFLite, install:")
        print("  pip install onnx onnx-tf tensorflow")
        print(f"\nONNX model is ready at {onnx_path}")
        print("You can convert it manually or use the ONNX model directly.")


# ============================================================
# Main
# ============================================================

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Wave Prediction Model Training")
    parser.add_argument("--data", type=str, default="data",
                        help="Path to wave_data directory")
    parser.add_argument("--epochs", type=int, default=50)
    parser.add_argument("--batch-size", type=int, default=16)
    parser.add_argument("--lr", type=float, default=0.001)
    parser.add_argument("--export", action="store_true",
                        help="Export trained model to TFLite")
    args = parser.parse_args()

    Path("model").mkdir(exist_ok=True)

    if args.export:
        export_tflite()
    else:
        train(args.data, args.epochs, args.batch_size, args.lr)
