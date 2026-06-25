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
  CreateIssueSchema: {},
  UpdateIssueStatusSchema: {},
}));
jest.mock('../src/middleware/validate', () => ({
  validate: () => (req, res, next) => next(),
}));

// 1. Firebase mock
jest.mock('../config/firebase', () => {
  const mockGet = jest.fn(() => Promise.resolve({
    exists: true,
    data: () => ({ society_id: 'soc1', postedBy: 'user1' }),
    docs: [{ id: 'issue1', data: () => ({ title: 'Leaking Pipe', description: 'Water everywhere', status: 'pending', society_id: 'soc1' }) }],
    size: 1,
  }));

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
    add: jest.fn(() => Promise.resolve({ id: 'new-issue-id' })),
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

jest.mock('../src/services/AuditLogService', () => ({
  AuditLogService: {
    getInstance: jest.fn(() => ({ log: jest.fn(() => Promise.resolve()) }))
  }
}));

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

jest.mock('../services/notificationService', () => ({
  sendToUser: jest.fn(() => Promise.resolve()),
  sendToSociety: jest.fn(() => Promise.resolve()),
}));

const issuesRouter = require('../routes/issues');
const app = express();
app.use(express.json());
app.use('/issues', issuesRouter);

describe('Issues API', () => {
  it('GET /issues should return list of issues', async () => {
    const res = await request(app).get('/issues');
    if (res.statusCode !== 200) console.error(res.body);
    expect(res.statusCode).toEqual(200);
    expect(res.body.issues).toBeDefined();
    expect(res.body.issues.length).toBeGreaterThan(0);
  });

  it('POST /issues should create an issue', async () => {
    const res = await request(app)
      .post('/issues')
      .send({ title: 'Elevator Broken', description: 'Not working on floor 5', category: 'maintenance' });
    
    if (res.statusCode !== 201) console.error(res.body);
    expect(res.statusCode).toEqual(201);
    expect(res.body.id).toEqual('new-issue-id');
  });

  it('PATCH /issues/:id/status should update issue status', async () => {
    const res = await request(app)
      .patch('/issues/issue1/status')
      .send({ status: 'resolved' });
    
    if (res.statusCode !== 200) console.error(res.body);
    expect(res.statusCode).toEqual(200);
    expect(res.body.message).toContain('updated');
  });
});
