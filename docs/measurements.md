# Measurements — iteration 3

Device: Nothing Phone A059 (Snapdragon 7s Gen 3), Android 16, `--profile` build.
All figures measured on that device, not modelled.

## Frame budget

Instrumented with `SchedulerBinding.addTimingsCallback` (see `lib/dev/perf_probe.dart`).
`dumpsys gfxinfo` is not usable here — it does not observe Flutter's pipeline.

Eight consecutive 130-frame windows covering **the live distance list updating**
and **panning the map in the editor**:

| | build p50 | build p95 | raster p50 | raster p95 | raster max | >16.7 ms | >8.3 ms |
|---|---|---|---|---|---|---|---|
| worst window | 2.3 ms | 3.0 ms | 3.1 ms | 3.7 ms | 4.0 ms | 0 | 0 |
| best window  | 1.5 ms | 2.0 ms | 2.9 ms | 3.4 ms | 3.8 ms | 0 | 0 |

**Zero** frames exceeded even the 120 fps budget across all eight windows, so the
60 fps bar is met with roughly 4× headroom.

Caveat worth keeping: these are **warm-shader** numbers. Earlier runs showed
transient spikes (raster max ~98 ms) on the *first* render of a new route, which
is shader compilation. An `--cache-sksl` warm-up pass should precede any release.

## Battery

The device is permanently on AC for adb, so real coulomb-counted drain is not
measurable. `dumpsys battery unplug` was used so the framework accumulates
on-battery accounting; the mAh values below are Android's power-model estimates
attributed per-UID, over **6-minute** windows (not the 30 minutes the brief asks
for), single run each.

App UID power, excluding `screen` (identical in every condition, and it is the
display rather than the app):

| Condition | cpu | gnss | gnss time | app total (ex-screen) |
|---|---|---|---|---|
| Home, live distance list | 0.234 mAh | 0.0102 mAh | 6m 07s | ~0.64 mAh / 6 min |
| Backgrounded (geofences only) | 0.0147 mAh | 0.0002 mAh | 7.6 s | ~0.015 mAh / 6 min |

Extrapolated: with the list open the app costs roughly **6.4 mAh/hour**, about
**0.13 % of this 5000 mAh battery per hour**. The screen showing that list draws
~12.9 mAh over the same 6 minutes — about **100× more than the app**.

Two honest findings from doing this properly:

1. **The first baseline was invalid.** Comparing "home" against "settings screen"
   showed near-identical GNSS time (6m 07s vs 6m 10s), because the GPS warm-up
   listener runs whenever the app is *foregrounded*, regardless of screen. That
   is not idle. The valid baseline is the app backgrounded.
2. **GNSS is not the expensive part at this scale.** Continuous positioning cost
   0.0102 mAh over 6 minutes. The adaptive tiering in `DistanceTrackingPolicy`
   still earns its place for fix quality and thermals, but the power argument for
   it is weaker than assumed when it was written.

Backgrounding verified: GNSS time drops from 6m 07s to 7.6 s (the few seconds
before the app was sent to background), confirming the lifecycle handling stops
the foreground streams as designed.

### What would make these numbers stronger
- 30-minute windows, repeated, with variance reported.
- A physically unplugged device, so drain is coulomb-counted rather than modelled.
- A third condition with GPS warm-up disabled, isolating warm-up from the
  distance stream.
