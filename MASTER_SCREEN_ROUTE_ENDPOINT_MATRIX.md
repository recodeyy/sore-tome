# MASTER_SCREEN_ROUTE_ENDPOINT_MATRIX

**Date:** 2026-06-16
**Author:** QA Director

This document lists the routes, pages, and API endpoints for all modules in SERO.

## 1. Matrix Table

| Flutter Screen | Route | Role Allowed | Backend API Endpoint |
|---|---|---|---|
| `login_screen.dart` | `/login` | Public | `POST /auth/login` |
| `workspace_selector_screen.dart` | `/workspace-select` | Multi-role | `POST /auth/workspace/select` |
| `ai_society_pulse_screen.dart` | `/ai/pulse` | Admin, Committee | `GET /api/v1/ai/pulse` |
| `complaint_intelligence_screen.dart` | `/ai/complaint-intelligence` | Admin, Committee | `GET /api/v1/ai/complaint-clusters` |
| `predictive_maintenance_screen.dart` | `/ai/maintenance` | Admin, Committee | `GET /api/v1/ai/maintenance-predictions` |
| `financial_anomaly_screen.dart` | `/ai/financial-anomaly` | Treasurer, Admin | `GET /api/v1/ai/financial-anomalies` |
| `auth_challenge_screen.dart` | `/challenge` | Multi-role | `POST /auth/challenge` |
| `account_state_screen.dart` | `/account-state` | Multi-role | `GET /users/me` |
