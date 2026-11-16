import { Router } from 'express';

// This service answers on api.empowered.vote and accounts-api.empowered.vote.
// Neither host has pages for people, only JSON endpoints, so ask every crawler
// to stay out. Without this, /robots.txt fell through to the HTML 404 page.
export const ROBOTS_TXT = 'User-agent: *\nDisallow: /\n';

const router = Router();

router.get('/robots.txt', (_req, res) => {
  res.type('text/plain').send(ROBOTS_TXT);
});

export default router;
