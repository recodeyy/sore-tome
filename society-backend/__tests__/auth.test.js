const request = require('supertest');
const express = require('express');
const jwt = require('jsonwebtoken');

const JWT_SECRET = 'test-secret';
process.env.JWT_SECRET = JWT_SECRET;

const { authMiddleware } = require('../middleware/auth');

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
app.get('/test-auth', authMiddleware, (req, res) => {
  res.json({ user: req.user });
});

describe('Auth Middleware', () => {
  it('should return 401 if no authorization header is present', async () => {
    const res = await request(app).get('/test-auth');
    expect(res.statusCode).toEqual(401);
    expect(res.body.error).toEqual('Missing or invalid Authorization header');
  });

  it('should return 401 if token is invalid', async () => {
    const res = await request(app)
      .get('/test-auth')
      .set('Authorization', 'Bearer invalid-token');
    expect(res.statusCode).toEqual(401);
    expect(res.body.error).toEqual('Invalid token. Please log in again.');
  });

  it('should pass and inject user if token is valid', async () => {
    const user = { uid: '123', phone: '1234567890', name: 'Test User', role: 'resident', society_id: 'soc1' };
    const token = jwt.sign(user, JWT_SECRET);
    
    const res = await request(app)
      .get('/test-auth')
      .set('Authorization', `Bearer ${token}`);
    
    expect(res.statusCode).toEqual(200);
    expect(res.body.user).toMatchObject(user);
  });
});
