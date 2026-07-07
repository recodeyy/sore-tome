const request = require('supertest');
const express = require('express');

// 0. Mock shared infrastructure
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

// 1. Firebase mock
jest.mock('../config/firebase', () => {
  const mockGet = jest.fn(() => {
    const data = { society_id: 'soc1', amount: 1500, maintenanceExempt: false, uid: 'user1', target: 200000, currency: 'Rs' };
    const docs = [{ id: 'tx1', data: () => ({ title: 'Maintenance', amount: 2000, type: 'credit', society_id: 'soc1', category: 'maintenance', addedBy: 'user1' }) }];
    return Promise.resolve({
      exists: true,
      data: () => data,
      docs,
      size: docs.length,
      forEach: function(cb) { docs.forEach(cb); }
    });
  });

  const mockDoc = {
    get: mockGet,
    update: jest.fn(() => Promise.resolve()),
    delete: jest.fn(() => Promise.resolve()),
  };

  const mockCollection = {
    where: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: mockGet,
    add: jest.fn(() => Promise.resolve({ id: 'new-tx-id' })),
    doc: jest.fn(() => mockDoc),
  };

  return {
    initFirebase: jest.fn(),
    getDb: jest.fn(() => ({ 
      collection: jest.fn(() => mockCollection),
      batch: jest.fn(() => ({ commit: jest.fn(), update: jest.fn(), delete: jest.fn() })) 
    })),
    getAdmin: jest.fn(() => ({
      firestore: { 
        FieldValue: { serverTimestamp: jest.fn(() => 'mock_timestamp') },
        Timestamp: { fromDate: jest.fn((d) => ({ toDate: () => d })) }
      }
    })),
  };
});

jest.mock('../middleware/auth', () => ({
  authMiddleware: (req, res, next) => {
    req.user = { uid: 'admin1', role: 'admin', society_id: 'soc1', name: 'Test Admin' };
    next();
  },
  adminOnly: (req, res, next) => next(),
  mainAdminOnly: (req, res, next) => next(),
  canManageFunds: (req, res, next) => next(),
  canManageContent: (req, res, next) => next(),
}));

jest.mock('../middleware/tenantMiddleware', () => ({
  tenantMiddleware: (req, res, next) => { req.societyId = 'soc1'; next(); },
}));

const fundsRouter = require('../routes/funds');
const app = express();
app.use(express.json());
app.use('/funds', fundsRouter);

describe('Funds API', () => {
  it('GET /funds/transactions should return list of transactions', async () => {
    const res = await request(app).get('/funds/transactions');
    if (res.statusCode !== 200) console.error(res.body);
    expect(res.statusCode).toEqual(200);
    expect(res.body.transactions).toBeDefined();
  });

  it('GET /funds/summary should return financial summary', async () => {
    const res = await request(app).get('/funds/summary');
    if (res.statusCode !== 200) console.error(res.body);
    expect(res.statusCode).toEqual(200);
    expect(res.body.totalCollected).toBeDefined();
  });

  it('POST /funds/transactions should create a transaction', async () => {
    const res = await request(app)
      .post('/funds/transactions')
      .send({ title: 'Cleaning Fee', amount: 500, type: 'debit', category: 'maintenance' });
    
    if (res.statusCode !== 201) console.error(res.body);
    expect(res.statusCode).toEqual(201);
    expect(res.body.id).toEqual('new-tx-id');
  });
});
