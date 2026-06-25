const request = require('supertest');
const express = require('express');

// ─────────────────────────────────────────────────────────────────────────────
// CRITICAL: jest.mock is HOISTED by Babel/Jest above ALL variable declarations.
// Any variables referenced inside jest.mock factories MUST use jest.fn() 
// returned from the factory itself, NOT outer-scope variables.
// ─────────────────────────────────────────────────────────────────────────────

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
  CreateNoticeSchema: {},
  UpdateUserSchema: {},
}));
jest.mock('../src/middleware/validate', () => ({
  validate: () => (req, res, next) => next(),
}));

// 1. Firebase mock — all query methods must be self-contained here (no outer vars)
jest.mock('../config/firebase', () => {
  const mockGet = jest.fn(() => Promise.resolve({
    exists: true,
    data: () => ({ society_id: 'soc1' }),
    docs: [{ id: '1', data: () => ({ title: 'Test Notice', body: 'Test Content', society_id: 'soc1' }) }],
    size: 1,
  }));

  const mockDoc = {
    get: mockGet,
    delete: jest.fn(() => Promise.resolve()),
  };

  const mockCollection = {
    where: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: mockGet,
    add: jest.fn(() => Promise.resolve({ id: 'new-notice-id' })),
    doc: jest.fn(() => mockDoc),
  };

  return {
    initFirebase: jest.fn(),
    getDb: jest.fn(() => ({ collection: jest.fn(() => mockCollection) })),
    getAdmin: jest.fn(() => ({
      firestore: { FieldValue: { serverTimestamp: jest.fn(() => 'mock_timestamp') } }
    })),
    getStorage: jest.fn(() => ({
      bucket: jest.fn(() => ({ name: 'test-bucket', file: jest.fn(() => ({ save: jest.fn(() => Promise.resolve()) })) }))
    })),
  };
});

// 2. Mock other dependencies
jest.mock('../src/services/AuditLogService', () => ({
  AuditLogService: {
    getInstance: jest.fn(() => ({ logAdminAction: jest.fn(() => Promise.resolve()) }))
  }
}));

jest.mock('../middleware/auth', () => ({
  authMiddleware: (req, res, next) => {
    req.user = { uid: 'admin1', role: 'admin', society_id: 'soc1', name: 'Test Admin' };
    next();
  },
  adminOnly: (req, res, next) => next(),
}));

jest.mock('../middleware/tenantMiddleware', () => ({
  tenantMiddleware: (req, res, next) => { req.societyId = 'soc1'; next(); },
}));

jest.mock('../services/notificationService', () => ({
  sendToSociety: jest.fn(() => Promise.resolve()),
}));

// 3. Build app AFTER mocks
const noticesRouter = require('../routes/notices');
const NotificationService = require('../services/notificationService');

const app = express();
app.use(express.json());
app.use('/notices', noticesRouter);

describe('Notices API', () => {
  it('GET /notices should return list of notices', async () => {
    const res = await request(app).get('/notices');
    if (res.statusCode !== 200) console.error('GET /notices body:', res.body);
    expect(res.statusCode).toEqual(200);
    expect(res.body.notices).toBeDefined();
    expect(res.body.notices.length).toBeGreaterThan(0);
    expect(res.body.notices[0].title).toEqual('Test Notice');
  });

  it('POST /notices should create a notice and send notification', async () => {
    const res = await request(app)
      .post('/notices')
      .send({ title: 'New Alert', body: 'Something happened', type: 'general' });
    
    if (res.statusCode !== 201) console.error('POST /notices body:', res.body);
    expect(res.statusCode).toEqual(201);
    expect(res.body.id).toEqual('new-notice-id');
    expect(NotificationService.sendToSociety).toHaveBeenCalled();
  });

  it('DELETE /notices/:id should return 404 if notice not in society', async () => {
    const { getDb } = require('../config/firebase');
    const db = getDb();
    const collection = db.collection('notices');
    const doc = collection.doc('some-id');
    doc.get.mockResolvedValueOnce({ exists: true, data: () => ({ society_id: 'other-society' }) });

    const res = await request(app).delete('/notices/some-id');
    expect(res.statusCode).toEqual(404);
  });

  it('DELETE /notices/:id should succeed if notice belongs to society', async () => {
    const res = await request(app).delete('/notices/some-id');
    expect(res.statusCode).toEqual(200);
    expect(res.body.message).toEqual('Notice deleted');
  });
});
