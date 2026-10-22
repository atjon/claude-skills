---
name: profile-yolo26
description: Profile the tr-yolo-26 helper_subscriber node with Nsight Systems -- one command that rebuilds, plays a rosbag, captures, and prints a per-range latency table diffed against the last run plus a flame graph. Event-based (exact NVTX ranges, -f = every function auto-instrumented) and sampling-based (-s = CPU call-stack samples of all code). Use when asked to profile/benchmark yolo26, check whether a change made a yolo26 stage faster, or produce a yolo26 flame graph.
---

# Profile yolo26 (Nsight Systems: event-based NVTX + sampling)

Everything is in `src/tr-yolo-26/tools/`; the full user guide is `tools/PROFILING.md`:

- `profile.sh` -- rebuild (RelWithDebInfo) -> `ros2 bag play --loop` -> `nsys profile` of the
  helper_subscriber binary -> `nvtx_flame.py`. Run `profile.sh -h` for flags.
- `nvtx_flame.py REPORT.nsys-rep [--baseline X_summary.csv] [--skip N]` -- folds NVTX push/pop
  ranges (from `nsys stats --report nvtx_pushpop_trace`) into `<run>.folded` weighted by self time,
  writes `<run>_summary.csv`, prints median/p95 per range and the delta vs baseline.

- `-f` -- rebuild with `-DTR_YOLO_26_INSTRUMENT_FUNCTIONS=ON`: GCC `-finstrument-functions` +
  `src/func_trace.cpp` hooks push/pop an NVTX range per function defined in this package (exact,
  event-based; no nvtxRangePushA needed). nvtx_flame.py re-roots stacks at `yolo26::image_cb` and
  addr2line-resolves `<module>+0x<off>` names. Plain runs pass `=OFF` explicitly (cache is sticky).
- `-s` -- CPU sampling (`--sample=process-tree --backtrace=dwarf`, `-B` to change) ->
  `cpu_flame.py` reads SAMPLING_CALLCHAINS from the sqlite export -> `<run>_cpu.speedscope.json`
  (rooted per thread, weights = samples) + self/total hotspot table. Statistical, CPU time only.

Outputs go to `src/tr-yolo-26/profiles/` (gitignored); `latest_summary.csv` is the rolling baseline
(`latest_summary_funcs.csv` for `-f` runs -- they never diff against plain runs).

## Workflow

1. `src/tr-yolo-26/tools/profile.sh -l before` (baseline)
2. edit code / move nvtxRangePush/Pop
3. `src/tr-yolo-26/tools/profile.sh -l after` -> table shows Δmed per range vs `before`
4. flame graph: load `profiles/after.speedscope.json` (seconds; `.folded` is integer us) in https://www.speedscope.app (Left Heavy view)
5. timeline detail: `nsys-ui profiles/after.nsys-rep`

Compare against a specific older run: `nvtx_flame.py profiles/after.nsys-rep --baseline profiles/before_summary.csv`.

## Gotchas

- Noise (measured 2026-10-20): `inference` is within 2% between identical runs, but the CPU stages
  (Preprocess/postprocess/publisher/publishing_detections) swing up to 2x. Use 3 runs a side for
  CPU-stage changes. CPU pinning and fixing the glibc mmap threshold did NOT help (the latter hurt).
- TensorRT emits per-layer NVTX ranges under `yolo26::inference` (CPU enqueue only, ~0.1 ms);
  table depth defaults to 2, `-d 3` shows them.
- Only compare runs captured with the same flags: `-c` (CUDA trace) adds overhead.
- `-s` needs `sudo sysctl kernel.perf_event_paranoid=2` (this desktop sits at 4). NVIDIA's
  stackcollapse_nsys.py is NOT used: it keeps one stack per leaf function.
- `-f` overhead measured 2026-10-22: within run-to-run noise (~15 instrumented calls/frame; 2 of 3 runs matched plain). The option is cached: after `-f`, a plain `colcon build` stays instrumented until rebuilt with `=OFF`. If a
  hot-loop helper shows a huge `n`, exclude it (`__attribute__((no_instrument_function))` or
  `-DTR_YOLO_26_INSTRUMENT_EXCLUDE_FUNCTIONS=a,b`).
- CUDA error 999 at TRT startup (even outside nsys) = broken driver state, usually after suspend;
  `sudo rmmod nvidia_uvm && sudo modprobe nvidia_uvm` or reboot.
- Range names from `NVTX_RANGE_FRAME_SRC` carry ` src=.. ts=..`; the folder strips it. New ranges
  need no script change -- any push/pop in the node shows up automatically.
- `yolo26::inference` is true latency for TRT because `PredictorTRT::predict` ends in
  `cudaStreamSynchronize`.
