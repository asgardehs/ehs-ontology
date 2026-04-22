# EHS Ontology — Changelog

All notable changes to `ehs-ontology-*.ttl` are recorded here. Each release
corresponds to a versioned Turtle file; prior versions are archived under
`.archive/` alongside this changelog.

Version numbers track the value in `owl:versionInfo` inside the ontology file.

---

## v3.3 — 2026-04-22

**Theme:** OSHA ITA CSV export vocabulary + citation-first rule.

Adds the taxonomies and properties needed for Odin to emit OSHA
Injury Tracking Application (ITA) CSV submissions per 29 CFR 1904.41.
Establishes "citation-first" as a binding rule for all new ontology
content: every class, property, and individual added at or after v3.3
must carry a regulatory citation (`dcterms:source`), a version anchor
(`rdfs:isDefinedBy`), and a plain-English `rdfs:comment` tying the
concept back to the cited regulation.

Legacy v3.2 content is not yet retrofitted — that sweep is v4.0 work
and is explicitly excluded from v3.3's coverage check.

### Added

**Enrichments on existing `ehs:IncidentSeverity` subclasses (8):**
- `ehs:Fatality`, `ehs:LostTimeIncident`, `ehs:RestrictedDutyIncident`,
  `ehs:MedicalTreatmentIncident`, `ehs:FirstAidIncident`, `ehs:NearMiss`,
  `ehs:PropertyDamageIncident`, `ehs:EnvironmentalIncident` each gain
  `rdfs:isDefinedBy`, `dcterms:source` (specific CFR subsection where
  applicable), `skos:notation` (bridges to Odin's SQL seed codes), and
  (where v3.2 lacked one) an `rdfs:comment` with the pedagogical hook.

**New `ehs:CaseClassification` subclasses (6):**
- `ehs:InjuryCase`, `ehs:SkinDisorderCase`, `ehs:RespiratoryConditionCase`,
  `ehs:PoisoningCase`, `ehs:HearingLossCase`, `ehs:OtherIllnessCase`.
  Populates the previously-bare v3.2 root class. Maps 1:1 to OSHA 300
  Log columns F and M1-M5 (per 29 CFR 1904.29).

**New ITA taxonomies (23 classes across 5 roots):**
- `ehs:EstablishmentSize` + 3 subclasses (Small / Medium / Large) for
  29 CFR 1904.41 submission tiers.
- `ehs:EstablishmentType` + 3 subclasses (PrivateIndustry / State-
  Government / LocalGovernment) for federal-vs-State-Plan routing.
- `ehs:TreatmentFacilityType` + 7 subclasses for OSHA Form 301 Item 15.
- `ehs:ITAIncidentOutcome` + 4 subclasses aligned with 29 CFR 1904.7(b)(2)-(5).
- `ehs:ITAIncidentType` + 6 subclasses 1:1 with CaseClassification.

**New properties (12):**
- Establishment-level: `ehs:hasEIN`, `ehs:hasCompanyName`,
  `ehs:hasEstablishmentSize`, `ehs:hasEstablishmentType`.
- OSHA 301 per-incident: `ehs:hasDaysAwayFromWork`,
  `ehs:hasDaysRestrictedOrTransferred`, `ehs:hasDateOfDeath`,
  `ehs:hasTreatmentFacilityType`, `ehs:hasTimeUnknown`,
  `ehs:hasInjuryIllnessDescription`, `ehs:hasITAOutcome`,
  `ehs:hasITAType`.

**SKOS mappings (10 triples + 4 absence statements):**
- 6 `skos:exactMatch` from `CaseClassification` subclasses to
  `ITAIncidentType` subclasses (1:1).
- 4 `skos:exactMatch` from recordable `IncidentSeverity` subclasses
  (Fatality, LostTimeIncident, RestrictedDutyIncident,
  MedicalTreatmentIncident) to `ITAIncidentOutcome` subclasses.
- The other 4 `IncidentSeverity` subclasses (FirstAidIncident,
  NearMiss, PropertyDamageIncident, EnvironmentalIncident)
  deliberately carry NO mapping; each gets an `rdfs:comment`
  explaining the regulatory basis for the absence.

**New test queries:**
- `tests/queries/scenario-9-ita-export.rq` — ASK that the 10 SKOS
  exactMatch triples exist and the 4 absences hold. Joins the
  existing 8-scenario routing-invariant suite.
- `tests/queries/coverage-citations.rq` — ASK that every resource
  carrying `rdfs:isDefinedBy` (i.e. v3.3+ content) also has
  `dcterms:source` and at least one `rdfs:comment`. Enforces the
  citation-first rule.

**Test runner:**
- `tests/run.sh` gains a `[4/4] Coverage` layer that globs
  `coverage-*.rq` alongside the existing `[3/4] Routing` layer
  (`scenario-*.rq`). Preexisting usage and contract unchanged.

### Modeling notes

- All new taxonomies use `owl:Class` + `rdfs:subClassOf` to match v3.2
  style; SKOS is used as an annotation vocabulary
  (`skos:prefLabel`, `skos:notation`, `skos:definition`) and as a
  mapping vocabulary (`skos:exactMatch`, `skos:broadMatch`), not as
  a parallel concept-scheme taxonomy. A SKOS-concept-scheme migration
  across the whole ontology is a candidate for v4.0 but out of scope
  here.
- Property domains split cleanly between `ehs:Establishment` (for
  org-identifying fields) and `ehs:OSHA301Report` (for per-incident
  fields). No new domain class introduced.
- Case-classification subclasses use the "Case" suffix
  (`ehs:InjuryCase`, etc.) to preserve common domain names like
  `ehs:Injury` for potential future use. ITA classes use the
  prefixed pattern `ehs:ITAIncidentOutcome_Death` etc. to namespace
  the export-layer vocabulary away from domain concepts.

### Regression test status

- 8 existing scenario ASKs (`scenario-1-` through
  `scenario-8-stormwater-msgp`) unaffected by v3.3 — they exercise
  compliance-activation routing that does not overlap the new ITA
  export surface. Goldens under `tests/golden/` remain valid.
- 1 new scenario ASK (`scenario-9-ita-export`) added.
- 1 new coverage ASK (`coverage-citations`) added.

### Not yet done (tracked for v4.0)

- Citation retrofit across all v3.2 content.
- EHS Geo-Compliance Extension implementation (design exists at
  `extension/EHS Geo-Compliance Extension.md`; TTL not yet authored).
- Possible migration of owl:Class taxonomies to SKOS concept schemes
  — requires a design decision; out of scope for v3.3.

---

## v3.2 — 2026-04-20 → 2026-04-21

**Theme:** Module D (Clean Water Act) — new regulatory-program module parallel
to Module B (Title V / CAA), plus a cross-program `ehs:Permit` umbrella that
reorganizes air and water permits into a shared hierarchy.

### Added

**New module: Module D — Clean Water Act Discharge & Monitoring.**

Water pollutant taxonomy:
- `ehs:WaterPollutant` with subclasses `ehs:ConventionalPollutant`,
  `ehs:PriorityPollutant`, `ehs:NonConventionalPollutant`, and
  `ehs:WholeEffluentToxicity` (`⊂ NonConventionalPollutant`). Scope per CWA
  §304(a)(4), 40 CFR 423 Appendix A, and 40 CFR 136.

Physical water infrastructure:
- `ehs:DischargePoint` — outfall analog to `ehs:EmissionUnit` on the air side.
- `ehs:StormwaterOutfall` (`⊂ DischargePoint`) — MSGP-regulated outfall.
- `ehs:MonitoringLocation` — compliance sampling point.

Water control equipment:
- `ehs:WaterControlDevice` — water-side analog to `ehs:ControlDevice`.
- `ehs:WastewaterTreatmentUnit` (`⊂ WaterControlDevice`).

Stormwater planning:
- `ehs:SWPPP` — Stormwater Pollution Prevention Plan (40 CFR 122.26).
- `ehs:BestManagementPractice`.

Regulatory-program classes:
- `ehs:NPDESPermit` (`⊂ Permit`) — CWA §402 individual or general permit.
- `ehs:POTWDischargePermit` (`⊂ Permit`) — indirect-discharge industrial
  user permit issued under 40 CFR 403.8.
- `ehs:PretreatmentStandard` — 40 CFR 403 categorical standard.
  **Deliberately not** a subclass of `ehs:Permit`; it is a generally-applicable
  regulatory requirement, not a site-specific authorization document.

Object properties (CWA discharge + monitoring + stormwater chain):
- `ehs:dischargesTo` — `EmissionUnit` → `DischargePoint`.
- `ehs:monitoredAt` — `DischargePoint` → `MonitoringLocation`.
- `ehs:sampledFor` — `MonitoringLocation` → `WaterPollutant`.
- `ehs:subjectToPermit` — `DischargePoint` → `Permit` (range uses the umbrella
  so NPDES, POTW, and future permit types all satisfy it without schema change).
- `ehs:coveredBy` — `StormwaterOutfall` → `SWPPP`.
- `ehs:implements` — `SWPPP` → `BestManagementPractice`.

**Cross-program Permit umbrella.**
- New top-level class `ehs:Permit` covering any regulatory authorization
  document (air, water, waste, radiation, etc.).
- Excludes regulatory standards that apply by operation of law without site-
  specific issuance (NSPS, NESHAP, 40 CFR 403 pretreatment standards).

### Changed

- `ehs:TitleVPermit` — retrofit with `rdfs:subClassOf ehs:Permit`.
- `ehs:FESOP` — retrofit with `rdfs:subClassOf ehs:Permit`.
- `ehs:WaterwayProximity` — definition narrowed to site geography only. CWA
  permitting substance moved to Module D where it belongs; this class
  remains a `LocationContext` modifier used by the
  `ContextualComplianceActivation` routing at incident time (e.g., to decide
  whether a release triggers CWA §311 notification).
- `ehs:EnvironmentalIncident` — added `rdfs:comment` documenting the CWA
  linkage back to the `Permit` / `DischargePoint` / `dischargesTo` chain.
- Header metadata: `owl:versionInfo "3.2"`; `dcterms:date 2026-04-20`;
  v3.2 additions block added to the header `rdfs:comment`.
- Module structure: former "MODULE D: EMPLOYEE INCIDENT MANAGEMENT" section
  renamed to "OPERATIONAL: EMPLOYEE INCIDENT MANAGEMENT" to free the letter
  D for the new regulatory-program module. Content of that section is
  unchanged except for one stale "(Module D)" reference in
  `ehs:alignsWithRecordingCriteria`.
- End-of-file banner bumped from "END OF v3.1" to "END OF v3.2".

### Scenarios

Added two Module D worked scenarios to the routing matrix so the regulatory
vocabulary is exercised end-to-end:

- `ehs:Scenario_NPDESPermitExceedance` — direct-discharge outfall exceeds a
  numeric permit limit; walks the `dischargesTo` / `subjectToPermit` chain;
  fires CWA §309 + 40 CFR 122.41(l)(6) 24-hour noncompliance reporting.
- `ehs:Scenario_StormwaterOutfall_MSGP` — industrial stormwater benchmark
  exceedance; walks the `StormwaterOutfall` / `coveredBy` / `implements`
  chain; fires MSGP Part 6 corrective-action (not direct enforcement).

### Fixed

- `ehs:exposureDuration` — `rdfs:range` changed from `xsd:duration` →
  `xsd:string` (with `skos:definition` pinning ISO 8601 duration format).
  Pre-existing issue surfaced by v3.2 validation: `xsd:duration` is outside
  the OWL 2 datatype map and caused HermiT to refuse to load the ontology.
  Application layer must validate the ISO 8601 grammar at ingress.

### Validation

- `rapper -c` parses cleanly: 1446 triples, zero errors.
- `owlready2` structural scan: all 16 Module D classes, all 6 new object
  properties (with correct `rdfs:domain` and `rdfs:range`), and both new
  scenarios resolve. Zero orphan `ehs:` IRIs (every referenced term is
  declared somewhere in the file).
- HermiT reasoner: **consistent** under OWL-DL semantics (0.5 s). No
  contradictions introduced by v3.2 additions.

### Archived

- `v3.1` moved to `.archive/ehs-ontology-v3.1.ttl`.

---

## Prior versions (pre-changelog)

Archived under `.archive/`. Summaries reconstructed from file headers rather
than from authoritative release notes.

### v3.1

Added `ehs:Establishment` as the facility/site anchor for chemical inventory
and OSHA 300 recordkeeping; expanded Section 313 (TRI Form R / Form A);
cross-module wiring (`InventoryChemical ↔ EmissionUnit`,
`Employee → EmissionUnit`, `IncidentSeverity ↔ RecordingCriteria` alignment,
`EnvironmentalIncident → ContextualComplianceActivation`); range fixes on
`addressedByControl` and `connectsToARECC`; `hasRecordingCriteria` domain
widened to `Outcome`.

### v3.0

First four-module release: Module A (EPCRA Tier II / chemical inventory),
Module B (Title V / CAA air permitting), Module C (OSHA 300 recordkeeping),
and a now-reallocated Module D (Employee Incident Management, renamed to
OPERATIONAL in v3.2). Also introduced the `ContextualComplianceActivation`
three-axis routing (HazardType × ActionContext × ContextualCondition).

### v3 extension and v3 merged

Working files preserved for provenance — `ehs-ontology-v3-extension.ttl`
and `ehs-ontology-v3-merged.ttl` in `.archive/`.
