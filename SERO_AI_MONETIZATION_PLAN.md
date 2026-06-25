# SERO AI Monetization Plan

**Date:** 2026-06-16
**Author:** Chief AI Product Officer

This document outlines the packaging, pricing tiers, and monetization strategy for SERO's AI capabilities.

## 1. Monetization Packaging

| Tier | Included Features | Pricing Model | Buyer |
|---|---|---|---|
| **Core (Standard)** | Basic RAG Copilot, Complaint classification. | Included in base subscription. | Residents / Admins |
| **Premium Operations** | Society Pulse Dashboard, Complaint Clustering. | Flat +$49/month per society. | Society Committee |
| **Enterprise / Financial** | Financial Anomaly Radar, Predictive Maintenance. | Flat +$99/month per society. | Treasurer / Facility Mgr |
| **AI Workflows (Autopilot)** | Multi-step autopilot orchestration, Custom RAG search over documents. | Usage-based credits ($0.05/credit). | Society Committee |

## 2. Margin Safety Guardrails
- **Token Usage Limits:** Endpoints are rate-limited via `express-rate-limit` (10 requests/minute) to control LLM cost-to-serve.
- **Cache Optimization:** Common RAG queries are cached in Redis to reduce external API token costs.
