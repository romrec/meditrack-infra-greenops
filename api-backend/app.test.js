const request = require('supertest');
const app = require('./index');

describe('MediTrack API', () => {
  test('GET / retourne 200', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
    expect(res.text).toBe('MediTrack API is running');
  });

  test('GET /contacts retourne un tableau', async () => {
    const res = await request(app).get('/contacts');
    expect(res.statusCode).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
  });

  test('POST /contact sans nom retourne 400', async () => {
    const res = await request(app)
      .post('/contact')
      .send({ email: 'test@example.com' });
    expect(res.statusCode).toBe(400);
  });
});
