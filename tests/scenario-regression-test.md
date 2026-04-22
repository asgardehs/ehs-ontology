# Scenario regression test — design + runbook

**Purpose:** Before merging any ontology change (v3.2 → v3.3 and
beyond), verify that the **8 worked scenarios** in
`ehs-ontology-v3.X.ttl` still classify to the same parent classes and
still route to the same regulatory frameworks they did at baseline.
This is the ontology's integration test: the scenarios are named
individuals asserting concrete compliance routes, and the paper's
claims rest on those routes staying stable.

## Scenarios under test

All 8 are `rdf:type ehs:ContextualComplianceActivation` in
`ehs-ontology-v3.2.ttl`:

| Scenario IRI                                 | Domain |
| -------------------------------------------- | ------ |
| `ehs:Scenario_ChemSpill_LoadingDock`         | Three-agency (DOT + EPA + OSHA) — transport context at loading dock |
| `ehs:Scenario_ChemSpill_Contained`           | Containment narrows routing to EPA + OSHA only (no CERCLA) |
| `ehs:Scenario_ChemErgo_DrumHandling`         | Multi-hazard: Chemical + Ergonomic compound activation |
| `ehs:Scenario_ChemSpill_Roadway`             | Transport accident on public roadway — DOT + EPA + USCG |
| `ehs:Scenario_BioChemMaintenance`            | Multi-hazard: Biological + Chemical in healthcare maintenance |
| `ehs:Scenario_ElecChemConfined`              | Multi-hazard: Electrical + Chemical in confined space |
| `ehs:Scenario_NPDESPermitExceedance`         | Module D (CWA): NPDES effluent-limit exceedance at direct-discharge outfall |
| `ehs:Scenario_StormwaterOutfall_MSGP`        | Module D (CWA): industrial-stormwater MSGP benchmark exceedance |

## What "still works as they should" means (3 invariants)

Every change to the TTL must preserve all three:

1. **Syntactic + OWL-DL validity.** TTL parses. `robot validate-profile
   --profile OWL2DL` passes. HermiT loads without contradiction.
2. **Classification stability.** Under HermiT-inferred types, every
   scenario individual is **still an instance of the same set of
   classes** it was at baseline. Newly-added, more-specific subclasses
   are allowed to appear; the baseline set must still be entailed.
3. **Routing stability.** For each scenario, the set of
   `ehs:triggeredByType`, `ehs:hasActionContext`,
   `ehs:hasContextCondition`, and `ehs:activatesFramework` assertions
   (asserted + inferred) must be a **superset** of the baseline set.
   Adding a new framework is fine; removing or renaming one breaks the
   regression.

## Tooling

Primary: **ROBOT** (http://robot.obolibrary.org/) — Java-based, wraps
OWL API + HermiT, standard for OBO-community regression tests.
Install:

- macOS: `brew install robot`
- Linux: download `robot.jar` + `robot` wrapper from the ROBOT release
  page and place on `$PATH`.
- Or: docker run `obolibrary/odkfull` — ROBOT bundled.

Fallback: **owlready2** (Python 3) — same HermiT reasoner under the
hood, scriptable. Useful if ROBOT install is friction.

## Test strategy (3 layers, increasing strictness)

### Layer 1 — Consistency (fast, every change)

```shell
robot reason \
  --reasoner hermit \
  --input ehs-ontology-v3.X.ttl \
  --output /tmp/reasoned.ttl
robot validate-profile \
  --profile OWL2DL \
  --input ehs-ontology-v3.X.ttl
```

Catches: parse errors, unsat classes, OWL-DL profile violations. ~5s
on a modern laptop.

### Layer 2 — Classification stability (golden-file diff)

**One-time baseline build** (run once against v3.2, commit outputs
under `tests/golden/`):

```shell
./tests/capture-golden.sh ehs-ontology-v3.2.ttl
```

That script runs `queries/scenario-types.rq` parameterized over each
of the 8 scenarios and writes one TSV per scenario.

**In CI / pre-merge**, re-run and diff. Regression = any **removed**
line. New lines are informational.

### Layer 3 — Routing stability (SPARQL ASK competency queries)

One hand-authored ASK query per scenario under `tests/queries/
scenario-N-<slug>.rq`, encoding **the specific assertions the paper
claims**. Authored from v3.2's own triples, so v3.2 is its own
baseline.

Each query checks:
- `ehs:triggeredByType` — all baseline hazard types still present
- `ehs:hasActionContext` — same action context
- `ehs:hasContextCondition` — all baseline conditions
- `ehs:activatesFramework` — all baseline frameworks

Test runner: one script reads each `.rq`, runs `robot verify`, fails
loudly if any returns false.

## Directory layout

```
ehs-ontology/
├── ehs-ontology-v3.2.ttl          # current
├── ehs-ontology-v3.3.ttl          # candidate (future)
├── tests/
│   ├── scenario-regression-test.md    # this file
│   ├── run.sh                         # top-level runner
│   ├── capture-golden.sh              # one-off baseline capture
│   ├── queries/
│   │   ├── scenario-types.rq          # parameterized type query
│   │   ├── scenario-1-chemspill-loadingdock.rq
│   │   ├── scenario-2-chemspill-contained.rq
│   │   ├── scenario-3-chemergo-drumhandling.rq
│   │   ├── scenario-4-chemspill-roadway.rq
│   │   ├── scenario-5-biochem-maintenance.rq
│   │   ├── scenario-6-elec-chem-confined.rq
│   │   ├── scenario-7-npdes-exceedance.rq
│   │   └── scenario-8-stormwater-msgp.rq
│   └── golden/
│       └── (captured at first run; committed)
```

## Running the tests

```shell
# Full suite (consistency + classification + routing), against a
# chosen ontology:
./tests/run.sh ehs-ontology-v3.2.ttl

# Or default (latest):
./tests/run.sh
```

Exit 0 on success, non-zero on first failure.

## When to update the golden files

- **Never during a feature branch's own CI run.** If a scenario's
  inferred types change legitimately (you reclassified a class on
  purpose), re-run `capture-golden.sh` manually, review the diff, and
  commit new goldens on the same branch. The commit message must link
  to the rationale (paper update, CFR revision, etc.).
- **Never to paper over a reasoner regression.** If HermiT suddenly
  drops a type that the paper's argument depends on, the ontology is
  wrong, not the golden.

## Adding a new scenario (future work)

When you add a 9th, 10th, Nth scenario to the ontology:

1. Add the individual to the TTL.
2. Add one ASK query at `tests/queries/scenario-N-<slug>.rq`.
3. Run `capture-golden.sh` to write the new type TSV.
4. Commit all three together so the test coverage grows lock-step
   with the ontology.

### Planned: Scenario 9 — OSHA ITA CSV export

When v3.3 introduces the ITA additions (`ehs:ITAIncidentOutcome` +
`ehs:ITAIncidentType` concept schemes and SKOS mappings from the
existing `ehs:SeverityLevel_*` individuals), add a 9th scenario that
exercises the new routing — e.g., "`Scenario_ITA_CSV_Recordable`"
asserting that an ITA-recordable injury routes through OSHA +
activates the ITA outcome + case-type taxonomies. One new ASK query,
one new golden.
