# Sero Society Database Architecture

This document provides a detailed overview of the multi-tier database and storage architecture used in the Sero Society backend.

## 🏛️ Executive Summary
Sero utilizes a **polyglot persistence** strategy to balance real-time responsiveness, complex relational querying, and scalable AI intelligence.

| Technology | Role | Primary Usage |
| :--- | :--- | :--- |
| **Firebase Firestore** | Real-time NoSQL | Core operational data, mobile app synchronization |
| **PostgreSQL** | Relational + Vector | AI long-term memory, audit logs, semantic search |
| **Redis** | In-Memory Data Grid | Caching, Rate limiting, Distributed job queues |
| **Firebase Storage** | Object Storage | Resident document uploads, AI training PDFs |
| **Firebase Auth** | Identity | User authentication and RBAC roles |

---

## 🔥 1. Firebase Firestore (Real-time NoSQL)
Firestore acts as the "source of truth" for the mobile application. Its document-based nature allows for rapid schema evolution and instant UI updates via Streams.

### Core Collections
- `users`: Profiles, role definitions (Admin/Resident), and apartment mappings.
- `notices`: Society-wide announcements (Broadcasts).
- `issues`: Maintenance requests, complaints, and status tracking (`open`, `in_progress`, `resolved`).
- `transactions`: Ledger for society funds and maintenance payments.
- `channels`: Chat channels for resident/admin communication.
- `ai_jobs`: Tracking long-running AI tasks like document ingestion or bulk extraction.

---

## 🐘 2. PostgreSQL (Relational & AI Vector Store)
PostgreSQL handles structured data that requires complex joins or specialized AI search capabilities via `pgvector`.

### Specialized AI Tables
- `document_chunks`: Stores embeddings of society documents (PDFs/Bylaws) for hybrid RAG search.
- `ai_costs`: Granular tracking of LLM token usage and cost-per-request.
- `ai_evaluations`: Quality monitoring for AI responses (accuracy/hallucination scores).
- `ai_prompts`: Version-controlled prompt management with A/B testing support.
- `ai_audit_logs`: Governance logs for AI-triggered actions (e.g., automated notice generation).

---

## ⚡ 3. Redis (Cache & Orchestration)
Redis provides a low-latency layer to protect primary databases and orchestrate background processing.

### Performance & Security
- **Semantic Cache**: Store results of frequent AI queries to reduce LLM costs and latency.
- **Rate Limiting**: Sliding-window throttling per-user and per-society.
- **Circuit Breaker**: Monitoring health of AI providers (Groq, Cloudflare, Cerebras).
- **BullMQ**: Managing the `ai-production-queue` for asynchronous document processing.

---

## 📁 4. Firebase Storage (Unstructured Data)
Used for all binary large objects (BLOBs).
- **Paths**:
  - `documents/`: PDFs and images processed by the AI Ingestion engine.
  - `profile_pics/`: User avatars.
  - `issue_media/`: Photos attached to maintenance requests.

---

## 🔄 5. Data Flow Example: Document Ingestion
1. **Storage**: Resident uploads a PDF to `Firebase Storage`.
2. **Firestore**: A record is created in `ai_jobs` with status `uploading`.
3. **Redis**: A job is pushed to the `ai-production-queue`.
4. **Backend**: The `AIQueueService` worker picks up the job, parses the text via `ParserService`.
5. **PostgreSQL**: Text chunks are embedded and saved to `document_chunks` (Vector table).
6. **Firestore**: The `ai_jobs` record status is updated to `indexed`, triggering a real-time pulse in the UI.
