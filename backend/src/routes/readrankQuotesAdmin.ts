// /api/admin/readrank-quotes/* — admin-only Read & Rank quote selection.
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { requireAuth, type AuthenticatedRequest } from '../middleware/auth.js';
import { requireAdmin } from '../middleware/requireAdmin.js';
import { logAdminAction } from '../lib/adminService.js';
import { listReadrankPoliticians, listReadrankQuotes, selectReadrankQuote, clearReadrankSelection, updateReadrankQuote, deleteReadrankQuote } from '../lib/readrankQuotesService.js';

const router = Router();
router.use(requireAuth, requireAdmin);

// GET /api/admin/readrank-quotes/politicians — all politicians who have at least one quote
router.get('/politicians', async (_req: Request, res: Response): Promise<void> => {
  try {
    const politicians = await listReadrankPoliticians();
    res.status(200).json({ politicians });
  } catch (err) {
    console.error('[GET /admin/readrank-quotes/politicians] error:', err);
    res.status(500).json({ error: 'Failed to list politicians' });
  }
});

const listQuery = z.object({ politician_id: z.string().uuid() });

// GET /api/admin/readrank-quotes?politician_id=...
router.get('/', async (req: Request, res: Response): Promise<void> => {
  const parsed = listQuery.safeParse(req.query);
  if (!parsed.success) {
    res.status(422).json({ error: 'politician_id (uuid) is required' });
    return;
  }
  try {
    const topics = await listReadrankQuotes(parsed.data.politician_id);
    res.status(200).json({ topics });
  } catch (err) {
    console.error('[GET /admin/readrank-quotes] error:', err);
    res.status(500).json({ error: 'Failed to list quotes' });
  }
});

const selectBody = z.object({ quote_id: z.string().uuid() });

// PUT /api/admin/readrank-quotes/select
router.put('/select', async (req: Request, res: Response): Promise<void> => {
  const parsed = selectBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ error: 'quote_id (uuid) is required' });
    return;
  }
  try {
    await selectReadrankQuote(parsed.data.quote_id);
    await logAdminAction(
      (req as AuthenticatedRequest).userId,
      'readrank_quote.select',
      null,
      { quote_id: parsed.data.quote_id },
    );
    res.status(200).json({ ok: true });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to select quote';
    const code = /not found/i.test(msg) ? 404 : /de-identified/i.test(msg) ? 422 : 500;
    if (code === 500) console.error('[PUT /admin/readrank-quotes/select] error:', err);
    res.status(code).json({ error: msg });
  }
});

// question_id is optional: present to clear ONE question in a topic hosting
// several (migration 1377), absent to clear the whole topic.
const deselectBody = z.object({
  politician_id: z.string().uuid(),
  topic_key: z.string().min(1),
  question_id: z.string().uuid().nullish(),
});

// PUT /api/admin/readrank-quotes/deselect — turn a candidate+question (or whole topic) off
router.put('/deselect', async (req: Request, res: Response): Promise<void> => {
  const parsed = deselectBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ error: 'politician_id (uuid), topic_key, and an optional question_id (uuid) are required' });
    return;
  }
  try {
    await clearReadrankSelection(parsed.data.politician_id, parsed.data.topic_key, parsed.data.question_id ?? null);
    await logAdminAction(
      (req as AuthenticatedRequest).userId,
      'readrank_quote.deselect',
      null,
      {
        politician_id: parsed.data.politician_id,
        topic_key: parsed.data.topic_key,
        question_id: parsed.data.question_id ?? null,
      },
    );
    res.status(200).json({ ok: true });
  } catch (err) {
    console.error('[PUT /admin/readrank-quotes/deselect] error:', err);
    res.status(500).json({ error: 'Failed to clear selection' });
  }
});

const updateBody = z.object({
  quote_id: z.string().uuid(),
  quote_text: z.string().min(1),
  deidentified_text: z.string().nullable(),
  source_url: z.string().nullable(),
  source_name: z.string().nullable(),
  editor_note: z.string().nullable(),
});

// PATCH /api/admin/readrank-quotes — edit a quote's text/source
router.patch('/', async (req: Request, res: Response): Promise<void> => {
  const parsed = updateBody.safeParse(req.body);
  if (!parsed.success) {
    res.status(422).json({ error: 'quote_id (uuid) and non-empty quote_text are required' });
    return;
  }
  const { quote_id, quote_text, deidentified_text, source_url, source_name, editor_note } = parsed.data;
  try {
    await updateReadrankQuote(quote_id, {
      quoteText: quote_text,
      deidentifiedText: deidentified_text,
      sourceUrl: source_url,
      sourceName: source_name,
      editorNote: editor_note,
    });
    await logAdminAction(
      (req as AuthenticatedRequest).userId,
      'readrank_quote.update',
      null,
      { quote_id, quote_text, deidentified_text, source_url, source_name, editor_note },
    );
    res.status(200).json({ ok: true });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to update quote';
    const code = /not found/i.test(msg) ? 404 : /de-identified/i.test(msg) ? 422 : 500;
    if (code === 500) console.error('[PATCH /admin/readrank-quotes] error:', err);
    res.status(code).json({ error: msg });
  }
});

const deleteParams = z.object({ quoteId: z.string().uuid() });

// DELETE /api/admin/readrank-quotes/:quoteId — remove a quote entirely
router.delete('/:quoteId', async (req: Request, res: Response): Promise<void> => {
  const parsed = deleteParams.safeParse(req.params);
  if (!parsed.success) {
    res.status(422).json({ error: 'quoteId (uuid) is required' });
    return;
  }
  try {
    await deleteReadrankQuote(parsed.data.quoteId);
    await logAdminAction(
      (req as AuthenticatedRequest).userId,
      'readrank_quote.delete',
      null,
      { quote_id: parsed.data.quoteId },
    );
    res.status(200).json({ ok: true });
  } catch (err) {
    const msg = err instanceof Error ? err.message : 'Failed to delete quote';
    const code = /not found/i.test(msg) ? 404 : 500;
    if (code === 500) console.error('[DELETE /admin/readrank-quotes/:quoteId] error:', err);
    res.status(code).json({ error: msg });
  }
});

export default router;
