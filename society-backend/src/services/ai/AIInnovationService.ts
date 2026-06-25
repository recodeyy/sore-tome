import { db } from '../../shared/Database';
import { logger } from '../../shared/Logger';

/**
 * AI Innovation Service — heuristic / analytics intelligence over the society's
 * operational data. No live LLM is required: every insight is derived from SQL
 * aggregates and deterministic scoring.
 *
 * Every query is tenant-scoped (society_id in every WHERE) and every read goes
 * through safeRows(), so a missing table or empty data yields an empty/zeroed
 * result instead of throwing. This mirrors AnalyticsService's degradation model.
 */

/** Run a query and return its rows; on ANY failure (missing table, bad column,
 *  connection blip) return [] so callers degrade gracefully. */
async function safeRows(sql: string, params: any[]): Promise<any[]> {
  try {
    const { rows } = await db.query(sql, params);
    return rows || [];
  } catch (err) {
    logger.warn({ err }, 'AIInnovationService: query degraded to empty');
    return [];
  }
}

function num(v: any): number {
  const n = Number(v);
  return isNaN(n) ? 0 : n;
}

export interface AIPulseMetrics {
  societyId: string;
  generatedAt: Date;
  complaintHealth: {
    openCount: number;
    overdueCount: number;
    avgResolutionHours: number;
    slaBreachRisk: 'low' | 'medium' | 'high';
    topCategory: string;
  };
  financialHealth: {
    collectionRate: number;
    overdueAmount: number;
    pendingInvoices: number;
    anomalyFlagged: boolean;
    anomalyDetail?: string;
  };
  maintenanceHealth: {
    assetsAtRisk: number;
    overdueWorkOrders: number;
    predictedFailures: string[];
  };
  communityPulse: {
    engagementScore: number;
    recentPolls: number;
    unresolvedNotices: number;
    emergingConcerns: string[];
  };
  staffHealth: {
    presentToday: number;
    absentToday: number;
    openGateCount: number;
  };
  autopilotActions: AutopilotAction[];
}

export interface AutopilotAction {
  id: string;
  type: 'reminder' | 'escalation' | 'maintenance' | 'financial' | 'community';
  priority: 'low' | 'medium' | 'high' | 'critical';
  title: string;
  description: string;
  suggestedAction: string;
  affectedCount?: number;
  estimatedImpact?: string;
  requiresApproval: boolean;
  createdAt: Date;
}

export interface ComplaintCluster {
  clusterId: string;
  rootCause: string;
  affectedUnits: string[];
  complaintIds: string[];
  confidence: number;
  suggestedAssignee?: string;
  estimatedResolutionHours?: number;
  explanation: string;
}

export interface FinancialAnomaly {
  id: string;
  type: 'duplicate_invoice' | 'unusual_expense' | 'budget_overrun' | 'suspicious_adjustment' | 'utility_spike' | 'collection_leakage';
  severity: 'low' | 'medium' | 'high';
  amount: number;
  description: string;
  whyFlagged: string;
  similarHistoricalPattern?: string;
  recommendedAction: string;
  confidence: number;
  requiresHumanReview: boolean;
  flaggedAt: Date;
}

export interface MaintenancePrediction {
  assetId: string;
  assetName: string;
  failureRiskScore: number; // 0-100
  riskLevel: 'low' | 'medium' | 'high' | 'critical';
  recommendedMaintenanceDate: Date;
  costOfDelay: number;
  suggestedVendor?: string;
  confidence: number;
  evidence: string[];
}

export class AIInnovationService {
  /**
   * Society Pulse — combined complaint / financial / maintenance / community /
   * staff signals plus autopilot suggestions. Read-only & tenant-scoped.
   */
  static async generateSocietyPulse(societyId: string): Promise<AIPulseMetrics> {
    logger.info({ societyId }, 'AI: Generating society pulse metrics');

    const [cRows, fRows, payRows, aRows, woRows, pollRows, noticeRows] = await Promise.all([
      // Complaint health
      safeRows(
        `SELECT
           COUNT(*) FILTER (WHERE status IN ('open','in_progress')) AS open_count,
           COUNT(*) FILTER (WHERE status IN ('open','in_progress')
                            AND due_at IS NOT NULL AND due_at < NOW()) AS overdue_count,
           AVG(EXTRACT(EPOCH FROM (resolved_at - created_at))/3600)
             FILTER (WHERE resolved_at IS NOT NULL) AS avg_resolution_hours
         FROM complaints WHERE society_id = $1`,
        [societyId]
      ),
      // Invoiced vs paid (collection)
      safeRows(
        `SELECT
           COALESCE(SUM(total_minor) FILTER (WHERE status = 'published'), 0) AS billed_minor,
           COUNT(*) FILTER (WHERE status = 'published') AS published_count,
           COALESCE(SUM(total_minor) FILTER (WHERE status = 'published'
                    AND due_date IS NOT NULL AND due_date < CURRENT_DATE), 0) AS overdue_billed_minor,
           COUNT(*) FILTER (WHERE status = 'published'
                    AND due_date IS NOT NULL AND due_date < CURRENT_DATE) AS overdue_count
         FROM invoices WHERE society_id = $1`,
        [societyId]
      ),
      safeRows(
        `SELECT COALESCE(SUM(amount_minor) FILTER (WHERE status = 'captured'), 0) AS collected_minor
         FROM payments WHERE society_id = $1`,
        [societyId]
      ),
      // Assets at risk (no completed WO in 180d) — counted in JS from work-order join
      safeRows(
        `SELECT a.id,
                MAX(wo.completed_at) AS last_done
         FROM assets a
         LEFT JOIN maintenance_work_orders wo
           ON wo.asset_id = a.id AND wo.status = 'completed'
         WHERE a.society_id = $1 AND a.status <> 'retired'
         GROUP BY a.id`,
        [societyId]
      ),
      safeRows(
        `SELECT COUNT(*) AS overdue_wo
         FROM maintenance_work_orders
         WHERE society_id = $1 AND status IN ('open','in_progress')
           AND created_at < NOW() - INTERVAL '7 days'`,
        [societyId]
      ),
      safeRows(
        `SELECT COUNT(*) AS recent_polls
         FROM polls WHERE society_id = $1 AND created_at > NOW() - INTERVAL '30 days'`,
        [societyId]
      ),
      safeRows(
        `SELECT COUNT(*) AS unresolved
         FROM notices WHERE society_id = $1 AND status = 'published'
           AND created_at > NOW() - INTERVAL '7 days'`,
        [societyId]
      ),
    ]);

    const c = cRows[0] || {};
    const f = fRows[0] || {};
    const overdueCount = num(c.overdue_count);
    const openCount = num(c.open_count);
    const slaBreachRisk = overdueCount > 10 ? 'high' : overdueCount > 4 ? 'medium' : 'low';

    const topCatRows = await safeRows(
      `SELECT cc.name AS category, COUNT(*) AS n
       FROM complaints c
       LEFT JOIN complaint_categories cc ON cc.id = c.category_id
       WHERE c.society_id = $1 AND c.status IN ('open','in_progress')
       GROUP BY cc.name ORDER BY n DESC LIMIT 1`,
      [societyId]
    );

    const billed = num(f.billed_minor);
    const collected = num(payRows[0]?.collected_minor);
    const overdueAmount = num(f.overdue_billed_minor);
    const pendingInvoices = num(f.overdue_count);
    const collectionRate = billed > 0 ? Math.min(100, (collected * 100) / billed) : 0;

    const anomalyFlagged = overdueAmount > 100000 && collectionRate < 70;

    // Assets at risk: never maintained, or last completed WO > 180 days ago
    const cutoff = Date.now() - 180 * 86400000;
    const assetsAtRisk = aRows.filter(
      (r) => !r.last_done || new Date(r.last_done).getTime() < cutoff
    ).length;

    const autopilotActions = await this._generateAutopilotActions(
      { overdueCount, openCount, slaBreachRisk },
      { collectionRate, overdueAmount, pendingInvoices, anomalyFlagged }
    );

    return {
      societyId,
      generatedAt: new Date(),
      complaintHealth: {
        openCount,
        overdueCount,
        avgResolutionHours: Math.round(num(c.avg_resolution_hours) * 10) / 10,
        slaBreachRisk,
        topCategory: topCatRows[0]?.category || 'general',
      },
      financialHealth: {
        collectionRate: Math.round(collectionRate * 10) / 10,
        overdueAmount,
        pendingInvoices,
        anomalyFlagged,
        anomalyDetail: anomalyFlagged
          ? `High overdue balance (${(overdueAmount / 100).toFixed(0)}) with low collection rate (${collectionRate.toFixed(1)}%)`
          : undefined,
      },
      maintenanceHealth: {
        assetsAtRisk,
        overdueWorkOrders: num(woRows[0]?.overdue_wo),
        predictedFailures: [],
      },
      communityPulse: {
        engagementScore: Math.min(100, num(pollRows[0]?.recent_polls) * 15),
        recentPolls: num(pollRows[0]?.recent_polls),
        unresolvedNotices: num(noticeRows[0]?.unresolved),
        emergingConcerns: overdueCount > 5 ? ['High overdue complaint volume'] : [],
      },
      staffHealth: {
        presentToday: 0,
        absentToday: 0,
        openGateCount: 0,
      },
      autopilotActions,
    };
  }

  /**
   * Complaint Intelligence — group recent open complaints by category to surface
   * systemic (clustered) issues vs isolated incidents.
   */
  static async detectComplaintClusters(societyId: string): Promise<ComplaintCluster[]> {
    logger.info({ societyId }, 'AI: Detecting complaint clusters');

    const rows = await safeRows(
      `SELECT c.id, c.title, c.unit_id, c.assigned_to, c.created_at, c.sla_minutes,
              COALESCE(cc.name, 'general') AS category
       FROM complaints c
       LEFT JOIN complaint_categories cc ON cc.id = c.category_id
       WHERE c.society_id = $1
         AND c.status IN ('open','in_progress')
         AND c.created_at > NOW() - INTERVAL '14 days'
       ORDER BY category, c.created_at DESC`,
      [societyId]
    );

    const groups: Record<string, any[]> = {};
    for (const r of rows) {
      const key = r.category || 'general';
      (groups[key] ||= []).push(r);
    }

    const clusters: ComplaintCluster[] = [];
    for (const [category, grp] of Object.entries(groups)) {
      if (grp.length >= 3) {
        const assignees = grp.map((r) => r.assigned_to).filter(Boolean);
        clusters.push({
          clusterId: `cluster-${category}-${Date.now()}`,
          rootCause: `Recurring ${category} issues across multiple units`,
          affectedUnits: [...new Set(grp.map((r) => r.unit_id).filter(Boolean))],
          complaintIds: grp.map((r) => r.id),
          confidence: Math.min(0.95, 0.6 + grp.length * 0.05),
          suggestedAssignee: assignees[0],
          estimatedResolutionHours: 24,
          explanation: `${grp.length} "${category}" complaints were raised in the last 14 days, suggesting a systemic issue rather than isolated incidents.`,
        });
      }
    }

    return clusters.sort((a, b) => b.complaintIds.length - a.complaintIds.length);
  }

  /**
   * Financial Anomaly & Leakage Detection — duplicate expenses (same vendor +
   * amount) and expense category spikes (> 2x category average).
   */
  static async detectFinancialAnomalies(societyId: string): Promise<FinancialAnomaly[]> {
    logger.info({ societyId }, 'AI: Scanning for financial anomalies');
    const anomalies: FinancialAnomaly[] = [];

    // Duplicate expenses: same vendor + amount within 30 days, submitted >1 time.
    const dupRows = await safeRows(
      `SELECT vendor, amount_minor, COUNT(*) AS count
       FROM expenses
       WHERE society_id = $1 AND vendor IS NOT NULL
         AND created_at > NOW() - INTERVAL '30 days'
       GROUP BY vendor, amount_minor
       HAVING COUNT(*) > 1`,
      [societyId]
    );
    for (const r of dupRows) {
      anomalies.push({
        id: `anomaly-dup-${r.vendor}-${r.amount_minor}`,
        type: 'duplicate_invoice',
        severity: 'high',
        amount: num(r.amount_minor) / 100,
        description: `Duplicate expense: vendor "${r.vendor}" with amount ${(num(r.amount_minor) / 100).toFixed(0)} appeared ${r.count} times in 30 days.`,
        whyFlagged: 'Identical vendor and amount submitted multiple times within 30 days.',
        recommendedAction: 'Review and void duplicate entries before payment.',
        confidence: 0.9,
        requiresHumanReview: true,
        flaggedAt: new Date(),
      });
    }

    // Category spikes: an expense > 2x its category average.
    const spikeRows = await safeRows(
      `WITH cat_avg AS (
         SELECT category, AVG(amount_minor) AS avg_amount
         FROM expenses WHERE society_id = $1 AND category IS NOT NULL
         GROUP BY category
       )
       SELECT e.id, e.category, e.amount_minor, ca.avg_amount
       FROM expenses e
       JOIN cat_avg ca ON ca.category = e.category
       WHERE e.society_id = $1
         AND e.created_at > NOW() - INTERVAL '30 days'
         AND ca.avg_amount > 0
         AND e.amount_minor > ca.avg_amount * 2`,
      [societyId]
    );
    for (const r of spikeRows) {
      const ratio = num(r.amount_minor) / Math.max(1, num(r.avg_amount));
      anomalies.push({
        id: `anomaly-spike-${r.id}`,
        type: 'unusual_expense',
        severity: 'medium',
        amount: num(r.amount_minor) / 100,
        description: `${r.category} expense is ${(ratio * 100).toFixed(0)}% of the category average.`,
        whyFlagged: `Amount ${(num(r.amount_minor) / 100).toFixed(0)} is more than 2x the category average ${(num(r.avg_amount) / 100).toFixed(0)}.`,
        recommendedAction: 'Verify the bill and check for data-entry or billing errors.',
        confidence: 0.75,
        requiresHumanReview: true,
        flaggedAt: new Date(),
      });
    }

    return anomalies;
  }

  /**
   * Predictive Maintenance Intelligence — score each asset's failure risk from
   * age, time since last completed work order, breakdown WO count and downtime.
   */
  static async predictMaintenanceNeeds(societyId: string): Promise<MaintenancePrediction[]> {
    logger.info({ societyId }, 'AI: Predicting maintenance needs');

    const rows = await safeRows(
      `SELECT a.id, a.name, a.type, a.commissioned_on,
              MAX(wo.completed_at) AS last_done,
              COUNT(wo.id) FILTER (WHERE wo.kind = 'breakdown'
                   AND wo.created_at > NOW() - INTERVAL '90 days') AS breakdowns,
              COUNT(dt.id) FILTER (WHERE dt.started_at > NOW() - INTERVAL '90 days') AS downtime_events
       FROM assets a
       LEFT JOIN maintenance_work_orders wo ON wo.asset_id = a.id
       LEFT JOIN asset_downtime dt ON dt.asset_id = a.id
       WHERE a.society_id = $1 AND a.status <> 'retired'
       GROUP BY a.id, a.name, a.type, a.commissioned_on`,
      [societyId]
    );

    const predictions: MaintenancePrediction[] = [];
    for (const r of rows) {
      const ageMonths = r.commissioned_on
        ? (Date.now() - new Date(r.commissioned_on).getTime()) / (1000 * 60 * 60 * 24 * 30)
        : 0;
      const daysSince = r.last_done
        ? (Date.now() - new Date(r.last_done).getTime()) / (1000 * 60 * 60 * 24)
        : 365;

      const rawScore =
        Math.min(40, daysSince / 3) +
        num(r.breakdowns) * 10 +
        num(r.downtime_events) * 6 +
        Math.min(20, ageMonths / 6);

      const failureRiskScore = Math.min(100, Math.round(rawScore));
      const riskLevel =
        failureRiskScore >= 75 ? 'critical' :
        failureRiskScore >= 50 ? 'high' :
        failureRiskScore >= 25 ? 'medium' : 'low';

      if (failureRiskScore >= 25) {
        const daysUntil = Math.max(1, 30 - Math.round((failureRiskScore - 25) / 2));
        predictions.push({
          assetId: r.id,
          assetName: r.name,
          failureRiskScore,
          riskLevel,
          recommendedMaintenanceDate: new Date(Date.now() + daysUntil * 86400000),
          costOfDelay: failureRiskScore * 500,
          confidence: Math.min(0.9, 0.5 + failureRiskScore / 200),
          evidence: [
            daysSince > 90 ? `${Math.round(daysSince)} days since last completed maintenance` : '',
            num(r.breakdowns) > 0 ? `${num(r.breakdowns)} breakdown work orders in 90 days` : '',
            num(r.downtime_events) > 0 ? `${num(r.downtime_events)} downtime events in 90 days` : '',
            ageMonths > 60 ? `Asset is ~${Math.round(ageMonths / 12)} years old` : '',
          ].filter(Boolean),
        });
      }
    }

    return predictions.sort((a, b) => b.failureRiskScore - a.failureRiskScore);
  }

  /** Internal: derive read-only autopilot suggestions from pulse signals. */
  private static async _generateAutopilotActions(
    complaint: { overdueCount: number; openCount: number; slaBreachRisk: string },
    financial: { collectionRate: number; overdueAmount: number; pendingInvoices: number; anomalyFlagged: boolean }
  ): Promise<AutopilotAction[]> {
    const actions: AutopilotAction[] = [];
    const now = new Date();

    if (complaint.slaBreachRisk === 'high') {
      actions.push({
        id: `action-complaint-${now.getTime()}`,
        type: 'escalation',
        priority: 'high',
        title: 'Complaint SLA Breach Alert',
        description: `${complaint.overdueCount} complaints are overdue. Resident satisfaction at risk.`,
        suggestedAction: 'Send bulk assignment reminders and escalate to committee.',
        affectedCount: complaint.overdueCount,
        estimatedImpact: 'Prevent SLA breach and resident escalation',
        requiresApproval: true,
        createdAt: now,
      });
    }

    if (financial.collectionRate < 70 && financial.pendingInvoices > 0) {
      actions.push({
        id: `action-finance-${now.getTime()}`,
        type: 'reminder',
        priority: 'high',
        title: 'Low Collection Rate Warning',
        description: `Collection rate is ${financial.collectionRate.toFixed(1)}%. ${financial.pendingInvoices} invoices overdue.`,
        suggestedAction: 'Send personalized payment reminders to overdue residents.',
        affectedCount: financial.pendingInvoices,
        estimatedImpact: `Potential recovery: ${(financial.overdueAmount / 100).toFixed(0)}`,
        requiresApproval: true,
        createdAt: now,
      });
    }

    if (financial.anomalyFlagged) {
      actions.push({
        id: `action-anomaly-${now.getTime()}`,
        type: 'financial',
        priority: 'critical',
        title: 'Financial Anomaly Detected',
        description: 'Unusual financial pattern detected. Requires treasurer review.',
        suggestedAction: 'Review flagged invoices and expenses in the anomaly report.',
        requiresApproval: false,
        createdAt: now,
      });
    }

    return actions;
  }
}
