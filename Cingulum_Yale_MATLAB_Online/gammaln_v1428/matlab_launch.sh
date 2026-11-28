#!/usr/bin/env bash
# Assert controls at the actual action helper's MATLAB exec boundary.
set -euo pipefail
flag_count=0
for arg in "$@"; do
  if [[ "$arg" == -singleCompThread ]]; then flag_count=$((flag_count + 1)); fi
done
{
  printf 'Launcher MKL_NUM_THREADS=%s\n' "${MKL_NUM_THREADS-}"
  printf 'Launcher OMP_NUM_THREADS=%s\n' "${OMP_NUM_THREADS-}"
  printf 'Launcher MKL_CBWR=%s\n' "${MKL_CBWR-}"
  printf 'Launcher -singleCompThread count=%s\n' "$flag_count"
} >> "$CPM_CPU_LOG"
test "${MKL_NUM_THREADS-}" = 1
test "${OMP_NUM_THREADS-}" = 1
test "${MKL_CBWR-}" = COMPATIBLE
test "$flag_count" = 1
exec "$CPM_REAL_MATLAB" "$@"
