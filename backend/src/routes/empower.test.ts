import { vi, describe, it, expect, beforeEach } from 'vitest';
import express from 'express';
import request from 'supertest';

// empower.ts imports the auth/tier middleware and empowerService at module scope.
// Mock them so the router mounts without real Supabase/DB env (env.js would otherwise
// process.exit(1) under vitest — same convention as admin.test.ts).
vi.mock('../middleware/auth.js', () => ({
  requireAuth: (req: { userId?: string }, _res: unknown, next: () => void) => {
    req.userId = 'user-1';
    next();
  },
}));
vi.mock('../middleware/tierGuards.js', () => ({
  requireConnected: (_req: unknown, _res: unknown, next: () => void) => next(),
}));

const { mockRunPreflight, mockConfirmEmpowerment, mockExecuteDemotion } = vi.hoisted(() => ({
  mockRunPreflight: vi.fn(),
  mockConfirmEmpowerment: vi.fn(),
  mockExecuteDemotion: vi.fn(),
}));
vi.mock('../lib/empowerService.js', () => ({
  runPreflight: mockRunPreflight,
  confirmEmpowerment: mockConfirmEmpowerment,
  executeDemotion: mockExecuteDemotion,
}));

import empowerRouter from './empower.js';

const app = express();
app.use(express.json());
app.use('/api/empower', empowerRouter);

const fullConsent = {
  consent: { legal_name_public: true, compass_stances_public: true, platform_terms: true },
};

beforeEach(() => {
  mockRunPreflight.mockReset();
  mockConfirmEmpowerment.mockReset();
  mockExecuteDemotion.mockReset();
});

describe('POST /api/empower/confirm — NO_LEGAL_NAME mapping', () => {
  it('maps a NO_LEGAL_NAME error from confirmEmpowerment to 422', async () => {
    const err = new Error('A legal name is required to publish an Empowered profile.');
    (err as NodeJS.ErrnoException).code = 'NO_LEGAL_NAME';
    mockConfirmEmpowerment.mockRejectedValue(err);

    const res = await request(app).post('/api/empower/confirm').send(fullConsent);

    expect(res.status).toBe(422);
    expect(res.body.code).toBe('NO_LEGAL_NAME');
  });

  it('still returns 201 on success', async () => {
    mockConfirmEmpowerment.mockResolvedValue({ empowered_profile: { id: 'ep-1' } });

    const res = await request(app).post('/api/empower/confirm').send(fullConsent);

    expect(res.status).toBe(201);
    expect(res.body.empowered).toBe(true);
  });
});
