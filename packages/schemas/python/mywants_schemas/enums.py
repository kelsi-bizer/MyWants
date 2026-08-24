"""Controlled vocabularies shared by every stage of the pipeline.

These are contracts, not conveniences. An agent returning a string outside
these sets is a bug that should fail at parse time, not surface three stages
later as a silently-dropped record.
"""

from __future__ import annotations

from enum import StrEnum


class DataCategory(StrEnum):
    """The seven MVP data categories from the source document."""

    DEMOGRAPHIC = "demographic"
    ECONOMIC = "economic"
    LABOR = "labor"
    TRADE = "trade"
    TECHNOLOGY = "technology"
    CONSUMER_BEHAVIOR = "consumer_behavior"
    INDUSTRY = "industry"


class SignalMethod(StrEnum):
    """How a change was detected.

    Every one of these is computed in BigQuery SQL. No model produces a value
    here -- the model interprets signals, it never measures them.
    """

    YOY = "yoy"                  # year-over-year delta
    CAGR = "cagr"                # compound annual growth rate
    ZSCORE = "zscore"            # deviation from the indicator's own history
    RANK_SHIFT = "rank_shift"    # movement in geography ranking
    BREAKPOINT = "breakpoint"    # structural break in the series


class SignalDirection(StrEnum):
    RISING = "rising"
    FALLING = "falling"
    FLAT = "flat"


class MismatchType(StrEnum):
    """The economic mismatches the Opportunity Engine searches for.

    Straight from the source document: demand and supply failing to align.
    """

    DEMAND_EXCEEDS_SUPPLY = "demand_exceeds_supply"
    POPULATION_EXCEEDS_SERVICE = "population_exceeds_service"
    IMPORTS_EXCEED_DOMESTIC = "imports_exceed_domestic"
    CAPABILITY_EXCEEDS_ADOPTION = "capability_exceeds_adoption"
    INTERNATIONAL_ABSENCE = "international_absence"


class SignalKind(StrEnum):
    """The four inputs to signal fusion.

    Strong opportunities come from combining all four; any one alone is noise.
    """

    WANT = "want"                # first-party: what people actually asked for
    STRUCTURAL = "structural"    # economic / demographic / trade data
    BEHAVIORAL = "behavioral"    # search, consumption, engagement
    CAPABILITY = "capability"    # what technology newly makes feasible


class OpportunityStatus(StrEnum):
    """The eight statuses from the source document.

    Detection never jumps straight to APPROVED. Human administrative review is
    a designed control point, not a gap in the automation.
    """

    DETECTED = "detected"
    MONITORING = "monitoring"
    RESEARCHING = "researching"
    CANDIDATE = "candidate"
    APPROVED = "approved"
    REJECTED = "rejected"
    ARCHIVED = "archived"
    REOPENED = "reopened"


class EntityStatus(StrEnum):
    PLANNING = "planning"    # plan exists, manifest not yet built
    FORMING = "forming"      # manifest open, accepting contributions
    ACTIVE = "active"        # manifest satisfied -- the Entity exists
    STALLED = "stalled"      # forming, but no contribution movement
    DISSOLVED = "dissolved"


class ManifestItemType(StrEnum):
    """What a Resource Manifest line item asks the world to supply."""

    CAPITAL = "capital"
    HUMAN_ROLE = "human_role"
    AI_WORKER_ROLE = "ai_worker_role"
    ASSET = "asset"
    DISTRIBUTION = "distribution"


class ContributionType(StrEnum):
    """Humans and AI agents contribute through the same ledger.

    That symmetry is the product thesis, not an implementation shortcut.
    """

    CAPITAL = "capital"
    LABOR = "labor"
    AI_WORK = "ai_work"
    ASSET = "asset"
    DISTRIBUTION = "distribution"


class ContributionStatus(StrEnum):
    PLEDGED = "pledged"        # promised, not yet delivered
    CONFIRMED = "confirmed"    # delivered and counted toward the manifest
    WITHDRAWN = "withdrawn"
    FAILED = "failed"


class AgentTrustTier(StrEnum):
    """Governance gate. FleetDispatcher will not dispatch below the policy
    floor for a given manifest item."""

    FIRST_PARTY = "first_party"    # agents we wrote
    VERIFIED = "verified"          # third-party, reviewed
    COMMUNITY = "community"        # third-party, unreviewed
    UNTRUSTED = "untrusted"        # registered but never dispatched to


class AgentTaskState(StrEnum):
    """A2A task lifecycle."""

    SUBMITTED = "submitted"
    WORKING = "working"
    INPUT_REQUIRED = "input_required"
    COMPLETED = "completed"
    FAILED = "failed"
    CANCELED = "canceled"


class GeographyLevel(StrEnum):
    COUNTRY = "country"
    STATE = "state"
    METRO = "metro"
    COUNTY = "county"


class PeriodGrain(StrEnum):
    YEAR = "year"
    QUARTER = "quarter"
    MONTH = "month"
