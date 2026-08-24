"""Single source of truth for every Gemini model and location this project uses.

COMPLIANCE — All Things Agentic Hackathon (submission deadline 2026-08-31)
==========================================================================
The rules require "Gemini 3.5 or newer, accessed through the Gemini API or
Vertex AI". Vertex AI was renamed **Gemini Enterprise Agent Platform** at Cloud
Next 2026; the API surface, SDK package, and endpoints are unchanged, so
calling GEAP satisfies that requirement exactly.

Every model ID in this file is >= 3.5.

    DO NOT add `gemini-3.1-pro-preview`, or any other 3.1 / 3.0 / 2.x model.

Version 3.1 is OLDER than 3.5 despite carrying the premium "Pro" tier label,
and shipping it would fail eligibility. If a task needs more reasoning power,
reach for a newer Flash and a larger thinking budget — never an older Pro.

Every value below was verified with a live API call on 2026-08-24 against
project `mywants-ai-hack26`. See docs/platform-notes.md for the evidence and
for the SDK symbol names that survived the rebrand.
"""

from __future__ import annotations

import os
from typing import Final

from google import genai
from google.genai import types

# --------------------------------------------------------------------------
# Project + locations
# --------------------------------------------------------------------------
# Generative models and infrastructure live in DIFFERENT locations. This is not
# an oversight: gemini-3.7-flash returns 404 on the us-central1 regional
# endpoint and 200 on the global endpoint. Newest models launch global-first.
#
# Because the two differ, every client must be constructed with an explicit
# `location`. Never let one be inherited from an ambient env var.

PROJECT_ID: Final[str] = os.environ.get("GOOGLE_CLOUD_PROJECT", "mywants-ai-hack26")

REGION: Final[str] = "us-central1"
"""Where infrastructure lives: Firestore, Cloud Run, BigQuery, Pub/Sub, GCS."""

GENERATIVE_LOCATION: Final[str] = "global"
"""Where generative Gemini models are served. Host has NO region prefix."""

EMBEDDING_LOCATION: Final[str] = REGION
"""Embeddings run in-region, co-located with Firestore.

The Want-clustering job embeds hundreds of documents and immediately writes
vectors back to Firestore, so the same-region round trip is worth having.
"""

# --------------------------------------------------------------------------
# Models
# --------------------------------------------------------------------------

REASONING_MODEL: Final[str] = "gemini-3.7-flash"
"""Genuine reasoning: opportunity generation, entity planning, international
transfer analysis, governance decisions, scoring rationale.

This is a THINKING model — it spent 87 thought tokens on an 8-token prompt in
our smoke test. Excellent for judgment, wasteful for bulk work.
"""

FAST_MODEL: Final[str] = "gemini-3.5-flash-lite"
"""High-volume per-record work: normalization, classification, tagging,
per-row summarization. Paired with a low thinking budget below.
"""

EMBEDDING_MODEL: Final[str] = "gemini-embedding-001"
"""Want and opportunity embeddings for Firestore vector search.

NOT `gemini-embedding-2` — that is a product name in the docs, not a callable
model ID, and returns 404 in every location.
"""

EMBEDDING_DIMENSIONS: Final[int] = 768
"""Firestore vector fields cap at 2048 dimensions; 768 is the practical
sweet spot for clustering quality against index size.
"""

# Fallbacks, verified available, if a primary is rate-limited or degraded.
# Both are >= 3.5 and therefore compliant.
REASONING_MODEL_FALLBACK: Final[str] = "gemini-3.6-flash"
FAST_MODEL_FALLBACK: Final[str] = "gemini-3.5-flash"

ALL_MODELS: Final[tuple[str, ...]] = (
    REASONING_MODEL,
    FAST_MODEL,
    EMBEDDING_MODEL,
    REASONING_MODEL_FALLBACK,
    FAST_MODEL_FALLBACK,
)

# --------------------------------------------------------------------------
# Thinking budgets
# --------------------------------------------------------------------------
# Unbounded thinking across per-record work is the most likely way to turn a
# manageable bill into a surprising one. Bound it explicitly at the call site.

THINKING_BUDGET_BULK: Final[int] = 0
"""Per-record work needs no deliberation — it is a mapping, not a judgement."""

THINKING_BUDGET_STANDARD: Final[int] = 2048
"""Scoring, classification with genuine ambiguity, manifest line items."""

THINKING_BUDGET_DEEP: Final[int] = 8192
"""Opportunity generation and international transfer analysis, where the
reasoning IS the product.
"""


def _client(location: str) -> genai.Client:
    """Build a GEAP client pinned to an explicit location.

    Uses `enterprise=True`, the current spelling. `vertexai=True` is the same
    flag under its legacy name — passing both would raise if they ever
    disagreed, so we pass only one.
    """
    return genai.Client(
        enterprise=True,
        project=PROJECT_ID,
        location=location,
    )


def generative_client() -> genai.Client:
    """Client for gemini-3.7-flash / 3.5-flash-lite. Pinned to `global`."""
    return _client(GENERATIVE_LOCATION)


def embedding_client() -> genai.Client:
    """Client for gemini-embedding-001. Pinned to `us-central1`."""
    return _client(EMBEDDING_LOCATION)


def generation_config(
    *,
    thinking_budget: int = THINKING_BUDGET_STANDARD,
    response_schema: type | None = None,
    temperature: float | None = None,
) -> types.GenerateContentConfig:
    """Standard generation config with an explicit thinking budget.

    Passing `response_schema` binds the response to a Pydantic model and
    switches the model to JSON output. Every agent in this project uses it —
    there is no free-text parsing anywhere in the pipeline.
    """
    config = types.GenerateContentConfig(
        thinking_config=types.ThinkingConfig(thinking_budget=thinking_budget),
    )
    if response_schema is not None:
        config.response_mime_type = "application/json"
        config.response_schema = response_schema
    if temperature is not None:
        config.temperature = temperature
    return config


def assert_compliant() -> None:
    """Fail loudly if a non-compliant model ID ever reaches this module.

    Called by the test suite and by scripts/verify-platform.sh. Guards the one
    mistake that would disqualify the entire submission.
    """
    for model in ALL_MODELS:
        if model.startswith("gemini-embedding"):
            continue
        version = model.removeprefix("gemini-").split("-")[0]
        if float(version) < 3.5:
            raise AssertionError(
                f"{model!r} is older than Gemini 3.5 and fails hackathon "
                f"eligibility. See the compliance note at the top of this file."
            )
