# SERO AI Architecture Plan

**Date:** 2026-06-16
**Author:** Principal AI Architect

This document details the software architecture, services, and integration patterns for SERO's AI services.

## 1. Architectural Structure
- **Service Layer:** `AIInnovationService.ts` contains PostgreSQL queries utilizing native window functions, group aggregates, and conditional scoring logic.
- **Routing:** Endpoints are hosted under `/api/v1/ai/` and utilize standard middleware for authentication and tenant isolation.
- **Task Scheduling:** Background tasks (such as recurring anomaly checks and daily autopilot aggregation) are queued using BullMQ and executed by Redis-backed workers.
- **Outbox Pattern:** High-impact recommendations approved by a user publish events to the outbox database partition to guarantee transaction delivery.

## 2. Model Pipeline
- **Heuristic Models:** Operational scoring (downtime risk, proration, cluster confidence) utilizes deterministic SQL and TypeScript mathematical libraries.
- **Vector Embeddings:** PGVector matches complaints and document rules using cosine similarity distance metrics, providing context to the RAG LLM prompts.
