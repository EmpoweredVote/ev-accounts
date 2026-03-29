/**
 * Lambda entry point for the Express API.
 * Uses Lambda Web Adapter (AWS-managed layer) — no code changes needed.
 * The adapter forwards API Gateway requests to Express on localhost:3000.
 *
 * This file just starts Express without the cron jobs or SQS worker.
 * Those run as separate Lambda functions triggered by EventBridge / SQS.
 */
import { app } from '../index.js';
import { campaignFinanceInit } from '../lib/campaignFinanceService.js';

const port = parseInt(process.env.PORT || '3000', 10);

await campaignFinanceInit();

app.listen(port, () => {
  console.info(`[lambda-api] Express listening on port ${port}`);
});
