#!/bin/bash
set -u

TRACES_DIR="/root/champsim_traces_mibench"
OUTPUT_DIR="/ChampSim/results_mibench"

NOPREF_BIN="/ChampSim/bin/champsim_nopref"
PREF_BIN="/ChampSim/bin/champsim_pref"

WARMUP=50000000
SIM=100000000
TOPN=10   # run biggest 10 traces you have

mkdir -p "$OUTPUT_DIR/nopref" "$OUTPUT_DIR/pref"

mapfile -t TRACES < <(find "$TRACES_DIR" -maxdepth 1 -type f -name "*.xz" -printf "%s %p\n" \
  | sort -nr | head -n "$TOPN" | awk '{print $2}')

if [[ "${#TRACES[@]}" -eq 0 ]]; then
  echo "No .xz traces found in $TRACES_DIR"
  exit 1
fi

run_one () {
  local BIN="$1"
  local TRACEFILE="$2"
  local OUTFILE="$3"

  echo ""
  echo "Running ChampSim:"
  echo "  Binary:      $BIN"
  echo "  Trace:       $TRACEFILE"
  echo "  Warmup inst: $WARMUP"
  echo "  Sim inst:    $SIM"
  echo "  Output:      $OUTFILE"
  echo ""

  if "$BIN" \
      --warmup-instructions "$WARMUP" \
      --simulation-instructions "$SIM" \
      "$TRACEFILE" \
      > "$OUTFILE" 2>&1; then
    echo "OK: $(basename "$TRACEFILE")"
  else
    echo "FAIL: $(basename "$TRACEFILE") (see $OUTFILE)"
  fi
}

echo "=== Running NO-PREFETCH (top $TOPN biggest traces) ==="
for TRACEPATH in "${TRACES[@]}"; do
  NAME=$(basename "$TRACEPATH")
  run_one "$NOPREF_BIN" "$TRACEPATH" "$OUTPUT_DIR/nopref/${NAME}.txt"
done

echo "=== Running PREFETCH (top $TOPN biggest traces) ==="
for TRACEPATH in "${TRACES[@]}"; do
  NAME=$(basename "$TRACEPATH")
  run_one "$PREF_BIN" "$TRACEPATH" "$OUTPUT_DIR/pref/${NAME}.txt"
done

echo "=== DONE ==="
echo "Next:"
echo "python3 /ChampSim/champsim_automation_bundle/parse_results.py $OUTPUT_DIR/nopref $OUTPUT_DIR/nopref_full.csv"
echo "python3 /ChampSim/champsim_automation_bundle/parse_results.py $OUTPUT_DIR/pref   $OUTPUT_DIR/pref_full.csv"
