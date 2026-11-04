"""Trim a uniform decorative border from a portrait.

🔴 A FRAMED SOURCE IS A DEFECT (Atlanta ATL-4 ruling: Che' Alexander / Patrick Labat, discs on
matte). Hinds's studio portraits carry a RECTANGULAR one -- same class, different shape, and it
passes every numeric check we own: licence, resolution, colour spread, face box, alt text.

The trim is measured, not assumed: an edge row/column is "border" only while its pixels are
near-uniform (low spread ACROSS the row) AND dark. It stops at the first row that is not.
"""
import numpy as np

def _is_border_line(line, tol, dark):
    # line: (N,3). Uniform along its length and dark.
    return line.std(axis=0).mean() < tol and line.mean() < dark

def border_box(arr, tol=14.0, dark=110.0, max_frac=0.12):
    h, w = arr.shape[:2]
    top, bottom, left, right = 0, h, 0, w
    lim_v, lim_h = int(h*max_frac), int(w*max_frac)
    while top < lim_v and _is_border_line(arr[top, left:right], tol, dark): top += 1
    while bottom > h-lim_v and _is_border_line(arr[bottom-1, left:right], tol, dark): bottom -= 1
    while left < lim_h and _is_border_line(arr[top:bottom, left], tol, dark): left += 1
    while right > w-lim_h and _is_border_line(arr[top:bottom, right-1], tol, dark): right -= 1
    return left, top, right, bottom

def _control():
    # POSITIVE CONTROL: a known 25px black frame around noise must come back as exactly that box.
    rng = np.random.default_rng(7)
    inner = rng.integers(90, 200, size=(300, 240, 3)).astype(np.uint8)
    # the frame carries JPEG-like noise, so a tolerance that is too TIGHT must miss it.
    # A perfectly flat frame would be found by any tol > 0 and would prove nothing.
    framed = rng.integers(8, 20, size=(350, 290, 3)).astype(np.uint8)
    framed[25:325, 25:265] = inner
    box = border_box(framed)
    assert box == (25, 25, 265, 325), f'CONTROL FAILED: planted 25px frame read as {box}'
    # NEGATIVE CONTROL: an unframed image must be left alone.
    box2 = border_box(inner)
    assert box2 == (0, 0, 240, 300), f'CONTROL FAILED: unframed image trimmed to {box2}'
    # NEGATIVE CONTROL 2: a dark but NON-uniform edge (a dark suit) must not be eaten.
    dark_noise = rng.integers(0, 60, size=(300, 240, 3)).astype(np.uint8)
    box3 = border_box(dark_noise)
    assert box3 == (0, 0, 240, 300), f'CONTROL FAILED: dark textured image trimmed to {box3}'
    return True

if __name__ == '__main__':
    _control(); print('CONTROL OK  planted 25px frame found exactly; unframed and dark-textured untouched')
