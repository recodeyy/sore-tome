export interface PaymentOrder {
  id: string;
  amount: number;
  currency: string;
  receipt?: string;
  status: string;
  gateway: string;
  metadata?: any;
}

export interface PaymentVerification {
  success: boolean;
  message: string;
  transactionId?: string;
  /** Amount in standard currency units (e.g. INR), fetched from gateway — NOT from client */
  verifiedAmount?: number;
  error?: string;
}

export abstract class PaymentProvider {
  abstract name: string;

  /**
   * Create an order in the payment gateway
   * @param amount Amount in standard currency units (e.g., INR)
   * @param currency Currency code (e.g., 'INR')
   * @param receipt Optional receipt ID
   */
  abstract createOrder(amount: number, currency: string, receipt?: string): Promise<PaymentOrder>;

  /**
   * Verify the payment response from the gateway
   * @param payload The data sent by the gateway/client for verification
   */
  abstract verifyPayment(payload: any): Promise<PaymentVerification>;
}
