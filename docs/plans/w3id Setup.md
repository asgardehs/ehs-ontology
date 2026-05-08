# Setting Up w3id.org for the AsgardEHS Ontology

**Goal:** Replace `http://example.org/ehs-ontology#` with a stable, resolvable namespace using w3id.org as a permanent
redirect, with the actual ontology hosted on GitHub Pages.

**Final IRI:** `https://w3id.org/asgardehs/ehs#`

**Versioning approach:** Version-free namespace with `owl:versionIRI` metadata (Interpretation B). Term IRIs stay
constant across versions; the document evolves.

---

## Mental Model

w3id.org is a redirect switchboard. Your IRI `https://w3id.org/asgardehs/ehs#ChemicalHazard` doesn't _contain_ anything
— when something requests it, w3id.org reads a config file you wrote and tells the requester "the real content is over
there." For now, "there" is GitHub Pages. Later, when you get your own domain, you change one config file and every
external reference to your ontology silently follows.

The split that makes this work:

- **Ontology IRI** — `https://w3id.org/asgardehs/ehs` — stable forever. This is what people import. Term IRIs
  (`ehs:ChemicalHazard`, etc.) live "inside" this.
- **Version IRI** — `https://w3id.org/asgardehs/ehs/3.3.0` — pins a specific release snapshot. Changes with each
  version.

Anyone who imports the ontology IRI always gets latest. Anyone who needs "the EHS ontology as it stood when I cited it"
imports the version IRI instead.

---

## Order of Operations

1. Update the TTL header and namespace (do this first — affects everything else)
2. Set up the GitHub Pages repo with proper directory structure
3. Verify the TTL is fetchable from GitHub Pages
4. Submit the w3id.org PR
5. End-to-end test once the PR is merged

The reason for this order: **a w3id PR pointing at a 404 will get rejected.** Hosting must work before the redirect is
submitted.

---

## Step 1 — Update the TTL

### 1a. Replace the namespace everywhere

Find-and-replace across the entire file:

- `http://example.org/ehs-ontology#` → `https://w3id.org/asgardehs/ehs#`

This catches `@prefix` declarations, the `owl:Ontology` IRI, and any term IRIs that were written out in full rather than
using the prefix.

### 1b. Replace the ontology header

Replace whatever your current `owl:Ontology` declaration looks like with this:

```turtle
@prefix :         <https://w3id.org/asgardehs/ehs#> .
@prefix ehs:      <https://w3id.org/asgardehs/ehs#> .
@prefix owl:      <http://www.w3.org/2002/07/owl#> .
@prefix rdfs:     <http://www.w3.org/2000/01/rdf-schema#> .
@prefix xsd:      <http://www.w3.org/2001/XMLSchema#> .
@prefix dcterms:  <http://purl.org/dc/terms/> .
@prefix skos:     <http://www.w3.org/2004/02/skos/core#> .

@base <https://w3id.org/asgardehs/ehs> .

<https://w3id.org/asgardehs/ehs> a owl:Ontology ;
    owl:versionIRI    <https://w3id.org/asgardehs/ehs/3.3.0> ;
    owl:versionInfo   "3.3.0" ;
    owl:priorVersion  <https://w3id.org/asgardehs/ehs/3.1.0> ;
    dcterms:title     "AsgardEHS Ontology"@en ;
    dcterms:creator   "Adam [Last Name]" ;
    dcterms:issued    "2026-05-07"^^xsd:date ;
    dcterms:modified  "2026-05-07"^^xsd:date ;
    dcterms:license   <https://creativecommons.org/licenses/by/4.0/> ;
    dcterms:description "Ontology for environmental health and safety regulatory routing across federal frameworks (OSHA, EPA, DOT) with contextual compliance activation."@en .
```

**Things to fill in / decide:**

- `dcterms:creator` — your name as it appears on the paper
- `dcterms:issued` — first publication date for v3.3.0 (or whichever version this is)
- `dcterms:modified` — today, on each release
- `dcterms:license` — CC-BY 4.0 is the default for academic ontologies. MIT or Apache-2.0 also fine but less
  conventional. Skip this line entirely if you haven't picked yet, but expect reviewers to ask.
- `owl:priorVersion` — only if you actually have a frozen prior release published. If v3.3 is your first public release,
  drop this line.

### 1c. Sanity-check the file

```bash
# Validate Turtle syntax (any of these works if you have them)
rapper -i turtle -c ehs.ttl
riot --validate ehs.ttl
robot validate --input ehs.ttl
```

Confirm no leftover `example.org` strings:

```bash
grep -n "example.org" ehs.ttl
# should return nothing
```

---

## Step 2 — GitHub Pages Hosting

### 2a. Repo structure

Create or organize the repo (suggested name: `asgardehs/ehs-ontology`) like this:

```
ehs-ontology/
├── ehs.ttl                       ← current/live version
├── index.html                    ← human-readable docs landing page
├── README.md                     ← repo overview
└── snapshots/
    ├── ehs-3.1.0.ttl             ← frozen copy of v3.1
    └── ehs-3.3.0.ttl             ← frozen copy of v3.3
```

**The discipline:** Every release, copy the new `ehs.ttl` into `snapshots/ehs-X.Y.Z.ttl` and never touch that snapshot
again. Snapshots are immutable; `ehs.ttl` is the moving target. This is what makes B's promise of "permanently citable
versions" actually true.

### 2b. Enable Pages

Repo Settings → Pages → Source: deploy from `main` branch, root directory.

### 2c. The index.html

A minimal landing page so humans visiting the IRI in a browser get something readable instead of raw Turtle. Doesn't
have to be fancy — title, abstract, link to paper, link to TTL, contact info. You can elaborate this later; what matters
is that _something_ loads.

### 2d. Verify hosting works

Before doing anything with w3id, confirm these all return HTTP 200 with correct content:

```bash
curl -I https://asgardehs.github.io/ehs-ontology/ehs.ttl
curl -I https://asgardehs.github.io/ehs-ontology/snapshots/ehs-3.3.0.ttl
curl -I https://asgardehs.github.io/ehs-ontology/
```

If any of these 404, fix before proceeding. **A failed redirect target is the #1 reason w3id PRs get rejected.**

---

## Step 3 — The w3id.org Pull Request

### 3a. Fork

Fork `https://github.com/perma-id/w3id.org` to your GitHub account. Clone your fork locally.

### 3b. Create the directory

```
w3id.org/asgardehs/
├── .htaccess
└── README.md
```

### 3c. The `.htaccess`

```apache
# AsgardEHS Ontology — permanent identifier configuration
# Contact: Adam [Last Name] <your-email@domain>

Options -MultiViews
AddType text/turtle .ttl
AddType application/rdf+xml .rdf
AddType application/ld+json .jsonld

RewriteEngine On
RewriteBase /asgardehs/

# Current ontology — Turtle for machines (reasoners, curl, Protégé)
RewriteCond %{HTTP_ACCEPT} text/turtle [OR]
RewriteCond %{HTTP_ACCEPT} application/x-turtle
RewriteRule ^ehs$ https://asgardehs.github.io/ehs-ontology/ehs.ttl [R=302,L]

# Current ontology — HTML for humans in browsers
RewriteCond %{HTTP_ACCEPT} text/html [OR]
RewriteCond %{HTTP_USER_AGENT} ^Mozilla
RewriteRule ^ehs$ https://asgardehs.github.io/ehs-ontology/ [R=302,L]

# Default — serve TTL when nothing specific was asked for
RewriteRule ^ehs$ https://asgardehs.github.io/ehs-ontology/ehs.ttl [R=302,L]

# Versioned snapshots — for owl:versionIRI resolution
# Matches /asgardehs/ehs/3.3.0 → snapshots/ehs-3.3.0.ttl
RewriteRule ^ehs/([0-9]+\.[0-9]+\.[0-9]+)$ https://asgardehs.github.io/ehs-ontology/snapshots/ehs-$1.ttl [R=302,L]
```

**On 302 vs 303:** Strictly correct for "this IRI is a concept, here's a document about it" is `303 See Other`. `302` is
simpler and works with every client. Use `302` now; tighten to `303` later if a reviewer asks.

### 3d. The `README.md`

```markdown
# AsgardEHS Ontology Permanent Identifiers

Contact: Adam [Last Name] <your-email@domain> Project: AsgardEHS — Environmental Health & Safety Ontology Repository:
https://github.com/asgardehs/ehs-ontology

## Identifiers

- https://w3id.org/asgardehs/ehs — EHS Ontology (Turtle / HTML via content negotiation)
- https://w3id.org/asgardehs/ehs/3.3.0 — EHS Ontology v3.3.0 snapshot
- https://w3id.org/asgardehs/ehs/3.1.0 — EHS Ontology v3.1.0 snapshot
```

The linkchecker bot reads the README, so every URL listed here must actually resolve. List only versions you've actually
published snapshots for.

### 3e. Commit and PR

```bash
git checkout -b add-asgardehs-redirect
git add asgardehs/
git commit -m "Add asgardehs redirect for EHS ontology"
git push origin add-asgardehs-redirect
```

Open a pull request against `perma-id/w3id.org` `master`. Use a descriptive title that includes the project name. Squash
any messy commit history into one commit before submitting.

Reviewers typically merge within hours to a few days. Once merged, the redirect goes live immediately.

---

## Step 4 — End-to-End Verification

Once the PR is merged, run these checks:

```bash
# Should return TTL with the new namespace inside it
curl -L -H "Accept: text/turtle" https://w3id.org/asgardehs/ehs

# Should redirect to the HTML docs
curl -L -H "Accept: text/html" https://w3id.org/asgardehs/ehs

# Should return the v3.3.0 snapshot
curl -L https://w3id.org/asgardehs/ehs/3.3.0

# Should resolve from inside Protégé — open this URL as an ontology import
# https://w3id.org/asgardehs/ehs
```

If the curl returns the TTL but the namespace inside still says `example.org`, you missed step 1a. Go back and fix.

---

## Maintenance Discipline (Going Forward)

### Releasing a new version

1. Edit `ehs.ttl` with whatever changes the new version introduces
2. Update the header:
   - `owl:versionIRI` → new version snapshot URL
   - `owl:versionInfo` → new version string
   - `owl:priorVersion` → previous version snapshot URL
   - `dcterms:modified` → today's date
3. Copy `ehs.ttl` to `snapshots/ehs-X.Y.Z.ttl`
4. Commit both files together so the snapshot matches the live file at the moment of release
5. Add the new version to the w3id `README.md` (separate PR to perma-id repo)

### Handling meaning-drift in terms

The trade-off you accepted with Interpretation B: term IRIs stay constant, so meaning changes are _invisible_ to
external imports unless you flag them.

When a term changes meaning or gets split:

```turtle
# Don't delete — that breaks citations.
# Deprecate and redirect users to the replacement.
ehs:ChemicalHazard a owl:Class ;
    owl:deprecated true ;
    rdfs:comment "Deprecated in v4.0. Use AcuteChemicalHazard or ChronicChemicalHazard depending on exposure pattern."@en ;
    skos:related ehs:AcuteChemicalHazard, ehs:ChronicChemicalHazard .
```

Reasoners and Protégé respect `owl:deprecated` and warn anyone still using the old term.

**The contract:** Change is allowed. Removal isn't. Meaning-shift requires explicit deprecation annotations.

---

## Quick Reference — File Checklist

| File                      | Where                                      | What                                        |
| ------------------------- | ------------------------------------------ | ------------------------------------------- |
| `ehs.ttl`                 | `asgardehs/ehs-ontology` repo, root        | Live ontology with new namespace and header |
| `index.html`              | `asgardehs/ehs-ontology` repo, root        | Human-readable docs landing page            |
| `snapshots/ehs-3.3.0.ttl` | `asgardehs/ehs-ontology` repo              | Frozen copy of v3.3.0 release               |
| `.htaccess`               | `perma-id/w3id.org` fork, `asgardehs/` dir | Redirect rules                              |
| `README.md`               | `perma-id/w3id.org` fork, `asgardehs/` dir | Contact info + identifier list              |

---

## Decisions Already Made

- **Top-level identifier:** `asgardehs` (extensible — future things like geo-extension can live at `asgardehs/ehs-geo`)
- **Versioning approach:** B — version-free namespace, version metadata in ontology header
- **Redirect target:** GitHub Pages at `https://asgardehs.github.io/ehs-ontology/` (interim until you get your own
  domain)
- **Redirect code:** 302
- **License:** TBD — recommend CC-BY 4.0

## Decisions Still Open

- License (if not CC-BY 4.0)
- Whether to publish the v3.1.0 snapshot at all, or only v3.3.0 going forward
- When to migrate to your own domain (no rush — w3id IRI stays the same when you do)
