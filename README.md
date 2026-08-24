# MyWants AI

**An Entity Formation Platform.**

MyWants AI identifies things people want or need, determines what Entity could satisfy that
demand, computes the resources required to make that Entity exist, allows people *and AI* to
contribute those resources, and **activates the Entity when the required resource pool is
complete**.

It is not an AI business assistant, an idea generator, a crowdfunding website, a freelance
marketplace, an investment platform, or an AI agent manager. It builds one new economic
primitive: **Collective Entity Formation**.

Its proactive half is the **Data Entity Opportunity Engine**, which analyzes economic,
demographic, labor, trade, technology, and behavioral data — fused with MyWants' own
first-party Want data — to identify things that *should exist but do not yet adequately exist*.

> Traditional data platforms report what is happening. Traditional idea platforms suggest what
> could be built. MyWants identifies what *should* exist, explains what it takes, and attempts
> to make it exist.

## Status

Pre-implementation. The build plan lives in **[docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md)** —
an 8-day MVP schedule targeting the
[All Things Agentic Hackathon](https://allthingsagentichackathon.devpost.com/)
(submission deadline **Aug 31, 2026, 5:00pm PDT**).

## Stack

Built on Google technology end to end:

- **Gemini 3.7 Flash / 3.5 Flash Lite / embedding-001** via **Gemini Enterprise Agent Platform**
  (formerly Vertex AI)
- **Google ADK 2.0** for agent orchestration, with **A2A v1.0** for the agent fleet
- **Cloud Run**, **Cloud Scheduler**, **Pub/Sub**, **Cloud Tasks**, **Firestore** (incl. vector
  search), **BigQuery**, **Cloud Storage**, **Secret Manager**, **Firebase Auth**, and
  **Cloud Trace / Logging / Monitoring**

See the development plan for the full architecture, data model, and phase breakdown.
