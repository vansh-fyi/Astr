#!/usr/bin/env python3
"""Checks scripts/astr_zone.py against test/fixtures/astr_zone_scale.vectors.json.

Run: python3 scripts/test_astr_zone.py
"""

import json
import math
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import astr_zone as az  # noqa: E402

VECTORS = json.loads((Path(__file__).resolve().parent.parent / "test" / "fixtures" / "astr_zone_scale.vectors.json").read_text())


class ZoneScaleTest(unittest.TestCase):
    def test_constants_match_vectors(self):
        c = VECTORS["constants"]
        self.assertEqual(az.NATURAL_UCD_PER_M2, c["natural_ucd_per_m2"])
        self.assertEqual(az.REFERENCE_SQM, c["reference_sqm"])
        self.assertEqual(az.FIRST_EDGE, c["first_edge"])
        self.assertEqual(az.STEP, c["step"])
        self.assertEqual(az.ZONE_COUNT, c["zone_count"])
        self.assertEqual(list(az.EDGES), VECTORS["edges"])

    def test_edges_double(self):
        for lo, hi in zip(az.EDGES, az.EDGES[1:]):
            self.assertAlmostEqual(hi / lo, 2.0, places=12)
        self.assertEqual(len(az.EDGES), az.ZONE_COUNT - 1)

    def test_ratio_to_zone(self):
        for case in VECTORS["ratio_to_zone"]:
            self.assertEqual(az.zone_from_ratio(case["r"]), case["zone"], case)

    def test_zone_is_monotonic(self):
        previous = 1
        r = 0.0
        while r < 100:
            zone = az.zone_from_ratio(r)
            self.assertGreaterEqual(zone, previous)
            previous = zone
            r += 0.01

    def test_infinity_is_top_zone_and_nan_is_rejected(self):
        self.assertEqual(az.zone_from_ratio(math.inf), 9)
        with self.assertRaises(ValueError):
            az.zone_from_ratio(float("nan"))
        with self.assertRaises(ValueError):
            az.sqm_from_ratio(float("nan"))
        with self.assertRaises(ValueError):
            az.zone_from_ratio(True)

    def test_ratio_to_sqm(self):
        t = VECTORS["ratio_to_sqm"]["tolerance"]
        for c in VECTORS["ratio_to_sqm"]["cases"]:
            self.assertAlmostEqual(az.sqm_from_ratio(c["r"]), c["sqm"], delta=t)

    def test_sqm_to_ratio(self):
        t = VECTORS["sqm_to_ratio"]["tolerance"]
        for c in VECTORS["sqm_to_ratio"]["cases"]:
            self.assertAlmostEqual(az.ratio_from_sqm(c["sqm"]), c["r"], delta=t)

    def test_sqm_round_trip(self):
        for r in (0.0, 0.05, 0.32, 3.0, 40.96, 500.0):
            self.assertAlmostEqual(az.ratio_from_sqm(az.sqm_from_ratio(r)), r, delta=1e-9 * max(1.0, r))

    def test_nelm(self):
        t = VECTORS["sqm_to_nelm"]["tolerance"]
        for c in VECTORS["sqm_to_nelm"]["cases"]:
            self.assertAlmostEqual(az.nelm_from_sqm(c["sqm"]), c["nelm"], delta=t)

    def test_artificial_luminance(self):
        t = VECTORS["artificial_ucd"]["tolerance"]
        for c in VECTORS["artificial_ucd"]["cases"]:
            self.assertAlmostEqual(az.artificial_ucd_from_ratio(c["r"]), c["ucd"], delta=t)

    def test_legacy(self):
        t = VECTORS["legacy"]["tolerance"]
        for c in VECTORS["legacy"]["cases"]:
            self.assertEqual(az.legacy_zone_from_radiance(c["radiance"]), c["legacy_zone"], c)
            self.assertAlmostEqual(az.legacy_ratio_from_radiance(c["radiance"]), c["ratio"], delta=t)
            self.assertEqual(az.zone_from_ratio(az.legacy_ratio_from_radiance(c["radiance"])), c["ladder_zone"], c)

    def test_legacy_and_ladder_differ_by_at_most_one_zone(self):
        radiance = 0.2
        while radiance < 400:
            legacy = az.legacy_zone_from_radiance(radiance)
            ladder = az.zone_from_ratio(az.legacy_ratio_from_radiance(radiance))
            self.assertLessEqual(abs(legacy - ladder), 1, radiance)
            radiance *= 1.001


if __name__ == "__main__":
    unittest.main(verbosity=2)
