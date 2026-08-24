# Platform notes — verified, not assumed

Every fact here was measured against the live SDK or a live API call on **2026-08-24**, against project `mywants-ai-hack26`. Where this file disagrees with a blog post, a docs page, or the development plan, **this file wins** — it is the only source that was tested.

Re-verify with `scripts/verify-platform.sh` after any dependency bump.

## Versions

| Package | Version |
| --- | --- |
| `google-adk` | **2.7.1** |
| `google-genai` | **2.19.0** |

## Endpoints and locations — the split that matters

`gemini-3.7-flash` returns **404 NOT_FOUND** on the `us-central1` regional endpoint and **200** on the global endpoint. The newest Gemini models launch global-first on this platform. Embedding models, by contrast, are available in-region.

| Workload | Location | Host |
| --- | --- | --- |
| Generative (`gemini-3.7-flash`, `3.5-flash-lite`) | `global` | `aiplatform.googleapis.com` |
| Embeddings (`gemini-embedding-001`) | `us-central1` | `us-central1-aiplatform.googleapis.com` |
| Firestore, Cloud Run, BigQuery, Pub/Sub, Cloud Tasks, GCS | `us-central1` | — |

The global host has **no region prefix**. It is `aiplatform.googleapis.com`, never `global-aiplatform.googleapis.com`.

Embeddings deliberately stay in `us-central1` to sit next to Firestore: the Want-clustering job embeds hundreds of documents and immediately writes vectors back, so the same-region round trip is worth having.

## Model availability (probed live)

| Model | global | us-central1 |
| --- | --- | --- |
| `gemini-3.7-flash` | ✅ 200 | ❌ 404 |
| `gemini-3.6-flash` | ✅ 200 | not probed |
| `gemini-3.5-flash` | ✅ 200 | not probed |
| `gemini-3.5-flash-lite` | ✅ 200 | not probed |
| `gemini-embedding-001` | ✅ 200 | ✅ 200 |
| `gemini-embedding-2` | ❌ 404 | ❌ 404 |
| `text-embedding-005` | ✅ 200 | ✅ 200 |

**`gemini-embedding-2` does not exist as a callable ID.** The GEAP docs list "Gemini Embedding 2" as a product name; the API does not accept it. Use `gemini-embedding-001`.

**The publisher-model listing endpoint is useless here.** `GET /v1beta1/publishers/google/models` returns an empty result for this project in both locations. To find out whether a model is available, make a real call and read the status code. There is no working catalog to enumerate.

## `enterprise=True` is the new spelling of `vertexai=True`

The rebrand **did** touch the SDK, additively. Both spellings work, but `vertexai` is now explicitly documented as the legacy flag:

```python
# google/genai/client.py
#   enterprise (bool): Indicates whether the client should use the Gemini ...
#   vertexai (bool): Legacy flag for `enterprise`.
```

Resolution rules, read from the source:

- `Client(enterprise=..., vertexai=...)` — if both are set **and conflict**, the client raises. If only one is set, it is used.
- Env vars: `GOOGLE_GENAI_USE_ENTERPRISE` and `GOOGLE_GENAI_USE_VERTEXAI` both exist. If both are set and conflict, **`GOOGLE_GENAI_USE_ENTERPRISE` wins** and a warning is logged.

**Our convention:** set *both* env vars to `true`. They agree, so no conflict is possible, and it works whether a given code path reads the new or the old name. In Python we pass `enterprise=True` explicitly — it is the current spelling and reads as current to a judge.

## Class names — the rebrand did NOT rename these

The plan predicted the old `VertexAi*` prefixes would survive. Confirmed:

| Symbol | Module | Status |
| --- | --- | --- |
| `VertexAiMemoryBankService` | `google.adk.memory` | ✅ still this name (lazy-loaded) |
| `VertexAiRagMemoryService` | `google.adk.memory` | ✅ still this name |
| `VertexAiSessionService` | `google.adk.sessions` | ✅ still this name |

**Do not "fix" these to match GEAP branding.** They are correct as written.

`google.adk.memory` lazy-loads its members through a module `__getattr__`, so `dir()` shows only `BaseMemoryService`. The others import fine — absence from `dir()` is not absence from the package.

## ADK 2.7.1 agent primitives

All present in `google.adk.agents`:

`Agent`, `BaseAgent`, `LlmAgent`, `SequentialAgent`, `ParallelAgent`, `LoopAgent`, `ManagedAgent`, `InvocationContext`, `RunConfig`, plus `*Config` variants for declarative construction.

Session services in `google.adk.sessions`: `InMemorySessionService`, `DatabaseSessionService`, `VertexAiSessionService`.

## Thinking control

`gemini-3.7-flash` is a **thinking model** — it spent **87 thought tokens on an 8-token prompt** in the smoke test. Left unbounded across per-record work, that is the difference between a manageable bill and a surprising one.

`types.ThinkingConfig` accepts: `include_thoughts`, `thinking_budget`, `thinking_level`.

Set via `types.GenerateContentConfig(thinking_config=...)`, which also carries `response_schema` and `response_mime_type` — that pair is how every agent in this project returns structured output instead of parseable prose.

**Policy:** high-volume agents (normalize, classify, tag) run on `gemini-3.5-flash-lite` with an explicit low thinking budget. Reasoning agents (opportunity generation, entity planning, international transfer, governance) get `gemini-3.7-flash` with a real budget.

## Environment variables the SDKs actually read

| Variable | Read by | Value here |
| --- | --- | --- |
| `GOOGLE_CLOUD_PROJECT` | genai, ADK | `mywants-ai-hack26` |
| `GOOGLE_CLOUD_LOCATION` | genai, ADK | `global` for generative clients |
| `GOOGLE_GENAI_USE_ENTERPRISE` | genai, ADK | `true` |
| `GOOGLE_GENAI_USE_VERTEXAI` | genai, ADK | `true` (legacy alias, kept in sync) |

Note `GOOGLE_CLOUD_LOCATION` — **not** `CLOUDSDK_RUN_REGION`, which is a `gcloud` CLI setting the SDKs never read. Because our generative location (`global`) differs from our infrastructure region (`us-central1`), clients must be constructed with an explicit `location` rather than inheriting an ambient one.
