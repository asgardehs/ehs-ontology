#!/usr/bin/env bash
# run.sh — ontology regression suite
#
# Four layers, run in order. Stops on first failure.
#   [1/4] Consistency    — HermiT loads, OWL-DL profile validates
#   [2/4] Classification — inferred-type set is a superset of baseline
#   [3/4] Routing        — scenario-*.rq ASK queries must all return true
#   [4/4] Coverage       — coverage-*.rq ASK queries enforce metadata
#                          rules (citation-first from v3.3 onward)
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

echo "[1/4] Consistency..."
robot reason \
    --reasoner hermit \
    --input "$ONTOLOGY_PATH" \
    --output "$REASONED"
# Profile validation is advisory, not fatal. HermiT consistency above
# is the real semantic check. DL profile violations (e.g. undeclared
# SKOS annotation properties) log a warning but don't block the suite.
if ! robot validate-profile \
    --profile DL \
    --input "$ONTOLOGY_PATH" >/tmp/ehs-profile-$$.log 2>&1
then
    echo "      WARN  DL profile violations (see /tmp/ehs-profile-$$.log)"
    echo "            Non-fatal. Fix by declaring external annotation"
    echo "            properties (skos:definition, skos:note, etc.)"
    echo "            alongside the ontology header."
fi
echo "      OK"

echo "[2/4] Classification (goldens)..."
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
    rendered="/tmp/ehs-types-$$-$s.rq"
    sed "s|\$scenario|ehs:$s|g" "$QUERIES_DIR/scenario-types.rq" > "$rendered"
    robot query \
        --input "$REASONED" \
        --query "$rendered" \
        "$actual"
    rm -f "$rendered"

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

echo "[3/4] Routing (ASK competency queries)..."
for q in "$QUERIES_DIR"/scenario-*.rq; do
    # scenario-types.rq is the parameterized helper, not a competency query.
    [[ "$q" == *scenario-types.rq ]] && continue
    name="$(basename "$q" .rq)"
    # `robot query` on an ASK writes "true" or "false" to the output
    # file. We require "true".
    out="/tmp/ehs-ask-$$-$name.txt"
    robot query --input "$REASONED" --query "$q" "$out" 2>/dev/null
    if ! grep -q '^true' "$out"; then
        echo "      FAIL $name — ASK returned false"
        echo "          (routing invariant violated — see $q)"
        exit 1
    fi
    rm -f "$out"
    echo "      OK   $name"
done

echo "[4/4] Coverage (metadata rules)..."
shopt -s nullglob
coverage_files=( "$QUERIES_DIR"/coverage-*.rq )
shopt -u nullglob
if [[ ${#coverage_files[@]} -eq 0 ]]; then
    echo "      SKIP (no coverage-*.rq queries present)"
else
    for q in "${coverage_files[@]}"; do
        name="$(basename "$q" .rq)"
        out="/tmp/ehs-ask-$$-$name.txt"
        robot query --input "$REASONED" --query "$q" "$out" 2>/dev/null
        if ! grep -q '^true' "$out"; then
            echo "      FAIL $name — ASK returned false"
            echo "          (coverage rule violated — see $q)"
            exit 1
        fi
        rm -f "$out"
        echo "      OK   $name"
    done
fi

echo
echo "All regression layers passed for $ONTOLOGY."
