#!/usr/bin/env bash
# capture-golden.sh — one-off baseline capture
#
# Runs HermiT against the chosen ontology, then for each scenario
# extracts the set of rdf:type triples (asserted + inferred) and
# writes one TSV per scenario under tests/golden/.
#
# Usage:
#   tests/capture-golden.sh [path-to-ontology.ttl]
#
# Default input is ehs-ontology-v3.2.ttl in the repo root.
#
# Re-run when a scenario's inferred-type set legitimately changes
# (class reclassification, new subclass hierarchy, etc.). Review the
# diff carefully before committing — a silent removal usually means
# the ontology change broke a routing invariant.

set -euo pipefail

ONTOLOGY="${1:-ehs-ontology-v3.2.ttl}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ONTOLOGY_PATH="$REPO_ROOT/$ONTOLOGY"
TESTS_DIR="$REPO_ROOT/tests"
GOLDEN_DIR="$TESTS_DIR/golden"
REASONED="/tmp/ehs-reasoned-$$.ttl"

command -v robot >/dev/null 2>&1 || {
    echo "ERROR: robot not on PATH. See tests/scenario-regression-test.md." >&2
    exit 127
}

echo "[capture] Reasoning $ONTOLOGY_PATH with HermiT..."
robot reason \
    --reasoner hermit \
    --input "$ONTOLOGY_PATH" \
    --output "$REASONED"

mkdir -p "$GOLDEN_DIR"

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
    echo "[capture] Types for ehs:$s"
    robot query \
        --input "$REASONED" \
        --query "$TESTS_DIR/queries/scenario-types.rq" \
        "$GOLDEN_DIR/$s.types.tsv" \
        --bindings "scenario=<http://example.org/ehs-ontology#$s>"
done

rm -f "$REASONED"
echo "[capture] Wrote goldens under $GOLDEN_DIR"
echo "[capture] Review the diffs before committing."
