# SERO AI Evaluation Plan

**Date:** 2026-06-16
**Author:** QA/Evaluation Engineer

This document defines the metrics and frameworks to evaluate AI performance and accuracy.

## 1. Offline Evaluation Metrics
- **Clustering Accuracy:** Evaluated via Rand Index and Silhouette Coefficients over synthetic duplicate complaint datasets.
- **Downtime Score Calibration:** Mean Absolute Error (MAE) between risk scores and actual breakdown occurrences.
- **RAG Precision/Recall:** Exact citation coverage metrics tracked using custom offline evaluation scripts (`__tests__/ai_chat.integration.test.ts`).

## 2. Online/Operational Metrics
- **Recommendation Acceptance Rate:** Target threshold > 75% for Autopilot suggestions.
- **SLA Reduction Rate:** Target 15% reduction in complaint resolution time.
- **False Accusation Rate:** Strict 0% target for financial anomalies. Anomaly labels explicitly specify "review required" rather than fraud accusations.
