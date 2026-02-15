# Astr Zone Scale - Final Specification

**Version:** 1.0  
**Status:** LOCKED ✅

---

## Formula

```
LPI = Radiance / 0.171
Zone = clamp(ceil(1 + log(LPI / 0.05) / log(2.5)), 1, 9)
```

## Constants

| Constant | Value | Meaning |
|----------|-------|---------|
| `NATURAL_RADIANCE` | 0.171 nW/cm²/sr | Natural sky brightness |
| `BASE_LPI` | 0.05 | Zone 1 threshold |
| `FACTOR` | 2.5 | Multiplier per zone |

## Zone Table

| Zone | LPI Range | Stars Visible | What You See |
|------|-----------|---------------|--------------|
| **1** | < 0.05 | ~15,000 | Zodiacal light, gegenschein |
| **2** | 0.05 - 0.13 | ~10,000 | Milky Way with dark lanes |
| **3** | 0.13 - 0.31 | ~7,000 | Milky Way clearly visible |
| **4** | 0.31 - 0.78 | ~4,500 | Milky Way visible |
| **5** | 0.78 - 1.95 | ~2,500 | Milky Way barely visible |
| **6** | 1.95 - 4.88 | ~1,000 | No Milky Way |
| **7** | 4.88 - 12.2 | ~500 | Major constellations only |
| **8** | 12.2 - 30.5 | ~200 | Orion's belt visible |
| **9** | > 30.5 | ~50 | Only planets + brightest stars |

## Implementation (Python)

```python
import math

NATURAL_RADIANCE = 0.171  # nW/cm²/sr
BASE_LPI = 0.05
FACTOR = 2.5

def radiance_to_zone(radiance: float) -> int:
    """Convert VIIRS radiance to Astr Zone (1-9)."""
    if radiance <= 0:
        return 1
    
    lpi = radiance / NATURAL_RADIANCE
    
    if lpi < BASE_LPI:
        return 1
    
    zone = 1 + math.log(lpi / BASE_LPI) / math.log(FACTOR)
    return max(1, min(9, math.ceil(zone)))
```

## Implementation (Dart)

```dart
import 'dart:math';

const double naturalRadiance = 0.171;
const double baseLpi = 0.05;
const double factor = 2.5;

int radianceToZone(double radiance) {
  if (radiance <= 0) return 1;
  
  final lpi = radiance / naturalRadiance;
  if (lpi < baseLpi) return 1;
  
  final zone = 1 + log(lpi / baseLpi) / log(factor);
  return zone.ceil().clamp(1, 9);
}
```
