const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'test-secret';
process.env.JWT_SECRET = JWT_SECRET;

const { authMiddleware, guardOnly } = require('../middleware/auth');

// Mock dependencies
jest.mock('../src/shared/Logger', () => ({
  logger: {
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

const app = express();
app.use(express.json());

// Set up a mock route requiring guard authorization
app.get('/test-guard-only', authMiddleware, guardOnly, (req, res) => {
  res.json({ success: true, user: req.user });
});

describe('Guard Auth Middleware', () => {
  it('should return 401 if authorization header is missing', async () => {
    const res = await request(app).get('/test-guard-only');
    expect(res.statusCode).toEqual(401);
    expect(res.body.error).toEqual('Missing or invalid Authorization header');
  });

  it('should return 403 Forbidden for "resident" role', async () => {
    const residentUser = {
      uid: 'user1',
      phone: '9999999999',
      name: 'Resident John',
      role: 'resident',
      society_id: 'SOC_DEMO',
    };
    const token = jwt.sign(residentUser, JWT_SECRET);

    const res = await request(app)
      .get('/test-guard-only')
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toEqual(403);
    expect(res.body.error).toEqual('Access denied. Guard or Admin role required.');
  });

  it('should grant access (200) for "guard" role', async () => {
    const guardUser = {
      uid: 'guard1',
      phone: '9999999991',
      name: 'Guard Bob',
      role: 'guard',
      society_id: 'SOC_DEMO',
    };
    const token = jwt.sign(guardUser, JWT_SECRET);

    const res = await request(app)
      .get('/test-guard-only')
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.user).toMatchObject(guardUser);
  });

  it('should grant access (200) for "main_admin" role', async () => {
    const adminUser = {
      uid: 'admin1',
      phone: '9999999992',
      name: 'Admin Alice',
      role: 'main_admin',
      society_id: 'SOC_DEMO',
    };
    const token = jwt.sign(adminUser, JWT_SECRET);

    const res = await request(app)
      .get('/test-guard-only')
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.user).toMatchObject(adminUser);
  });
});
