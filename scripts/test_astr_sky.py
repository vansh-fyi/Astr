#!/usr/bin/env python3
"""Checks scripts/astr_sky.py against test/fixtures/astr_sky_model.vectors.json.

Run: python3 scripts/test_astr_sky.py
"""

import json
import math
import sys
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import astr_sky as s  # noqa: E402

V = json.loads((Path(__file__).resolve().parent.parent / "test" / "fixtures" / "astr_sky_model.vectors.json").read_text())


def hour(row):
    return s.hour_quality(*row)


class SkyModelTest(unittest.TestCase):
    def test_published_anchor(self):
        a = V["anchor"]
        v = s.moon_brightness_v(a["obs_zenith"], a["moon_zenith"], a["separation"], a["phase_angle"], a["k_v"])
        self.assertAlmostEqual(v, a["v"], delta=a["tolerance"])

    def test_numeric_tables(self):
        def check(key, fn, in_keys, out_key):
            t = V[key]["tolerance"]
            for c in V[key]["cases"]:
                self.assertAlmostEqual(fn(*[c[k] for k in in_keys]), c[out_key], delta=t, msg=str(c))
        check("scattering_airmass", s.scattering_airmass, ["zenith"], "x")
        check("phase_angle_from_illumination", s.phase_angle_from_illumination, ["illumination"], "degrees")
        check("pressure_ratio", s.pressure_ratio, ["elevation_m"], "ratio")
        check("extinction_k_v", s.extinction_k_v, ["aod550", "elevation_m"], "k")
        check("moon_brightness_v", s.moon_brightness_v, ["obs_zenith", "moon_zenith", "separation", "phase_angle", "k_v"], "v")
        check("moon_ratio", s.moon_ratio, ["obs_zenith", "moon_zenith", "separation", "phase_angle", "k_v"], "ratio")
        check("angular_separation", s.angular_separation_deg, ["alt1", "az1", "alt2", "az2"], "degrees")
        check("sqm_effective", s.sqm_effective, ["r_art", "b_moon"], "sqm")
        check("relative_star_count", s.relative_star_count, ["nelm"], "relative")

    def test_moon_below_horizon(self):
        self.assertTrue(math.isinf(s.moon_brightness_v(0, 90, 90, 0, 0.15)))
        self.assertEqual(s.moon_ratio(0, 95, 95, 0, 0.15), 0.0)

    def test_moon_is_brighter_when_fuller_and_higher(self):
        k = 0.15
        full_high = s.moon_ratio(0, 30, 30, 0, k)
        full_low = s.moon_ratio(0, 60, 60, 0, k)
        half_high = s.moon_ratio(0, 30, 30, 90, k)
        self.assertGreater(full_high, full_low)
        self.assertGreater(full_high, half_high)

    def test_sky_state(self):
        for c in V["sky_state"]:
            self.assertEqual(s.sky_state(c["cloud"], c["r_art"], c["r_eff"]), c["state"], c)

    def test_night_state(self):
        for c in V["night_state"]["cases"]:
            hours = [hour(r) for r in c["hours"]]
            res = s.night_state(hours)
            if c["state"] is None:
                self.assertIsNone(res, c["name"])
                continue
            self.assertEqual(res[0], c["state"], c["name"])
            self.assertEqual(None if res[1] is None else list(res[1]), c["window"], c["name"])

    def test_instant_state(self):
        for c in V["instant_state"]:
            self.assertEqual(s.instant_state(hour(c["hour"])), c["state"], c)

    def test_why(self):
        for c in V["why"]["cases"]:
            w = s.why(c["cloud"], c["r_art"], c["r_eff"])
            self.assertEqual(w["primary"], c["primary"], c)
            self.assertAlmostEqual(w["light_loss"], c["light_loss"], delta=V["why"]["tolerance"])
            self.assertAlmostEqual(w["moon_loss"], c["moon_loss"], delta=V["why"]["tolerance"])

    def test_moon_hours(self):
        for c in V["moon_hours"]["cases"]:
            self.assertEqual(s.moon_hours(c["dark"], c["moon_altitude"]), (c["up"], c["down"]))

    def test_state_never_improves_when_moon_added(self):
        order = list(s.STATES)[:4]
        for r in (0, 0.2, 0.7, 2, 6, 15):
            for b in (0, 0.5, 3, 20, 80):
                dark = s.sky_state(0.1, r, r)
                moon = s.sky_state(0.1, r, r + b)
                if dark in order and moon in order:
                    self.assertGreaterEqual(order.index(moon), order.index(dark))


if __name__ == "__main__":
    unittest.main(verbosity=2)
