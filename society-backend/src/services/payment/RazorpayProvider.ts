import Razorpay from 'razorpay';
import crypto from 'crypto';
import { PaymentOrder, PaymentProvider, PaymentVerification } from './PaymentProvider';
import { logger } from '../../shared/Logger';

export class RazorpayProvider extends PaymentProvider {
  name = 'razorpay';
  private instance: Razorpay;

  constructor() {
    super();
    const keyId = process.env.RAZORPAY_KEY_ID;
    const keySecret = process.env.RAZORPAY_KEY_SECRET;

    if (!keyId || !keySecret) {
      logger.warn('Razorpay keys missing from environment. Using placeholder mode.');
    }

    this.instance = new Razorpay({
      key_id: keyId || 'rzp_test_placeholder',
      key_secret: keySecret || 'placeholder_secret',
    });
  }

  async createOrder(amount: number, currency: string = 'INR', receipt?: string): Promise<PaymentOrder> {
    try {
      // Razorpay expects amount in subunits (paise for INR)
      const options = {
        amount: Math.round(amount * 100),
        currency,
        receipt: receipt || `receipt_${Date.now()}`,
      };

      const order = await this.instance.orders.create(options);

      return {
        id: order.id,
        amount: amount,
        currency: order.currency,
        receipt: order.receipt,
        status: order.status,
        gateway: this.name,
        metadata: {
          key: process.env.RAZORPAY_KEY_ID, // Frontend needs this to open the checkout
        }
      };
    } catch (error: any) {
      logger.error({ error: error.message }, 'Razorpay Order Creation Failed');
      throw new Error(`Payment gateway error: ${error.message}`);
    }
  }

  async verifyPayment(payload: any): Promise<PaymentVerification> {
    try {
      const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = payload;

      if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
        return { success: false, message: 'Missing Razorpay signature parameters' };
      }

      const keySecret = process.env.RAZORPAY_KEY_SECRET || 'placeholder_secret';
      
      // Verify signature using HMAC-SHA256
      const expectedSignature = crypto
        .createHmac('sha256', keySecret)
        .update(razorpay_order_id + '|' + razorpay_payment_id)
        .digest('hex');

      if (expectedSignature !== razorpay_signature) {
        logger.warn({ ip: payload.ip, orderId: razorpay_order_id }, 'SEC-ALERT: Invalid Razorpay signature detected');
        return { success: false, message: 'Invalid payment signature' };
      }

      // ✅ BUG-02 FIX: Fetch canonical amount from Razorpay API — never trust client body
      let verifiedAmount: number | undefined;
      try {
        const paymentDetails = await this.instance.payments.fetch(razorpay_payment_id);
        // Razorpay returns amount in paise (subunits) — convert to INR
        verifiedAmount = Number(paymentDetails.amount) / 100;
      } catch (fetchErr: any) {
        logger.warn({ razorpay_payment_id, error: fetchErr.message }, 'Could not fetch payment details from Razorpay; amount unverified');
        // verifiedAmount stays undefined — funds.js will handle this
      }

      return {
        success: true,
        message: 'Payment verified successfully',
        transactionId: razorpay_payment_id,
        verifiedAmount,
      };
    } catch (error: any) {
      logger.error({ error: error.message }, 'Razorpay Verification Failed');
      return { success: false, message: 'Verification process failed', error: error.message };
    }
  }
}
