import { logger } from "./Logger.js";

export enum CircuitState {
  CLOSED = "CLOSED",
  OPEN = "OPEN",
  HALF_OPEN = "HALF_OPEN",
}

export interface CircuitBreakerOptions {
  failureThreshold: number;
  cooldownPeriodMs: number;
}

/**
 * Enterprise Circuit Breaker (Self-Healing)
 * Used to protect the system from cascading failures in external services (Firebase, AI, etc.)
 */
export class CircuitBreaker {
  private state: CircuitState = CircuitState.CLOSED;
  private failureCount: number = 0;
  private lastFailureTime: number | null = null;
  private nextRetryTime: number | null = null;

  constructor(
    private serviceName: string,
    private options: CircuitBreakerOptions = { failureThreshold: 5, cooldownPeriodMs: 60000 }
  ) {}

  public async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === CircuitState.OPEN) {
      if (Date.now() >= (this.nextRetryTime || 0)) {
        this.state = CircuitState.HALF_OPEN;
        logger.info({ service: this.serviceName }, "🔌 CircuitBreaker: Moving to HALF-OPEN (Testing recovery)");
      } else {
        throw new Error(`Circuit Breaker for ${this.serviceName} is OPEN. Try again later.`);
      }
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (err: any) {
      this.onFailure(err);
      throw err;
    }
  }

  private onSuccess() {
    if (this.state === CircuitState.HALF_OPEN || this.state === CircuitState.OPEN) {
      logger.info({ service: this.serviceName }, "✅ CircuitBreaker: Service recovered, state moved to CLOSED");
    }
    this.state = CircuitState.CLOSED;
    this.failureCount = 0;
    this.lastFailureTime = null;
    this.nextRetryTime = null;
  }

  private onFailure(error: Error) {
    this.failureCount++;
    this.lastFailureTime = Date.now();

    logger.error({ 
      service: this.serviceName, 
      count: this.failureCount, 
      error: error.message 
    }, "❌ CircuitBreaker: Service failure recorded");

    if (this.state === CircuitState.HALF_OPEN) {
      this.trip();
    } else if (this.failureCount >= this.options.failureThreshold) {
      this.trip();
    }
  }

  private trip() {
    this.state = CircuitState.OPEN;
    this.nextRetryTime = Date.now() + this.options.cooldownPeriodMs;
    logger.fatal({ 
      service: this.serviceName, 
      cooldown: `${this.options.cooldownPeriodMs}ms` 
    }, "🚨 CircuitBreaker: State moved to OPEN (Tripped)");
  }

  public getState() {
    return this.state;
  }
}

// Instantiate breakers for core external services
export const firebaseBreaker = new CircuitBreaker("Firebase-Cloud");
export const aiBreaker = new CircuitBreaker("AI-Provider", { failureThreshold: 3, cooldownPeriodMs: 30000 });
export const externalApiBreaker = new CircuitBreaker("External-API");
