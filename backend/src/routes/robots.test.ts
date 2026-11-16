import express from 'express';
import request from 'supertest';
import { describe, expect, it } from 'vitest';
import robotsRouter, { ROBOTS_TXT } from './robots.js';

describe('GET /robots.txt', () => {
  const app = express();
  app.use(robotsRouter);

  it('serves a plain-text disallow-all file', async () => {
    const res = await request(app).get('/robots.txt');
    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toMatch(/^text\/plain/);
    expect(res.text).toBe(ROBOTS_TXT);
    expect(res.text).toContain('User-agent: *');
    expect(res.text).toContain('Disallow: /');
  });
});
