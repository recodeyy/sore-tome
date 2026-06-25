const request = require('supertest');
const express = require('express');
const { tenantMiddleware } = require('../tenantMiddleware');

const app = express();
app.use(express.json());

// Helper to simulate authMiddleware injection
app.use((req, res, next) => {
  if (req.headers.user) {
    req.user = JSON.parse(req.headers.user);
  }
  next();
});

app.get('/test-tenant', tenantMiddleware, (req, res) => {
  res.json({ societyId: req.societyId });
});

describe('Tenant Middleware', () => {
  it('should return 401 if req.user is missing', async () => {
    const res = await request(app).get('/test-tenant');
    expect(res.statusCode).toEqual(401);
    expect(res.body.error).toEqual('Authentication required for tenant enforcement');
  });

  it('should return 403 if req.user.society_id is missing', async () => {
    const res = await request(app)
      .get('/test-tenant')
      .set('user', JSON.stringify({ uid: '123' }));
    expect(res.statusCode).toEqual(403);
    expect(res.body.error).toContain('societyId) is required');
  });

  it('should pass and inject societyId if society_id is present', async () => {
    const res = await request(app)
      .get('/test-tenant')
      .set('user', JSON.stringify({ uid: '123', society_id: 'soc123' }));
    
    expect(res.statusCode).toEqual(200);
    expect(res.body.societyId).toEqual('soc123');
  });
});
