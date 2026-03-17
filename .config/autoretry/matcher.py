#!/usr/bin/env python3
"""OpenCV template matcher for auto-retry dialog detection.
Outputs: MATCH <score> <x> <y>  or  NOMATCH <best_score>
Exit code: 0 = match found, 1 = no match
"""
import sys
import cv2
import numpy as np

THRESHOLD = 0.7  # TM_CCOEFF_NORMED: 1.0 = perfect, >0.7 = reliable match

def match(template_path, screenshot_path):
    template = cv2.imread(template_path)
    screenshot = cv2.imread(screenshot_path)

    if template is None:
        print(f"ERROR: Cannot read template: {template_path}", file=sys.stderr)
        return 1
    if screenshot is None:
        print(f"ERROR: Cannot read screenshot: {screenshot_path}", file=sys.stderr)
        return 1

    # Convert to grayscale for more robust matching
    tmpl_gray = cv2.cvtColor(template, cv2.COLOR_BGR2GRAY)
    shot_gray = cv2.cvtColor(screenshot, cv2.COLOR_BGR2GRAY)

    th, tw = tmpl_gray.shape[:2]
    result = cv2.matchTemplate(shot_gray, tmpl_gray, cv2.TM_CCOEFF_NORMED)

    # Find all matches via iterative peak suppression
    matches = []
    while True:
        _, max_val, _, max_loc = cv2.minMaxLoc(result)
        if max_val < THRESHOLD:
            break
        matches.append((max_val, max_loc[0], max_loc[1]))
        # Zero out region around this peak so next iteration finds others
        x, y = max_loc
        result[
            max(0, y - th // 2) : min(result.shape[0], y + th // 2),
            max(0, x - tw // 2) : min(result.shape[1], x + tw // 2),
        ] = 0

    if matches:
        for score, x, y in matches:
            print(f"MATCH {score:.6f} {x} {y}")
        return 0
    else:
        print(f"NOMATCH {max_val:.6f}")
        return 1

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <template.png> <screenshot.png>", file=sys.stderr)
        sys.exit(2)
    sys.exit(match(sys.argv[1], sys.argv[2]))
