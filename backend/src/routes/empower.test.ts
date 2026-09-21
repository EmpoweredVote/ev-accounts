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

describe('legal_name trimming at the route boundary', () => {
  it('POST /confirm trims a padded legal_name before it reaches the stored public name', async () => {
    mockConfirmEmpowerment.mockResolvedValue({ empowered_profile: { id: 'ep-1' } });

    await request(app)
      .post('/api/empower/confirm')
      .send({ ...fullConsent, legal_name: '  John Doe  ' });

    // The 3rd argument becomes p_legal_name for execute_empowerment — the value
    // stored in the PUBLIC empower.empowered_profiles.legal_name. It must be trimmed.
    expect(mockConfirmEmpowerment).toHaveBeenCalledWith(
      'user-1',
      ['legal_name_public', 'compass_stances_public', 'platform_terms'],
      'John Doe'
    );
  });

  it('POST /preflight trims a padded legal_name so the generated slug has no leading hyphen', async () => {
    mockRunPreflight.mockResolvedValue({
      eligible: true,
      summary: {
        legal_name: 'John Doe',
        compass_completeness: { required: 5, answered: 5, percent: 100, complete: true },
        slug_preview: 'john-doe-a3b4',
      },
    });

    await request(app).post('/api/empower/preflight').send({ legal_name: '  John Doe  ' });

    // runPreflight feeds generateSlug; only a trimmed name keeps the slug from
    // starting with a hyphen (generateSlug('  John Doe  ') => '-john-doe-xxxx').
    expect(mockRunPreflight).toHaveBeenCalledWith('user-1', 'John Doe');
  });

  it('POST /confirm treats a whitespace-only legal_name as absent (keeps the NO_LEGAL_NAME guard path)', async () => {
    mockConfirmEmpowerment.mockResolvedValue({ empowered_profile: { id: 'ep-1' } });

    await request(app)
      .post('/api/empower/confirm')
      .send({ ...fullConsent, legal_name: '   ' });

    // A blank field resolves to undefined so confirmEmpowerment falls back to the
    // DB legal_name (and its NO_LEGAL_NAME guard) — never stores a whitespace name.
    expect(mockConfirmEmpowerment).toHaveBeenCalledWith(
      'user-1',
      ['legal_name_public', 'compass_stances_public', 'platform_terms'],
      undefined
    );
  });
});
