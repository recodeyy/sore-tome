import { PaymentProvider } from './PaymentProvider';
import { RazorpayProvider } from './RazorpayProvider';
import { logger } from '../../shared/Logger';

export class PaymentService {
  private static instance: PaymentService;
  private provider: PaymentProvider;

  private constructor() {
    const gateway = process.env.PAYMENT_GATEWAY || 'razorpay';
    
    switch (gateway.toLowerCase()) {
      case 'razorpay':
        this.provider = new RazorpayProvider();
        break;
      // case 'stripe':
      //   this.provider = new StripeProvider();
      //   break;
      default:
        logger.warn(`Unknown gateway '${gateway}', defaulting to Razorpay`);
        this.provider = new RazorpayProvider();
    }
    
    logger.info(`PaymentService initialized with ${this.provider.name} provider`);
  }

  public static getInstance(): PaymentService {
    if (!PaymentService.instance) {
      PaymentService.instance = new PaymentService();
    }
    return PaymentService.instance;
  }

  public getProvider(): PaymentProvider {
    return this.provider;
  }
}
