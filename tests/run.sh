#!/usr/bin/env bash
# run.sh — ontology regression suite
#
# Three layers, run in order. Stops on first failure.
#   [1/3] Consistency   — HermiT loads, OWL-DL profile validates
#   [2/3] Classification — inferred-type set is a superset of baseline
#   [3/3] Routing        — 8 hand-authored ASK queries must all return true
#
# Usage:
#   tests/run.sh [path-to-ontology.ttl]
#
# Default input is ehs-ontology-v3.2.ttl in the repo root.

set -euo pipefail

ONTOLOGY="${1:-ehs-ontology-v3.2.ttl}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ONTOLOGY_PATH="$REPO_ROOT/$ONTOLOGY"
TESTS_DIR="$REPO_ROOT/tests"
GOLDEN_DIR="$TESTS_DIR/golden"
QUERIES_DIR="$TESTS_DIR/queries"
REASONED="/tmp/ehs-reasoned-$$.ttl"

command -v robot >/dev/null 2>&1 || {
    echo "ERROR: robot not on PATH. See tests/scenario-regression-test.md." >&2
    exit 127
}

test -f "$ONTOLOGY_PATH" || {
    echo "ERROR: $ONTOLOGY_PATH not found" >&2
    exit 2
}

cleanup() { rm -f "$REASONED" /tmp/ehs-types-$$-*.tsv; }
trap cleanup EXIT

echo "[1/3] Consistency..."
robot reason \
    --reasoner hermit \
    --input "$ONTOLOGY_PATH" \
    --output "$REASONED"
robot validate-profile \
    --profile OWL2DL \
    --input "$ONTOLOGY_PATH"
echo "      OK"

echo "[2/3] Classification (goldens)..."
SCENARIOS=(
    Scenario_ChemSpill_LoadingDock
    Scenario_ChemSpill_Contained
    Scenario_ChemErgo_DrumHandling
    Scenario_ChemSpill_Roadway
    Scenario_BioChemMaintenance
    Scenario_ElecChemConfined
    Scenario_NPDESPermitExceedance
    Scenario_StormwaterOutfall_MSGP
)

for s in "${SCENARIOS[@]}"; do
    golden="$GOLDEN_DIR/$s.types.tsv"
    if [[ ! -f "$golden" ]]; then
        echo "      SKIP $s (no golden yet — run tests/capture-golden.sh first)"
        continue
    fi
    actual="/tmp/ehs-types-$$-$s.tsv"
    robot query \
        --input "$REASONED" \
        --query "$QUERIES_DIR/scenario-types.rq" \
        "$actual" \
        --bindings "scenario=<http://example.org/ehs-ontology#$s>"

    # Fail only on lines present in golden but missing in actual.
    # (New lines are OK — they mean the ontology added specificity.)
    missing="$(comm -23 <(sort "$golden") <(sort "$actual") || true)"
    if [[ -n "$missing" ]]; then
        echo "      FAIL $s — missing types:"
        printf '        %s\n' $missing
        exit 1
    fi
    echo "      OK   $s"
done

echo "[3/3] Routing (ASK competency queries)..."
for q in "$QUERIES_DIR"/scenario-*.rq; do
    # scenario-types.rq is the parameterized helper, not a competency query.
    [[ "$q" == *scenario-types.rq ]] && continue
    name="$(basename "$q" .rq)"
    # `robot verify` treats ASK queries with WHERE-matching rows as
    # failures; we want the inverse. Use `query` + text match instead.
    result="$(robot query \
        --input "$REASONED" \
        --query "$q" 2>/dev/null || true)"
    if [[ "$result" != *"true"* ]]; then
        echo "      FAIL $name — ASK returned false"
        echo "          (routing invariant violated — see $q)"
        exit 1
    fi
    echo "      OK   $name"
done

echo
echo "All scenario regressions passed for $ONTOLOGY."
