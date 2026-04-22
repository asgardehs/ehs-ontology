# EHS Ontology Documentation

## Files

- **ehs-ontology-v3.3.ttl** — The EHS Ontology (OWL/Turtle). Current
  version. Four regulatory-program modules plus one operational module:
  - Module A: EPCRA Tier II / TRI (chemical inventory reporting)
  - Module B: Title V / CAA (air permitting)
  - Module C: OSHA 300 (injury and illness recordkeeping) — extended
    in v3.3 with ITA CSV export vocabulary, establishment-size/type
    taxonomies, treatment-facility taxonomy, and SKOS mappings from
    Odin's internal severity/case-classification codes to OSHA ITA.
  - Module D: Clean Water Act (NPDES discharge + monitoring, stormwater
    SWPPPs + BMPs, added in v3.2)
  - OPERATIONAL: Employee Incident Management (investigation workflow,
    root cause analysis, corrective actions — cross-cutting, non-regulatory)
  Cross-program `ehs:Permit` umbrella introduced in v3.2 covers Title V,
  FESOP, NPDES, and POTW discharge permits. Validated in Protégé;
  consistent under OWL-DL semantics via HermiT. v3.3 also establishes
  the citation-first rule: all new classes/properties/individuals
  carry `dcterms:source` (regulatory citation) and `rdfs:comment`
  (plain-English explanation). Enforced by
  `tests/queries/coverage-citations.rq`.
- **ehs-ontology-v3.2.ttl** — Prior stable release. Retained in-repo
  (not yet archived) as a reference during the v3.2 → v3.3 migration
  of downstream consumers (odin submodule pointer, research paper
  citations). Will move to `.archive/` once v3.3 has bedded in.
- **CHANGELOG.md** — Version history.
- **docs/plans/** — In-flight plan documents (v3.3 + Mimir viewer).
- **.archive/** — Prior ontology versions retained for provenance
  (v3.1, v3-merged, v3-extension, and the original ehs-ontology.ttl).
- **EHS Geo-Compliance Extension.md** — Design document for the fourth
  routing axis (FacilityJurisdiction). Adds state/county/city regulatory
  overlays on top of the federal baseline. Implementation is v4.0 work.

## Paper

"The Compliance Routing Problem — A Practitioner-Built Ontology for Multi-Agency
EHS Navigation" Adam J. Bick, 2026-04-09. Submitted to EngrXiv.

The paper presents the ontology's formal architecture, validates the three-axis
routing model (HazardType × ActionContext × ContextualCondition) through
nine worked scenarios, and describes the Geo-Compliance Extension design.
The v3.2 revision adds Module D (Clean Water Act) and two additional worked
scenarios (`Scenario_NPDESPermitExceedance`, `Scenario_StormwaterOutfall_MSGP`)
exercising the new regulatory-program chain; the paper's published claims
are on v3.1 and remain unchanged. v3.3 extends Module C with OSHA ITA export
scaffolding and the citation-first rule — orthogonal to the paper's routing
claims.
