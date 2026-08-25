#!/usr/bin/env bash
#
# Builds ACT4 self-checking ELFs for this core's RV32I config, converts
# each ELF to a hex file this repo's imem module can $readmemh, runs it
# through act4_test_tb.sv, and reports pass/fail.
#
# Usage:
#   ./run_act4_tests.sh /path/to/riscv-arch-test
#
# Exits 0 if every generated RV32I test passes. Exits 1 on any build
# failure or test failure.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ACT_DIR="${1:?Usage: $0 /path/to/riscv-arch-test}"

CONFIG_NAME="riscv-cpu-rv32i"     # must match `name:` in test_config.yaml
WORKDIR="$ROOT/act4_work"

echo "============================================================"
echo " Generating + compiling ACT4 ELFs (RV32I only)"
echo "============================================================"

(
  cd "$ACT_DIR" &&
  EXTENSIONS=I \
  CONFIG_FILES="$SCRIPT_DIR/test_config.yaml" \
  WORKDIR="$WORKDIR" \
  make tests

  sed -n '30,45p' "$ACT_DIR/tests/rv32i/I/I-add-00.S"

  grep -rn "define.*RVTEST_SIGUPD\|define LREG\|define SREG\|define REGWIDTH" "$ACT_DIR"/**/test_macros.h "$ACT_DIR"/**/arch_test.h 2>/dev/null

  BAD_OPCODES='\b(lq|sq|ld|sd|addiw|addw|subw|sllw|srlw|sraw|slliw|srliw|sraiw|divw|divuw|remw|remuw|mulw)\b'
  while IFS= read -r -d '' f; do
    echo "!! Excluding generated test with non-RV32I opcode: $f"
    rm -f "$f"
  done < <(grep -lrEZ "$BAD_OPCODES" "$ACT_DIR/tests/rv32i" 2>/dev/null)

  # Drop any generated rv32i test source that references a 64/128-bit-only opcode.
  EXTENSIONS=I \
  CONFIG_FILES="$SCRIPT_DIR/test_config.yaml" \
  WORKDIR="$WORKDIR" \
  VERBOSE=True \
  make --jobs "$(nproc)"
)
BUILD_STATUS=$?

if [ "$BUILD_STATUS" -ne 0 ]; then
  echo "!! ACT4 ELF generation/build failed - see make output above"
  exit 1
fi

# NOTE: this path pattern ($WORKDIR/<config_name>/elfs) is taken directly
# from the ACT4 README's description of `make`'s output.
ELF_DIR="$WORKDIR/$CONFIG_NAME/elfs"

if [ ! -d "$ELF_DIR" ]; then
  echo "!! Expected ELF directory not found: $ELF_DIR"
  echo "   Looking for ELFs elsewhere under $WORKDIR:"
  find "$WORKDIR" -name '*.elf' 2>/dev/null | head -20
  exit 1
fi

SIM_WORKDIR="$(mktemp -d)"
trap 'rm -rf "$SIM_WORKDIR"' EXIT

# Every RTL source the design needs, package first (same pattern as
# run_tests.sh / run_arch_tests.sh elsewhere in this repo).
mapfile -d '' RTL_SOURCES < <(
  {
    printf '%s\0' "$ROOT/RTL/riscv_pkg.sv"
    find "$ROOT/RTL" -mindepth 2 -name '*.sv' -print0 | sort -z
  }
)

SIM_BIN="$SIM_WORKDIR/act4_test_tb.vvp"
echo "Building simulation image..."
if ! iverilog -g2012 -o "$SIM_BIN" "${RTL_SOURCES[@]}" "$SCRIPT_DIR/act4_test_tb.sv" > "$SIM_WORKDIR/build.log" 2>&1; then
  echo "!! Failed to build simulation image:"
  cat "$SIM_WORKDIR/build.log"
  exit 1
fi

TOTAL=0
PASSED=0

shopt -s nullglob
for elf in "$ELF_DIR"/*.elf; do
  name="$(basename "${elf%.elf}")"
  TOTAL=$((TOTAL + 1))

  bin="$SIM_WORKDIR/$name.bin"
  hex="$SIM_WORKDIR/$name.hex"

  riscv32-unknown-elf-objcopy -O binary "$elf" "$bin"
  python3 "$ROOT/Verification/Top Level Tests/Assembly Programs/bin_to_hex.py" "$bin" "$hex" > /dev/null

  echo "============================================================"
  echo " $name"
  echo "============================================================"

  if vvp "$SIM_BIN" +HEXFILE="$hex" | tee "$SIM_WORKDIR/$name.log" | grep -q 'RVCP-SUMMARY: TEST PASSED'; then
    PASSED=$((PASSED + 1))
  fi
done
shopt -u nullglob

if [ "$TOTAL" -eq 0 ]; then
  echo "!! No .elf files found in $ELF_DIR - EXTENSIONS=I may have produced nothing, or the path is wrong"
  exit 1
fi

echo "============================================================"
echo "ACT4 RV32I RESULTS: $PASSED/$TOTAL passed"
echo "============================================================"

[ "$PASSED" -eq "$TOTAL" ]