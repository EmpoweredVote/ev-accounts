"""Shared portrait handling for headshot importers.

Two defects reached production because every importer rolled its own PIL pipeline and
none of them checked either of these:

  1. EXIF orientation was never applied, so a phone-camera source was stored on its side.
     Lynn Fitch (MS Attorney General) shipped rotated 90 degrees.
  2. Nothing asked whether the frame contained a face, so an office seal, an election
     results map and a blank white frame all imported cleanly. Michael Watson (MS
     Secretary of State) shipped as the Mississippi Secretary of State seal.

Neither is visible to any other gate: both files were 600x750, exactly 4:5, in colour,
correctly licensed, and the database columns agreed with each other.

Use `open_portrait()` instead of `Image.open()`, and `assert_portrait()` before upload.
"""
from __future__ import annotations

import hashlib
import io
import os
import urllib.request

from PIL import Image, ImageOps

TARGET_SIZE = (600, 750)

# opencv_zoo YuNet. The plain raw.githubusercontent URL serves a ~131 byte Git LFS
# POINTER, not the model, and opencv then fails with an unhelpful ONNX parse error -
# so fetch through the media host and verify the bytes.
_MODEL_URL = (
    "https://media.githubusercontent.com/media/opencv/opencv_zoo/main/"
    "models/face_detection_yunet/face_detection_yunet_2023mar.onnx"
)
_MODEL_SHA256 = "8f2383e4dd3cfbb4553ea8718107fc0423210dc964f9f4280604804ed2552fa4"
_MODEL_MIN_BYTES = 200_000

_FACE_CONFIDENCE = 0.80   # a face this confident is really there
_ROTATIONS = (0, 90, 180, 270)
_WORK_MIN, _WORK_MAX = 400, 1200   # longest edge the detector sees; see _best_face

import threading

# One detector PER THREAD. setInputSize() mutates the detector and detect() reads it, so a
# detector shared between worker threads races and takes the process down with a hard crash
# (exit 127, no traceback) rather than a Python exception.
_tls = threading.local()


class PortraitRejected(Exception):
    """The image is not usable as a headshot. The message says why."""


def open_portrait(data: bytes | str) -> Image.Image:
    """Open image bytes (or a path) as RGB with EXIF orientation APPLIED.

    `Image.open` does not honour the EXIF Orientation tag; `exif_transpose` does. Without
    it a phone photo tagged Orientation=6 is written out rotated 90 degrees clockwise.
    """
    img = Image.open(data if isinstance(data, str) else io.BytesIO(data))
    img = ImageOps.exif_transpose(img)          # the line whose absence shipped Lynn Fitch sideways
    # A PNG cutout's RGB UNDER fully transparent pixels is arbitrary, and `convert("RGB")` drops
    # alpha without compositing - so a transparent background renders as whatever junk was stored
    # there. Kansas's portrait came out on a near-black halo. Composite onto white instead.
    if img.mode in ("RGBA", "LA") or (img.mode == "P" and "transparency" in img.info):
        img = img.convert("RGBA")
        flat = Image.new("RGBA", img.size, (255, 255, 255, 255))
        img = Image.alpha_composite(flat, img)
    if img.mode != "RGB":
        img = img.convert("RGB")
    return img


def model_path() -> str:
    """Path to the YuNet model, downloading it once into a cache dir if absent."""
    cache = os.environ.get(
        "EV_HEADSHOT_MODEL_DIR",
        os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", ".cache"),
    )
    os.makedirs(cache, exist_ok=True)
    path = os.path.join(cache, "face_detection_yunet_2023mar.onnx")
    if os.path.exists(path) and os.path.getsize(path) >= _MODEL_MIN_BYTES:
        return path
    req = urllib.request.Request(_MODEL_URL, headers={"User-Agent": "EmpoweredVote-civic-data/1.0"})
    with urllib.request.urlopen(req, timeout=60) as r:
        blob = r.read()
    # An LFS pointer is a short text file and arrives with a clean HTTP 200.
    if len(blob) < _MODEL_MIN_BYTES:
        raise PortraitRejected(
            f"face model download returned {len(blob)} bytes, expected >={_MODEL_MIN_BYTES} "
            "(a Git LFS pointer, not the model)"
        )
    got = hashlib.sha256(blob).hexdigest()
    if got != _MODEL_SHA256:
        raise PortraitRejected(f"face model sha256 {got} != expected {_MODEL_SHA256}")
    with open(path, "wb") as f:
        f.write(blob)
    return path


def _detector_for(size):
    import cv2  # imported lazily so scripts that never check faces need no opencv

    det = getattr(_tls, "detector", None)
    if det is None:
        det = cv2.FaceDetectorYN.create(model_path(), "", (320, 320), 0.6, 0.3, 5000)
        _tls.detector = det
    det.setInputSize(size)
    return det


def _best_face(bgr):
    """Highest-confidence face in one orientation -> (confidence, eye_angle_degrees)."""
    import cv2, math
    import numpy as np

    # YuNet's anchors cover a limited face-size range, so normalise the frame into it at BOTH
    # ends. Without the upper bound a 3930x4644 OFFICIAL portrait scores 0.62 and is refused as
    # "not a portrait" - the detector fails on the best source, not the worst.
    h, w = bgr.shape[:2]
    longest = max(h, w)
    if longest < _WORK_MIN or longest > _WORK_MAX:
        s = (_WORK_MIN if longest < _WORK_MIN else _WORK_MAX) / float(longest)
        interp = cv2.INTER_CUBIC if s > 1 else cv2.INTER_AREA
        bgr = cv2.resize(bgr, (max(1, int(w * s)), max(1, int(h * s))), interpolation=interp)
        h, w = bgr.shape[:2]
    _, faces = _detector_for((w, h)).detect(bgr)
    if faces is None or len(faces) == 0:
        return 0.0, None
    f = max(faces, key=lambda r: r[-1])
    angle = math.degrees(math.atan2(f[7] - f[5], f[6] - f[4]))   # landmarks 2..3 are the eyes
    return float(f[-1]), round(angle, 1)


def face_report(img: Image.Image) -> dict:
    """Confidence that an upright face is present, at each of four rotations.

    Returns {'confs': {deg: conf}, 'best': deg, 'eye_angle': deg_or_None}. A frame with no
    face at any rotation is not a portrait; one that only scores when turned is stored
    rotated.
    """
    import cv2
    import numpy as np

    bgr = cv2.cvtColor(np.array(img), cv2.COLOR_RGB2BGR)
    ops = {0: None, 90: cv2.ROTATE_90_CLOCKWISE, 180: cv2.ROTATE_180, 270: cv2.ROTATE_90_COUNTERCLOCKWISE}
    confs, angles = {}, {}
    for deg in _ROTATIONS:
        frame = bgr if ops[deg] is None else cv2.rotate(bgr, ops[deg])
        confs[deg], angles[deg] = _best_face(frame)
    best = max(confs, key=lambda d: confs[d])
    return {"confs": {d: round(c, 3) for d, c in confs.items()}, "best": best, "eye_angle": angles[best]}


def assert_portrait(img: Image.Image, who: str = "image") -> Image.Image:
    """Raise PortraitRejected unless the frame holds an upright human face.

    Rotation is CORRECTED rather than rejected: a sideways file is a real portrait that was
    written out wrong, and turning it is lossless.
    """
    rep = face_report(img)
    confs, best = rep["confs"], rep["best"]
    if confs[best] < _FACE_CONFIDENCE:
        raise PortraitRejected(
            f"{who}: no face at any rotation (best {confs[best]:.2f} at {best} deg, "
            f"bar {_FACE_CONFIDENCE}) - a seal, logo, map or blank frame, not a portrait"
        )
    if best != 0 and confs[0] < _FACE_CONFIDENCE:
        return img.rotate(-best, expand=True)   # PIL rotates anticlockwise
    return img


def crop_to_4_5(img: Image.Image) -> Image.Image:
    """Crop to 4:5 without stretching. Too tall crops from the TOP so the head is kept."""
    w, h = img.size
    target = 4 / 5
    if w / h > target:
        nw = int(h * target)
        left = (w - nw) // 2
        return img.crop((left, 0, left + nw, h))
    nh = int(w / target)
    return img.crop((0, 0, w, nh))


def to_jpeg(img: Image.Image, quality: int = 90) -> bytes:
    """Final 600x750 JPEG, ready to upload."""
    buf = io.BytesIO()
    img.resize(TARGET_SIZE, Image.Resampling.LANCZOS).save(
        buf, format="JPEG", quality=quality, optimize=True
    )
    return buf.getvalue()
