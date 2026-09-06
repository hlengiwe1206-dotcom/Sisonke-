# Sisonke Live MVP v4 — Verified & Fixed

This package is aligned to the deployed Sisonke Supabase phases 1–7.

## v4 fixes
- Help Exchange now uses the Phase 7 `help_request_feed` view.
- Open Help Requests are streamed live through Supabase Realtime.
- Offer counts are read from `help_request_feed`.
- Request owners receive live Help Offer updates.
- Authentication no longer redundantly upserts profiles; the Phase 2 trigger is authoritative.
- Existing secure RPC workflow is retained for accepting, withdrawing and completing help connections.
- Existing private realtime chat and live connection stream are retained.

## Two-user live test
1. Create Account A and Account B with different email addresses.
2. Account A creates a Help Request.
3. Account B sees it in Help Exchange and submits an offer.
4. Account A sees the offer live and accepts it.
5. Both accounts open My Connections and private chat.
6. Send messages in both directions.
7. Complete the Help Connection.

## Supabase prerequisite
Phases 1–7 must already be deployed, including `help_request_feed` from Phase 7.
