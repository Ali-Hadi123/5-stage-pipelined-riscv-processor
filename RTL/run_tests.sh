#!/usr/bin/env bash
#
# run_tests.sh
#
# Compiles and runs every unit testbench plus the full top-level integration
# testbench for the RISC-V CPU project, using Icarus Verilog.
#
# Usage:
#   ./run_tests.sh
#
# Exits 0 if every testbench compiled and every reported "N/M tests passed"
# had N == M. Exits 1 otherwise (compile error OR any failed assertion),
# which is what lets CI mark the run red/green.

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

OVERALL_FAIL=0

# Every RTL source file the design needs, package first.
mapfile -d '' RTL_SOURCES < <(
  {
    printf '%s\0' "$ROOT/RTL/riscv_pkg.sv"
    find "$ROOT/RTL" -mindepth 2 -name '*.sv' -print0 | sort -z
  }
)

# Runs one testbench: compiles it against the full RTL source list, executes
# it from the given working directory (so relative $readmemh paths resolve),
# and checks the output for failures.
#
# args: <human-readable name> <testbench .sv path> <run directory>
run_tb () {
  local name="$1"
  local tb_path="$2"
  local run_dir="$3"

  echo "============================================================"
  echo " $name"
  echo "============================================================"

  local sim_out="$WORKDIR/${name// /_}.vvp"
  local compile_log="$WORKDIR/${name// /_}.compile.log"

  if ! iverilog -g2012 -o "$sim_out" "${RTL_SOURCES[@]}" "$tb_path" > "$compile_log" 2>&1; then
    echo "  !! COMPILE FAILED"
    cat "$compile_log"
    OVERALL_FAIL=1
    return
  fi

  local run_log="$WORKDIR/${name// /_}.run.log"
  ( cd "$run_dir" && vvp "$sim_out" ) | tee "$run_log"

  # A testbench is only considered passing if every "N/M tests passed" line
  # it printed has N == M, AND it printed at least one such line (a
  # testbench that silently produces no summary is treated as a failure,
  # since that usually means something crashed before printing results).
  local ratios
  ratios=$(grep -oE '[0-9]+/[0-9]+ tests passed' "$run_log" || true)

  if [ -z "$ratios" ]; then
    echo "  !! NO RESULTS SUMMARY FOUND (treating as failure)"
    OVERALL_FAIL=1
    return
  fi

  local bad=0
  while IFS= read -r line; do
    local n="${line%%/*}"
    local m="${line#*/}"
    m="${m%% *}"
    if [ "$n" != "$m" ]; then
      bad=1
    fi
  done <<< "$ratios"

  if [ "$bad" -ne 0 ]; then
    echo "  !! ONE OR MORE ASSERTIONS FAILED"
    OVERALL_FAIL=1
  else
    echo "  -> OK"
  fi
}

UNIT_TB_DIR="$ROOT/Verification/Unit Test Benches"
for tb in alu_tb reg_file_tb imm_gen_tb data_mem_tb instr_mem_tb; do
  run_tb "$tb" "$UNIT_TB_DIR/$tb.sv" "$UNIT_TB_DIR"
done

TOP_TB_DIR="$ROOT/Verification/Top Level Tests"
run_tb "top_level_tb" "$TOP_TB_DIR/top_level_tb.sv" "$TOP_TB_DIR"

echo "============================================================"
if [ "$OVERALL_FAIL" -ne 0 ]; then
  echo "REGRESSION: FAILED"
  exit 1
else
  echo "REGRESSION: ALL TESTS PASSED"
  exit 0
fi
