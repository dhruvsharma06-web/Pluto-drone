"""Train the Pluto CW/CCW propeller detector (YOLO11) and export ONNX for Android.

Usage (repo root, CUDA PyTorch + ultralytics installed):
    python ml/scripts/train_propeller.py --data <dataset>/data.yaml --model yolo11s.pt

Horizontal/vertical flips are DISABLED on purpose: mirroring a CW propeller
produces the shape of a CCW propeller, which would corrupt the class labels.
"""
import argparse

from ultralytics import YOLO


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--data', required=True)
    ap.add_argument('--model', default='yolo11s.pt')
    ap.add_argument('--epochs', type=int, default=150)
    ap.add_argument('--imgsz', type=int, default=800)
    ap.add_argument('--batch', type=int, default=8)
    ap.add_argument('--name', default='propeller')
    ap.add_argument('--device', default='0')
    a = ap.parse_args()
    model = YOLO(a.model)
    model.train(data=a.data, epochs=a.epochs, imgsz=a.imgsz, batch=a.batch,
                device=a.device, name=a.name, exist_ok=True, workers=0,
                fliplr=0.0, flipud=0.0,  # chirality-preserving
                degrees=20, translate=0.2, scale=0.6, mosaic=1.0, mixup=0.15,
                hsv_h=0.03, hsv_s=0.7, hsv_v=0.5, close_mosaic=15, patience=50)
    best = YOLO(f'{model.trainer.save_dir}/weights/best.pt')
    best.val(data=a.data, split='test', imgsz=a.imgsz, device=a.device)
    # Android engine expects 640x640 input, output [1, 6, 8400].
    best.export(format='onnx', imgsz=640, opset=12, simplify=True, dynamic=False)


if __name__ == '__main__':
    main()
