import { Router } from 'express';
import { redis } from '../lib/redis.js';

const router = Router();

router.get('/health', async (req, res) => {
  const redisOk = redis.isAvailable();
  res.status(200).json({
    status: 'ok',
    timestamp: Date.now(),
    ...(redisOk ? {} : { redis: 'degraded' }),
  });
});

export default router;
