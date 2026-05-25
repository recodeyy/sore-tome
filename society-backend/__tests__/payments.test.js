const request = require('supertest');
const express = require('express');
const crypto = require('crypto');

// 0. Environment configuration
const WEBHOOK_SECRET = 'test_webhook_secret';
process.env.RAZORPAY_WEBHOOK_SECRET = WEBHOOK_SECRET;

// 1. Mock shared infrastructure
jest.mock('../src/shared/Logger', () => ({
  logger: { info: jest.fn(), warn: jest.fn(), error: jest.fn(), fatal: jest.fn(), alert: jest.fn() }
}));
jest.mock('../src/shared/Redis', () => ({
  redisManager: { isConnected: true, getClient: jest.fn(() => ({ get: jest.fn(), set: jest.fn(), incrby: jest.fn(), expire: jest.fn() })) },
  redis: { get: jest.fn(), set: jest.fn(), del: jest.fn() }
}));
jest.mock('../src/shared/CircuitBreaker', () => ({
  firebaseBreaker: { fire: jest.fn((fn) => fn()) }
}));
jest.mock('../src/shared/schemas', () => ({
  CreateTransactionSchema: {},
}));
jest.mock('../src/middleware/validate', () => ({
  validate: () => (req, res, next) => next(),
}));

// 2. Mock Firebase
const mockGet = jest.fn();
const mockTransactionGet = jest.fn();
const mockTransactionSet = jest.fn();
const mockTransactionUpdate = jest.fn();

jest.mock('../config/firebase', () => {
  const mockDoc = {
    get: mockGet,
    set: jest.fn(() => Promise.resolve()),
    update: jest.fn(() => Promise.resolve()),
  };

  const mockCollection = {
    where: jest.fn().mockReturnThis(),
    get: mockGet,
    doc: jest.fn(() => mockDoc),
  };

  return {
    initFirebase: jest.fn(),
    getDb: jest.fn(() => ({
      collection: jest.fn(() => mockCollection),
      runTransaction: jest.fn((callback) => {
        // Immediate execution of transaction callbacks for testing
        const transactionObject = {
          get: mockTransactionGet,
          set: mockTransactionSet,
          update: mockTransactionUpdate,
        };
        return callback(transactionObject);
      }),
    })),
    getAdmin: jest.fn(() => ({
      firestore: {
        FieldValue: {
          serverTimestamp: jest.fn(() => 'mock_timestamp'),
          increment: jest.fn((val) => ({ val, increment: true })),
        },
      },
    })),
  };
});

jest.mock('../middleware/auth', () => ({
  authMiddleware: (req, res, next) => next(),
  canManageFunds: (req, res, next) => next(),
}));

jest.mock('../middleware/tenantMiddleware', () => ({
  tenantMiddleware: (req, res, next) => next(),
}));

const fundsRouter = require('../routes/funds');
const app = express();

// Ensure unparsed req.rawBody is captured, matching server.js
app.use(express.json({
  verify: (req, res, buf) => {
    req.rawBody = buf.toString();
  }
}));

app.use('/funds', fundsRouter);

describe('Razorpay Webhook Payments Verification', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should return 400 if x-razorpay-signature header is missing', async () => {
    const res = await request(app)
      .post('/funds/payments/webhook')
      .send({ event: 'payment.captured' });

    expect(res.statusCode).toEqual(400);
    expect(res.text).toEqual('Bad Request');
  });

  it('should return 400 if signature is invalid', async () => {
    const payload = { event: 'payment.captured' };
    const res = await request(app)
      .post('/funds/payments/webhook')
      .set('x-razorpay-signature', 'invalid_signature_hash')
      .send(payload);

    expect(res.statusCode).toEqual(400);
    expect(res.text).toEqual('Invalid signature');
  });

  it('should return 200 Already processed if webhook is duplicate', async () => {
    const payload = {
      id: 'evt_dup123',
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: 'pay_dup123',
            amount: 150000,
            notes: { society_id: 'soc1', user_id: 'user1' }
          }
        }
      }
    };

    const rawBodyString = JSON.stringify(payload);
    const signature = crypto
      .createHmac('sha256', WEBHOOK_SECRET)
      .update(rawBodyString)
      .digest('hex');

    // Mock webhook database lookup: already exists in processed_webhooks
    mockGet.mockResolvedValueOnce({
      exists: true,
      data: () => ({ processedAt: 'yesterday' })
    });

    const res = await request(app)
      .post('/funds/payments/webhook')
      .set('x-razorpay-signature', signature)
      .set('Content-Type', 'application/json')
      .send(rawBodyString);

    expect(res.statusCode).toEqual(200);
    expect(res.text).toEqual('Already processed');
  });

  it('should successfully process webhook payment and update ledgers', async () => {
    const payload = {
      id: 'evt_new123',
      event: 'payment.captured',
      payload: {
        payment: {
          entity: {
            id: 'pay_new123',
            amount: 150000, // 1500 Rs in subunits
            notes: { society_id: 'soc1', user_id: 'user1' }
          }
        }
      }
    };

    const rawBodyString = JSON.stringify(payload);
    const signature = crypto
      .createHmac('sha256', WEBHOOK_SECRET)
      .update(rawBodyString)
      .digest('hex');

    // 1. Webhook doc does not exist
    mockGet.mockResolvedValueOnce({ exists: false });
    // 2. Transaction search by ID is empty (not processed synchronously yet)
    mockGet.mockResolvedValueOnce({ empty: true });

    // Transaction mock returns
    mockTransactionGet.mockResolvedValueOnce({ exists: false }); // processed_webhooks re-verification
    mockTransactionGet.mockResolvedValueOnce({ exists: true, data: () => ({ totalCollected: 1000 }) }); // society summary exists

    const res = await request(app)
      .post('/funds/payments/webhook')
      .set('x-razorpay-signature', signature)
      .set('Content-Type', 'application/json')
      .send(rawBodyString);

    expect(res.statusCode).toEqual(200);
    expect(res.text).toEqual('OK');

    // Ensure transaction summary balance increments correctly
    expect(mockTransactionUpdate).toHaveBeenCalled();
    expect(mockTransactionSet).toHaveBeenCalledTimes(2); // set transaction log + set webhook idempotency lock
  });
});
