# MyWants AI — Entity Factory Platform: Development Plan

## Context

**Why this exists.** MyWants AI is an *Entity Formation Platform* — a new economic primitive called **Collective Entity Formation**. It identifies things people want or need, determines what Entity could satisfy that demand, computes the resources required to make that Entity exist, lets people *and AI* contribute those resources, and **activates the Entity when the required resource pool is complete**. It is explicitly not an AI assistant, idea generator, crowdfunding site, freelance marketplace, or agent manager.

The second document adds the platform's proactive half: the **Data Entity Opportunity Engine**, which analyzes economic, demographic, labor, trade, technology, and behavioral data — fused with MyWants' own first-party Want data — to identify *things that should exist but do not yet adequately exist*, and pushes the strongest into Formation.

**What prompted this plan.** Submission to the [All Things Agentic Hackathon](https://allthingsagentichackathon.devpost.com/), sponsored by Google.

**Hard constraints (verified against the rules page):**

| Constraint | Value |
| --- | --- |
| Submission deadline | **Aug 31, 2026, 5:00pm PDT** — **8 days from today (Aug 23)** |
| Project newness | Must be *newly created* during Aug 3–31, 2026. Pre-existing code must be disclosed. The empty repo is an asset. |
| Required model | **Gemini 3.5 or newer**, via Gemini API or Vertex AI — now **Gemini Enterprise Agent Platform** (see naming note below) |
| Required framework | ≥1 Google agent framework: **ADK**, GenAI SDK, Antigravity SDK, or GenKit |
| Required infra | ≥1 Google Cloud service: Cloud Run, Cloud SQL, Firestore, GKE, Pub/Sub |
| Must submit | Live URL, repo + README spin-up steps, **architecture diagram**, **≤4-min demo video showing live execution on Google Cloud**, text description |
| Judging | Innovation & Operational Utility 40% · Architectural Discipline 30% · Demo & Production Readiness 30% |

**Decisions locked with the user:**
- **Primary track: The Taskmaster** — complete autonomous workflows that *take action*. The A2A fleet layer additionally makes this same submission a genuine contender for **The Fortified Enterprise Fleet**, and the architecture depth for **Best Architectural Design**.
- **Velocity: ~7x my baseline estimate** — one day of the user's build time ≈ one week of conventional estimate. Scope below is sized accordingly; what would normally be Phase 2 and much of Phase 3 lands *inside* the MVP window.
- **Scope: full loop plus three depth tracks** — (1) data depth + backtesting, (2) A2A agent registry / fleet / memory bank / governance, (3) real formation depth with contributor reputation, milestones, equity-credit ledger, and the feedback loop.
- **Data: hybrid** — BigQuery public datasets as backbone plus live external APIs, led by World Bank Indicators v2 (keyless).
- **Contributions: Firestore append-only ledger + Stripe test mode** for capital pledges.
- **Calendar: max scope through Day 7 (Aug 30)**, record and submit Aug 31.
- **Deferred by choice:** multimodal UX (voice/photo Want capture, generated entity visuals). Kept in the Phase 2 roadmap.

**Intended outcome.** A deployed Google Cloud platform where a judge watches an autonomous agent fleet ingest real public data on a schedule, surface an economic mismatch, generate and score an Entity Opportunity with full provenance, get approved by an admin, auto-plan an Entity with a Resource Manifest, accept human *and* A2A-registered AI-agent contributions, and **watch the Entity auto-activate and produce real artifacts** — in under four minutes.

---

## One risk I want on the record

"Max scope through Day 7" leaves the demo video to a single tired take on Aug 30–31, and **30% of the score is demo and production readiness**. I am not reducing scope — that is your call and you've made it — but the plan includes one cheap insurance policy: **a complete rough-cut demo video recorded at the end of Day 5 (Aug 28)**, using whatever exists then. It costs about an hour and guarantees a submittable video exists no matter what happens in the final 48 hours. The Day 7 recording replaces it if all goes well.

Second, smaller note: **Stripe is a non-Google dependency the judges will not credit.** It stays behind a `PaymentProvider` interface with a null fallback so it can never block the demo path.

---

## Platform naming — Vertex AI is now Gemini Enterprise Agent Platform

Google rebranded **Vertex AI → Gemini Enterprise Agent Platform (GEAP)** at Cloud Next 2026 (announced Apr 22, 2026). What this does and does not change:

| | Status |
| --- | --- |
| Product name and console | **Changed** — "Gemini Enterprise Agent Platform (formerly Vertex AI)" |
| Positioning | **Changed** — agent-first. Model training, AutoML, Model Registry, and Endpoints are now sub-features under the agent platform, rather than the platform being a model service with agent features bolted on. |
| Python SDK package | **Unchanged** — `google-genai` |
| Proto / API namespaces | **Unchanged** — `aiplatform.v1beta1.*` |
| API endpoints | **Unchanged** |
| Existing workloads | **Unchanged** — run as-is under the Gemini Enterprise namespace |

**Two practical consequences for this build:**

1. **Class and env-var names very likely still carry the old prefix**, because the SDK surface did not move — expect `VertexAiMemoryBankService`, `GOOGLE_GENAI_USE_VERTEXAI=true`, and `aiplatform` imports to still be correct. Do not "fix" these to match the new branding. **Verify the actual symbol names on Day 0** and write down what you find; a rename mid-build would be the single most disruptive surprise available.
2. **The hackathon rules still say "Gemini API or Vertex AI."** State the equivalence explicitly in the README and Devpost description — *"Gemini 3.7 Flash accessed via Gemini Enterprise Agent Platform (formerly Vertex AI)"* — so a judge checking the rule text maps it in one read instead of wondering whether we used something else.

This rebrand is also a small positioning win: the submission is built on Google's **agent-first** platform, which is exactly the framing the Taskmaster and Fortified Enterprise Fleet tracks reward.

---

## Technology stack

All three hackathon requirements are satisfied several times over.

### Models (requirement: Gemini 3.5+)

| Role | Model ID | Why |
| --- | --- | --- |
| Primary reasoning: opportunity generation, entity planning, international transfer, governance decisions | `gemini-3.7-flash` | Newest stable Flash; strong agentic planning; fast enough for a live demo |
| High-volume subagents: normalization, classification, tagging, per-record summarization | `gemini-3.5-flash-lite` | Cost/latency optimized for thousands of small calls |
| Want + opportunity embeddings | `gemini-embedding-001` (768 dims) | Firestore vector fields cap at 2048 dims; 768 is the practical sweet spot |

> **Compliance trap — read this before writing any agent code.** Do **not** reach for `gemini-3.1-pro-preview` because it is labeled "Pro." Version 3.1 is **older than 3.5** and would **fail eligibility**. Every model ID must be ≥ 3.5. Centralize them in a single `services/agents/models.py` with a compliance comment so a judge can verify in one file.

Access through **Gemini Enterprise Agent Platform** (formerly Vertex AI) via the `google-genai` SDK — not the AI Studio key path — so everything runs under project IAM and appears in Cloud Trace.

### Agent framework (requirement: ≥1 Google framework)

**Google ADK 2.0 GA** — `pip install google-adk`. Uses `LlmAgent`, `SequentialAgent`, `ParallelAgent`, `LoopAgent`, ADK 2.0 **graph workflows** (deterministic code interleaved with model reasoning), function/OpenAPI/MCP tools, callbacks for provenance capture, **Memory Bank** for cross-session long-term memory (ADK class name expected to still read `VertexAiMemoryBankService` — confirm Day 0), and the built-in **evaluation harness**.

### Interop

**A2A protocol v1.0** (`a2a-python` SDK; ADK ships A2A quickstarts). Agent Cards, agent discovery, task lifecycle, SSE streaming, and push notifications for long-running work. *Verify exact SDK surface at build time — v1.0 is recent.*

### Infrastructure (requirement: ≥1 Cloud service — we use twelve)

| Service | Use |
| --- | --- |
| **Gemini Enterprise Agent Platform** | Model access (Gemini 3.7/3.5), **Memory Bank** long-term agent memory, evaluation, agent observability. Formerly Vertex AI. |
| **Cloud Run (services)** | Next.js web app; FastAPI API; ADK agent server; A2A agent endpoints |
| **Cloud Run (jobs)** | Ingestion, signal detection, backtesting, pipeline runner |
| **Cloud Scheduler** | The autonomy proof — pipeline runs on a real cadence |
| **Pub/Sub** | Stage-to-stage events, agent task dispatch, dead-letter topics |
| **Cloud Tasks** | Long-running A2A task callbacks and retries |
| **Firestore (Native)** | Wants, clusters, opportunities, entities, manifests, ledger, agent registry, provenance + native `find_nearest` **vector search** |
| **BigQuery** | Observations warehouse, public datasets, deterministic trend SQL, backtests |
| **Cloud Storage** | Provenance snapshots, raw dataset drops, AI-worker deliverables |
| **Secret Manager** | Stripe test key, external API credentials |
| **Firebase Auth** | User, contributor, and admin identity |
| **Cloud Trace / Logging / Monitoring** | ADK-native tracing; SLO dashboards; the observability story |

Frontend: **Next.js 15 (App Router) on Cloud Run** — one deploy target, server components read Firestore directly.
IaC: **Terraform** in `infra/`, so README spin-up is three commands. This is a direct 30%-of-score item.

---

## Architecture

### The Data Opportunity Loop (from the source document)

```
Data → Signal → Pattern → Economic Mismatch → Opportunity Hypothesis
     → Entity Concept → Opportunity Evaluation → Entity Plan → Formation
```

### Agent topology

Three ADK graph workflows plus an A2A-registered worker fleet.

**Workflow A — `opportunity_engine` (scheduled, fully autonomous)**

1. `IngestAgent` — driven by the **Data Source Registry**. Pluggable connectors: BigQuery public datasets via SQL, HTTP APIs via ADK function tools. Raw to GCS, rows to BigQuery `observations`.
2. `NormalizeAgent` — maps heterogeneous rows to the canonical `Observation`: `{source_id, indicator, geography, period, value, unit, ingested_at}`. Deterministic mappers first; `gemini-3.5-flash-lite` only for unmapped fields.
3. `ChangeDetectionAgent` — **pure BigQuery SQL, no LLM**: YoY delta, CAGR, z-score vs. history, rank shift, breakpoint detection. Emits `Signal` records. *The model interprets; it never measures.* This separation is the core architectural argument.
4. `WantClusterAgent` — embeds Wants with `gemini-embedding-001`, groups via Firestore `find_nearest`, computes cluster metrics: topic, volume, growth, user characteristics, geography, frequency, dissatisfaction, willingness to contribute/pay.
5. `SignalFusionAgent` — the document's four-signal fusion: **Want × Structural × Behavioral × Capability** → `EconomicMismatch` records (demand growth vs. insufficient supply; population growth vs. service shortage; high imports vs. low domestic production; new tech capability vs. old business model).
6. `OpportunityAgent` — `ParallelAgent` fan-out, one branch per mismatch. Produces the full **Data Entity Opportunity Record**: Opportunity Name, Problem, Evidence, Demand, Market, Existing Alternatives, Gap, International Proof, Capability Change, Resource Availability, Risks, Confidence, Recommended Action.
7. `InternationalTransferAgent` — "works there, absent here": identify a successful model, why it works, compare similar markets, identify differences (regulation, culture, infrastructure, distribution), adapt, evaluate viability.
8. `ScoringAgent` — the model produces ten sub-scores; **deterministic code applies the weights**: Demand Strength, Demand Growth, Market Gap, International Validation, AI Feasibility, Human Resource Availability, Capital Efficiency, Distribution Feasibility, Revenue Potential, MyWants Signal → composite 0–100.
9. Writes to the **review queue**. Statuses: `Detected → Monitoring → Researching → Candidate → Approved | Rejected → Archived → Reopened`.

> **Human review is a designed feature, not a gap.** The source document is explicit: *"Signal should not automatically mean Opportunity approval. Human administrative review should remain part of the MVP process."* Present it that way — a Taskmaster agent that knows where to stop is a stronger submission than one that doesn't.

**Workflow B — `entity_formation` (triggered on approval)**

10. `EntityPlannerAgent` — approved Opportunity → Entity Plan (solution, users, market, risks, feasibility).
11. `ResourceManifestAgent` — the platform's core primitive. Typed line items: **capital**, **human roles**, **AI worker roles**, **assets**, **distribution channels**, **milestones**, **activation conditions**.
12. `ContributorMatchAgent` — matches open human line items against contributor skill/reputation profiles and notifies candidates.
13. Ledger accepts contributions: human pledges, Stripe test-mode capital, A2A agent claims. Append-only; equity-credit computed from contribution type and value.
14. `ActivationWatcher` — Firestore-triggered; when every required item is satisfied, flips the Entity to **ACTIVE** and dispatches Workflow C.

**Workflow C — `agent_fleet` (A2A, post-activation)**

15. **Agent Registry** — Firestore-backed catalog of Agent Cards (capabilities, cost, SLA, trust tier, owner). Both first-party ADK workers and third-party A2A agents register here.
16. `FleetDispatcher` — matches open AI-worker manifest items to registered agents by capability, dispatches A2A tasks, tracks the task lifecycle, handles long-running work via push notifications + Cloud Tasks.
17. **Worker agents** produce real deliverables into GCS: brand brief, landing copy, market analysis, competitive scan, milestone plan, financial model skeleton.
18. **Governance layer** — policy checks before dispatch (data-residency, spend caps, trust tier, PII rules), full audit trail, human override. **Memory Bank** on Gemini Enterprise Agent Platform gives agents continuity across sessions and across entities.

**Feedback loop** — `Data → Opportunity → Entity → Performance → Better Data Model`. Activated entities emit performance telemetry; a scheduled `WeightTuningAgent` proposes scoring-weight adjustments, gated by admin approval. Backtesting validates any proposed change against history before it ships.

### Provenance

Every `Signal` retains source, indicator, date, geography, observed value, historical comparison, transformations applied, and AI interpretation. Captured via **ADK callbacks** into immutable `provenance` docs + GCS JSON, surfaced in the UI as an expandable "why we believe this" panel on every opportunity. Wire this on Day 0 — retrofitting provenance is far more expensive than inheriting it.

---

## Data model

**BigQuery** (`mywants`): `observations`, `signals`, `signal_history`, `backtest_runs`, `entity_performance`.

**Firestore collections:**

```
data_sources/        registry: name, dataset, provider, category, geo + time coverage,
                     update frequency, access method, license, last_import_at,
                     quality_status, staleness_score, available_fields, notes
wants/               raw Wants + embedding vector field
want_clusters/       topic, volume, growth, geography, dissatisfaction, wtp
mismatches/          fused four-signal records
opportunities/       13-field Opportunity Record + status + composite score
opportunity_scores/  10 sub-scores + weights + composite + rationale
provenance/          immutable evidence chain per signal/opportunity
entities/            entity plan, status (PLANNING|FORMING|ACTIVE), links
resource_manifests/  manifest header + activation conditions
manifest_items/      typed items w/ required qty, satisfied qty, claimant
contributors/        identity, skills, reputation, contribution history
contributions/       who/what/when, type, value, status
ledger_entries/      append-only; never mutated
equity_credits/      per-contributor credit derived from the ledger
milestones/          per-entity milestone tracking post-activation
agent_registry/      A2A Agent Cards, capabilities, trust tier, SLA, owner
agent_tasks/         A2A task lifecycle, long-running state, results
governance_policies/ spend caps, residency, PII, trust rules
audit_log/           every agent dispatch + admin action
activations/         activation event log
review_queue/        admin actions + audit trail
```

**Shared contracts:** Pydantic in `packages/schemas/python`, mirrored Zod in `packages/schemas/ts`, generated from one source of truth. Every agent uses **structured output** bound to these schemas — no free-text parsing anywhere in the pipeline.

---

## Repository layout

```
mywants/
├── infra/terraform/          # project, APIs, Firestore, BQ, Pub/Sub, Tasks, Scheduler, Run, IAM
├── services/
│   ├── api/                  # FastAPI on Cloud Run
│   ├── agents/               # google-adk package
│   │   ├── models.py         # ← single source of Gemini model IDs (compliance file)
│   │   ├── opportunity_engine/
│   │   ├── entity_formation/
│   │   ├── fleet/            # A2A server, registry, dispatcher, governance
│   │   ├── workers/          # first-party A2A worker agents
│   │   ├── tools/            # BigQuery, HTTP connectors, Firestore tools
│   │   └── callbacks/        # provenance capture
│   └── jobs/                 # Cloud Run jobs: ingest, signal_detect, backtest, pipeline_run
├── web/                      # Next.js 15 on Cloud Run
├── packages/schemas/         # Pydantic + Zod, one source of truth
├── eval/                     # ADK evalsets + backtest fixtures
├── scripts/seed/             # demo seed data (Wants, sources, contributors)
└── docs/
    ├── architecture.md       # + Mermaid diagram, exported PNG for submission
    ├── platform-notes.md     # verified GEAP/ADK symbol names, pinned Day 0
    ├── submission.md         # Devpost text, drafted early not last
    └── demo-script.md
```

---

## Phase 1 — MVP (8 days, Aug 23–31)

Sized at ~7x baseline: each day below is roughly a conventional week. **Deploy every day** — integration is never deferred.

### Day 0 — Aug 23 (today): Foundation + full data plane
- Terraform: project, all APIs enabled, Firestore, BigQuery, Pub/Sub topics + DLQs, Cloud Tasks queues, Scheduler, GCS buckets, Secret Manager, service accounts with least-privilege IAM.
- Monorepo scaffold; `packages/schemas` with the complete contract set; Cloud Build CI/CD on push; Firebase Auth with admin/contributor claims.
- `services/agents/models.py` with the three Gemini IDs + compliance comment.
- **Pin the platform surface first, before any agent code.** Confirm against the live SDK: `google-genai` client init for Gemini Enterprise Agent Platform, the `GOOGLE_GENAI_USE_VERTEXAI` (or successor) env var, and ADK's memory-service class name. Record the verified symbols in `docs/platform-notes.md`. The rebrand left the SDK unchanged, so the old names should still be right — the point is to *know*, not assume.
- **Data Source Registry** with **25+ sources across all seven categories** — demographic, economic, labor, trade, technology, consumer behavior, industry — each with license, coverage, frequency, and quality metadata.
- Pluggable connector framework; BigQuery public-dataset connector + HTTP connector. **Verify exact public dataset/table IDs at build time — do not trust names from this plan.** Live APIs led by World Bank Indicators v2 (keyless), with retry/backoff.
- `IngestAgent` + `NormalizeAgent`; ingest Cloud Run job; raw drops to GCS; dataset quality + staleness scoring.
- **Cost guard from the first query:** `maximum_bytes_billed` on every BigQuery job; materialize small extract tables instead of rescanning public datasets. This is the most likely way to burn the budget.
- **Provenance callbacks wired now**, before any downstream code exists.
- **Exit criteria:** three live Cloud Run URLs; `observations` populated from 10+ real sources including a live API; one `gemini-3.7-flash` call visible in Cloud Trace.

#### Project coordinates (established Day 0)

| | |
| --- | --- |
| Project ID | `mywants-ai-hack26` |
| Project name | MyWants AI |
| Billing account | `0116DC-D0BCA8-06FD36` (HeyKels Billing) |
| Region | `us-central1` — Firestore location is **not editable after creation**; changing it later means recreating the database |
| Repo path in Cloud Shell | `~/mywants` |

#### Verified platform facts (task 0.2/0.3 — measured, not assumed)

| Fact | Status |
| --- | --- |
| `gemini-3.7-flash` on **`global`** endpoint | ✅ **Works** — returned `"modelVersion": "gemini-3.7-flash"` |
| `gemini-3.7-flash` on `us-central1` | ❌ **404 NOT_FOUND** — not available in-region |
| Publisher-model listing via `v1beta1/publishers/google/models` | Returns empty; does not enumerate. Probe with a real call instead. |
| `gemini-3.7-flash` is a **thinking model** | ⚠️ 87 thought tokens for an 8-token prompt |

**Architectural consequence — split locations.** Gemini calls use `location = global`; Firestore, Cloud Run, BigQuery, Pub/Sub, and Cloud Tasks all stay in `us-central1`. This is normal and costs nothing, but it must be right in config from the start:

```
https://aiplatform.googleapis.com/v1/projects/{PROJECT}/locations/global/publishers/google/models/{MODEL}:generateContent
```

Note the global endpoint has **no region prefix** on the host — it is `aiplatform.googleapis.com`, not `global-aiplatform.googleapis.com`. `models.py` must carry `GEMINI_LOCATION = "global"` as a separate constant from `REGION`, and ADK/`google-genai` clients must be initialized with it explicitly rather than inheriting `CLOUDSDK_RUN_REGION`.

**Thinking-token consequence.** Reserve `gemini-3.7-flash` for genuine reasoning (opportunity generation, entity planning, international transfer, governance). Per-record work — normalization, classification, tagging — goes to `gemini-3.5-flash-lite` with an explicit low thinking budget. At Day 1 volumes (25+ indicators × many periods) the difference between the two is the difference between a manageable bill and a surprising one.

#### Development environment: Google Cloud Shell

All build work happens in **Google Cloud Shell**. This is a good choice — `gcloud`, `bq`, `gsutil`, `terraform`, `docker`, `python3`, `node`, and `git` are all pre-installed and pre-authenticated, so Task 0.1 shrinks considerably. Three properties shape how we work:

| Property | Consequence |
| --- | --- |
| `$HOME` persists (5 GB); **everything outside it is wiped** when the VM recycles | Keep the repo, venv, and `node_modules` under `~/mywants`. Never `apt install` to a system path and expect it to survive — pin tool installs into `$HOME` or a re-runnable `scripts/setup.sh`. |
| VM recycles after ~20 min idle / 12 h max session | **Never run long builds in the terminal.** Use Cloud Build (server-side) and Cloud Run jobs, which survive disconnects. This is what we were doing anyway. |
| ~50 hours/week usage quota | A real risk across 8 days of high-velocity work. If the quota binds mid-week, fall back to local `gcloud` or a Compute Engine VM. Worth watching from Day 2 on. |

Practical rules: the repo lives at `~/mywants`; `scripts/setup.sh` restores tooling after a VM recycle; every container build goes through Cloud Build rather than local `docker build`.

**Gotcha hit on Day 0, task 0.2 — `gcloud config` does not survive a session reset.** Cloud Shell generates a fresh ephemeral config (`cloudshell-NNNNN`) each session, so `gcloud config set project` is lost on every recycle, taking exported shell variables with it. Symptom: `ERROR: The required property [project] is not currently set`, and the shell prompt drops its `(project-id)` suffix.

Fix — put the settings in `~/.bashrc`, which lives in the persistent `$HOME`:

```bash
export PROJECT_ID=mywants-ai-hack26
export REGION=us-central1
export CLOUDSDK_CORE_PROJECT=$PROJECT_ID     # env var overrides gcloud config
export CLOUDSDK_RUN_REGION=$REGION
export GOOGLE_CLOUD_PROJECT=$PROJECT_ID      # what client libraries read
```

Anything that must survive a recycle belongs in `~/.bashrc` or `scripts/setup.sh` — never in `gcloud config` or a bare `export` alone.

#### Day 0 task sequence (dependency-ordered, executed one at a time)

Deploy path is de-risked early (0.6) rather than left to the end of the day — a broken deploy discovered at hour 10 costs the whole day.

| # | Task | Blocks | Owner |
| --- | --- | --- | --- |
| 0.1 | **GCP project + billing enabled** | everything | human — needs Google account + billing |
| 0.2 | Enable required APIs; set `gcloud` defaults | 0.5+ | human/CLI |
| 0.3 | **Pin the platform surface** — verify real `google-genai` / ADK symbol names post-rebrand → `docs/platform-notes.md` | all agent code | pair |
| 0.4 | Monorepo scaffold + `services/agents/models.py` (compliance file) | all code | Claude |
| 0.5 | Terraform: state bucket, Firestore, BigQuery, GCS, Pub/Sub + DLQs, Cloud Tasks, Scheduler, Secret Manager, service accounts + least-privilege IAM | 0.6+ | Claude |
| 0.6 | **Hello-world deploys**: Next.js + FastAPI + ADK agent server on Cloud Run, Cloud Build CI/CD on push | de-risks everything after | Claude |
| 0.7 | `packages/schemas`: Pydantic + Zod contracts from one source of truth | 0.8+ | Claude |
| 0.8 | Provenance callback framework (wired before any consumer exists) | all pipeline stages | Claude |
| 0.9 | Data Source Registry schema + 25+ sources across all seven categories | 0.10 | Claude |
| 0.10 | Connector framework: BigQuery public-dataset + HTTP connectors — **verify real dataset/table IDs against the live catalog** | 0.11 | Claude |
| 0.11 | `IngestAgent` + `NormalizeAgent` + ingest Cloud Run job + `maximum_bytes_billed` cost guards | Day 1 | Claude |
| 0.12 | Firebase Auth + admin/contributor custom claims | Day 2 console | Claude |
| 0.13 | Verify Day 0 exit criteria end to end | Day 1 start | pair |

### Day 1 — Aug 24: Signals, clustering, fusion, backtesting
- `ChangeDetectionAgent`: full BigQuery SQL suite — YoY, CAGR, z-score, rank shift, breakpoint — across all registered indicators → `signals`.
- Want capture UI + API; seed 200+ realistic Wants (`scripts/seed`) shaped so genuine clusters emerge.
- `WantClusterAgent`: `gemini-embedding-001` → Firestore vector field → `find_nearest` → clusters + all eight cluster metrics.
- `SignalFusionAgent`: four-signal fusion → `mismatches`.
- **Backtest harness:** replay historical windows and check whether the engine surfaces known market gaps. Results to `backtest_runs`. This is the single most credible thing in the submission — it turns "our AI finds opportunities" into a measurable claim.
- **Exit criteria:** signals across 25+ indicators; real Want clusters; ≥1 fused mismatch; a backtest report with hit/miss counts.

### Day 2 — Aug 25: Opportunity generation, scoring, review console
- `OpportunityAgent` (`ParallelAgent`) → complete 13-field records with structured output.
- `InternationalTransferAgent` — full international comparison and adaptation analysis.
- `ScoringAgent` — 10 sub-scores + deterministic weighted composite + rationale.
- Full Workflow A assembled as an ADK graph; Pub/Sub between stages; **Cloud Scheduler on a real cadence**; idempotency keys per stage.
- Admin **review console**: queue, opportunity detail, evidence/provenance panel, score breakdown, all eight status transitions, audit trail.
- **Exit criteria:** an unattended scheduled run produces scored opportunities with complete provenance, waiting in the review queue.

### Day 3 — Aug 26: Entity Formation depth
- `EntityPlannerAgent` + `ResourceManifestAgent` → entity plan, typed manifest items, activation conditions.
- Contributor profiles: identity, skills, reputation; `ContributorMatchAgent` matching open items to people.
- Contribution API; **append-only ledger**; manifest satisfaction tracking; **equity-credit** derived from contribution type and value.
- Human pledge flows (labor, assets, distribution). **Stripe test mode** behind `PaymentProvider` with a `NullPaymentProvider` fallback; key in Secret Manager.
- `ActivationWatcher` → Entity `ACTIVE` when the manifest is satisfied. Post-activation **milestone tracking**.
- Entity detail page: manifest as a live fill-up view.
- **Exit criteria:** Approve → autonomous Entity Plan + Manifest → contributions fill it → Entity auto-activates with zero manual state changes.

### Day 4 — Aug 27: A2A agent fleet, registry, governance
- **A2A v1.0 server + client**; Agent Cards for every first-party worker.
- **Agent Registry** in Firestore + an agent catalog UI (capabilities, trust tier, SLA, cost, owner, health).
- `FleetDispatcher`: capability matching, A2A task dispatch, task lifecycle tracking, **long-running async tasks** via push notifications + Cloud Tasks, SSE streaming for live progress.
- **Governance layer:** pre-dispatch policy checks (spend caps, data residency, trust tier, PII), full `audit_log`, human override, kill switch.
- **Memory Bank** (Gemini Enterprise Agent Platform) for cross-session, cross-entity agent continuity, wired through ADK's memory service.
- Worker agents producing real GCS deliverables: brand brief, landing copy, market analysis, competitive scan, milestone plan.
- **Exit criteria:** an activated Entity's AI line items are claimed by registered agents over A2A and produce downloadable artifacts; the audit log shows every dispatch and policy decision.

### Day 5 — Aug 28: Feedback loop, dashboard, evaluation — **and the insurance video**
- **Opportunity Intelligence Dashboard**: new signals, emerging Want clusters, potential and high-scoring opportunities, international matches, tech-enabled opportunities, reconsideration candidates, review/approval queues, fleet health.
- **Opportunity Feedback Loop:** entity performance telemetry → `WeightTuningAgent` proposes scoring-weight changes → validated against backtests → admin-gated.
- ADK **evalsets** for scoring, planning, and dispatch agents; wire `adk eval` into CI.
- Cloud Monitoring dashboards + SLOs; Cloud Trace span tree across the whole loop.
- **Record a complete rough-cut demo video (~1 hour).** Insurance only; expected to be replaced Day 7.
- **Exit criteria:** dashboard live on real data; eval suite green in CI; a submittable video exists on disk.

### Day 6 — Aug 29: Hardening and scale
- Retries, idempotency, dead-letter handling, and replay tooling on every pipeline stage and agent task.
- Load-test the pipeline at 10x seed volume; fix what breaks.
- Security pass: IAM tightening to least privilege, Firestore security rules, secret hygiene, input validation on public endpoints, rate limiting.
- Cost guards verified end-to-end; budget alerts.
- Full clean-clone test of the README spin-up. **Untested setup instructions are a classic scoring loss.**
- **Exit criteria:** a chaos pass (kill a job mid-run, revoke an API, feed malformed data) leaves the system recoverable with no data corruption.

### Day 7 — Aug 30: Final scope, docs, rehearsal, final video
- Last capability additions and UI polish (scope closes at midday — protect the recording).
- `docs/architecture.md` + exported **architecture diagram PNG**.
- Load the clean demo dataset; rehearse the full loop end-to-end at least three times.
- **Record the final ≤4-minute demo video.** Draft `docs/submission.md` in full.
- **Exit criteria:** every submission asset exists and has been reviewed once.

### Day 8 — Aug 31 (deadline 5:00pm PDT): Buffer + submit
- **Submit by 12:00pm PDT.** The remaining five hours are pure margin — no work is planned into them.
- Run the compliance checklist below. Select Taskmaster as primary category; add Fortified Enterprise Fleet and Best Architectural Design where Devpost allows multiple.

---

## The 4-minute demo script (30% of the score — designed now, not on Day 7)

| Time | Beat |
| --- | --- |
| 0:00–0:20 | **The problem.** Entrepreneurship begins with a lucky human insight, and most things that should exist never do — nobody assembles the resources. |
| 0:20–0:45 | **The primitive.** MyWants finds what should exist, computes what it takes, and makes it exist. Show the loop diagram. |
| 0:45–1:30 | **Autonomous discovery, live.** Cloud Scheduler fires the pipeline. Real Census + World Bank data → signal → mismatch → scored opportunity. Open the provenance panel: source, indicator, geography, observed value, historical comparison, transformation, interpretation. Flash the backtest result — *"and here is the engine catching a known gap in historical replay."* |
| 1:30–1:55 | **Human judgment where it belongs.** Admin reviews the queue and approves. Emphasize this is a designed control point, not a missing feature. |
| 1:55–2:30 | **Formation, autonomously.** Approval instantly yields an Entity Plan + Resource Manifest: capital, human roles, AI worker roles, assets, distribution, milestones, activation conditions. |
| 2:30–3:15 | **Collective contribution, human and machine.** Human pledges + a capital contribution, then the **agent registry** — AI agents discovered over A2A, claiming line items under governance policy. Manifest fills. |
| 3:15–3:45 | **Activation.** Manifest completes → Entity flips to ACTIVE → agents deliver real artifacts. Open one. |
| 3:45–4:00 | **Proof it ran on Google Cloud.** Cloud Run services, Scheduler history, Cloud Trace span tree, audit log. |

Show the Google Cloud console at least twice. "Live execution on Google Cloud" is an explicit submission requirement, not an implication.

---

## Phase 2+ — Post-hackathon roadmap

**Phase 2 — Multimodal + reach (weeks 2–8).** The deferred multimodal layer: voice and photo Want capture via the Gemini Live API, generated entity visuals, narrated opportunity briefings (targets the Best Multimodal UX posture we skipped). Public entity marketplace. Contributor mobile experience. Expand to 100+ datasets and multi-region discovery.

**Phase 3 — Real formation (months 3–5).** Real capital handling and escrow, legal entity formation integrations, equity-credit with genuine economic meaning, contributor payouts, and entity performance telemetry at scale. Migrate agents from Cloud Run to the **Gemini Enterprise Agent Platform Agent Runtime** for managed autoscaling, sub-second cold starts, and built-in session management.

**Phase 4 — Network (months 6–12).** Open the A2A registry to third-party agent providers with billing and reputation. Self-improving scoring weights trained on realized entity outcomes. Cross-entity resource pooling. Opportunity syndication to partners.

---

## Verification

**Per-stage, during the build:**
```bash
# Ingest + signals
gcloud run jobs execute ingest --region us-central1 --wait
bq query --max_bytes_billed=1000000000 \
  'SELECT source_id, COUNT(*) FROM mywants.observations GROUP BY 1 ORDER BY 2 DESC'
gcloud run jobs execute signal-detect --region us-central1 --wait

# Backtest
gcloud run jobs execute backtest --region us-central1 --wait

# Agents locally, before deploying
adk run services/agents/opportunity_engine
adk eval services/agents/opportunity_engine eval/opportunity.evalset.json

# A2A fleet
curl "$FLEET_URL/.well-known/agent-card.json"    # confirm Agent Card discovery
```

**Full end-to-end acceptance — the exact chain the source document names as MVP success:**
1. Trigger the Scheduler job; confirm `observations` grows with a fresh `ingested_at` from both BigQuery and live-API sources.
2. Confirm new `signals` rows across multiple categories and ≥1 fused `mismatch`.
3. Confirm an `opportunity` with all 13 fields, 10 sub-scores, a composite, and a non-empty provenance chain.
4. Open the provenance panel in the UI and trace one number back to its source row.
5. Approve in the admin console; confirm status transition and audit entry.
6. Confirm an `entity` + `resource_manifest` with typed items and activation conditions appear with no further input.
7. Contribute from a second browser session (human pledge + Stripe test-mode capital); confirm ledger append and equity-credit calculation.
8. Confirm `FleetDispatcher` discovers registered agents, dispatches A2A tasks under policy, and writes `audit_log` entries.
9. Confirm GCS deliverables exist and are downloadable from the entity page.
10. Confirm the Entity flips to **ACTIVE** automatically and an `activations` record is written.
11. Confirm Cloud Trace shows the full span tree for the run, and the Monitoring dashboard is populated.
12. Run the backtest report and confirm hit/miss numbers are reproducible.

**Submission compliance checklist (run before submitting):**
- [ ] Every model ID in `services/agents/models.py` is ≥ Gemini 3.5 — no 3.1-Pro anywhere
- [ ] ADK 2.0 in dependencies and genuinely orchestrating, not wrapping a single call
- [ ] README and Devpost text state the platform equivalence: *"via Gemini Enterprise Agent Platform (formerly Vertex AI)"* — so the rule text "Gemini API or Vertex AI" maps in one read
- [ ] ≥1 required Cloud service — we have twelve; list them in the README
- [ ] Live public URL reachable in an incognito window
- [ ] README spin-up verified in a clean clone
- [ ] Architecture diagram exported and attached
- [ ] Demo video ≤ 4:00, shows live Google Cloud execution
- [ ] Pre-existing code disclosed — there is none; the repo started empty on Aug 23, which is worth stating explicitly

---

## Key risks

| Risk | Mitigation |
| --- | --- |
| **Max scope through Day 7 leaves no video margin** | Insurance rough-cut recorded end of Day 5; scope closes midday Day 7 |
| **Wrong model tier fails eligibility** | Single `models.py`; never use 3.1-Pro despite the "Pro" label |
| **GEAP rebrand causes doc/SDK confusion mid-build** | SDK, protos, and endpoints are unchanged — pin and record the real symbol names in `docs/platform-notes.md` on Day 0; treat blog-post naming as unreliable, the SDK as truth |
| **Judge can't match our stack to the rule text "Vertex AI"** | Spell out the equivalence in README and Devpost description |
| **BigQuery public-dataset cost blowout** | `maximum_bytes_billed` on every job; materialize small extracts; budget alerts Day 6 |
| **A2A v1.0 SDK surface is new and may have shifted** | Verify against the spec on Day 4 morning; first-party agents work over plain HTTP if A2A wiring stalls, with the registry unchanged |
| **Signal quality looks arbitrary to judges** | Deterministic SQL detection + mandatory provenance panel + backtest numbers |
| **Demo depends on a live scheduled run** | Pre-run the pipeline; demo a *recent real* run plus one live trigger, so nothing hangs on camera |
| **Stripe eats time for no scoring credit** | Behind an interface with a null fallback; droppable without regret |
| **Breadth dilutes the core loop** | The loop is complete and deployed by end of Day 3; every later day is additive, never load-bearing for the demo |
