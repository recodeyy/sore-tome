import { logger } from "../shared/Logger";

export enum SecuritySeverity {
  INFO = "INFO",
  WARN = "WARN",
  ALERT = "ALERT",
  CRITICAL = "CRITICAL",
}

export interface SecurityEvent {
  type: string;
  userId?: string;
  ip: string;
  details?: any;
  severity: SecuritySeverity;
}

/**
 * SecurityAlertService
 * Centralized logic for security event intelligence and alerting signals.
 */
export class SecurityAlertService {
  private static instance: SecurityAlertService;

  private constructor() {}

  public static getInstance(): SecurityAlertService {
    if (!SecurityAlertService.instance) {
      SecurityAlertService.instance = new SecurityAlertService();
    }
    return SecurityAlertService.instance;
  }

  /**
   * Tracks and logs a security event with structured metadata.
   */
  public logEvent(event: SecurityEvent) {
    const logMethod = this.getLogMethod(event.severity);
    
    // Structured log for ELK/Datadog ingestion
    logMethod({
      eventType: event.type,
      userId: event.userId || "anonymous",
      ip: event.ip,
      severity: event.severity,
      timestamp: new Date().toISOString(),
      ...event.details
    }, `SEC-SIGNAL [${event.severity}]: ${event.type}`);

    // Trigger immediate alerting logic for CRITICAL events
    if (event.severity === SecuritySeverity.CRITICAL) {
      this.triggerEmergencyAlert(event);
    }
  }

  private getLogMethod(severity: SecuritySeverity) {
    switch (severity) {
      case SecuritySeverity.CRITICAL:
        return logger.fatal.bind(logger);
      case SecuritySeverity.ALERT:
        return logger.error.bind(logger);
      case SecuritySeverity.WARN:
        return logger.warn.bind(logger);
      case SecuritySeverity.INFO:
      default:
        return logger.info.bind(logger);
    }
  }

  private triggerEmergencyAlert(event: SecurityEvent) {
    // In a real production system, this would integrate with:
    // - PagerDuty API
    // - Slack Webhook
    // - SMS Alert (Twilio)
    console.error(`\n🚨 EMERGENCY SECURITY ALERT 🚨\nTYPE: ${event.type}\nUSER: ${event.userId}\nIP: ${event.ip}\n`);
    
    // Log specialized critical marker for log aggregators
    logger.fatal({ 
      ALERT_TYPE: "IMMEDIATE_INTERVENTION_REQUIRED",
      userId: event.userId 
    }, "Security breach signature detected");
  }

  // Convenience methods
  public warn(type: string, ip: string, userId?: string, details?: any) {
    this.logEvent({ type, ip, userId, details, severity: SecuritySeverity.WARN });
  }

  public alert(type: string, ip: string, userId?: string, details?: any) {
    this.logEvent({ type, ip, userId, details, severity: SecuritySeverity.ALERT });
  }

  public critical(type: string, ip: string, userId?: string, details?: any) {
    this.logEvent({ type, ip, userId, details, severity: SecuritySeverity.CRITICAL });
  }
}
