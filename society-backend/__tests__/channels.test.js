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

// 1. Firebase mock
jest.mock('../config/firebase', () => {
  const mockGet = jest.fn(() => Promise.resolve({
    exists: true,
    data: () => ({ society_id: 'soc1', name: 'General', allowedRoles: ['resident'] }),
    docs: [{ id: 'chan1', data: () => ({ name: 'General', type: 'public', society_id: 'soc1', allowedRoles: ['resident'] }) }],
    size: 1,
    forEach: jest.fn(),
  }));

  const mockDoc = {
    get: mockGet,
    update: jest.fn(() => Promise.resolve()),
    collection: jest.fn(() => ({
      orderBy: jest.fn().mockReturnThis(),
      limit: jest.fn().mockReturnThis(),
      get: mockGet,
      add: jest.fn(() => Promise.resolve({ id: 'new-msg-id' })),
    })),
  };

  const mockCollection = {
    where: jest.fn().mockReturnThis(),
    orderBy: jest.fn().mockReturnThis(),
    limit: jest.fn().mockReturnThis(),
    get: mockGet,
    add: jest.fn(() => Promise.resolve({ id: 'new-chan-id' })),
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
    req.user = { uid: 'user1', role: 'resident', society_id: 'soc1', name: 'Test User' };
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
  sendToSociety: jest.fn(() => Promise.resolve()),
}));

const channelsRouter = require('../routes/channels');
const app = express();
app.use(express.json());
app.use('/channels', channelsRouter);

describe('Channels API', () => {
  it('GET /channels should return list of channels', async () => {
    const res = await request(app).get('/channels');
    if (res.statusCode !== 200) console.error(res.body);
    expect(res.statusCode).toEqual(200);
    expect(res.body.channels).toBeDefined();
  });

  it('POST /channels should create a new channel', async () => {
    const res = await request(app)
      .post('/channels')
      .send({ name: 'Emergency', type: 'announcement' });
    
    if (res.statusCode !== 201) console.error(res.body);
    expect(res.statusCode).toEqual(201);
    expect(res.body.id).toEqual('new-chan-id');
  });

  it('GET /channels/:id/messages should return messages', async () => {
    const res = await request(app).get('/channels/chan1/messages');
    if (res.statusCode !== 200) console.error(res.body);
    expect(res.statusCode).toEqual(200);
    expect(res.body.messages).toBeDefined();
  });
});
