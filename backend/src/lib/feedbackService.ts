import { env } from './env.js';

export interface FeedbackPayload {
  body: string;           // full report text
  feature: string;        // feature label slug (compass, essentials, etc.)
  email?: string;         // optional reporter email
  url?: string;           // optional source URL
  ip?: string;            // from X-Forwarded-For (used for country only — not stored)
  timestamp: string;      // ISO string
}

/**
 * Creates a Linear issue via GraphQL issueCreate mutation.
 * Skips gracefully if LINEAR_API_KEY / LINEAR_TEAM_ID / LINEAR_PROJECT_ID are missing.
 */
export async function createLinearIssue(payload: FeedbackPayload): Promise<void> {
  const { LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_PROJECT_ID } = env;
  if (!LINEAR_API_KEY || !LINEAR_TEAM_ID) {
    console.warn('[feedbackService] LINEAR_API_KEY or LINEAR_TEAM_ID not set — skipping Linear');
    return;
  }

  const title = payload.body.slice(0, 60).replace(/\n/g, ' ');
  const description = [
    payload.body,
    '',
    `**Reporter email:** ${payload.email ?? '(not provided)'}`,
    `**Source URL:** ${payload.url ?? '(not provided)'}`,
    `**Timestamp:** ${payload.timestamp}`,
    `**Feature:** ${payload.feature}`,
    '',
    '_Sent from ev-landing alpha_',
  ].join('\n');

  const mutation = `
    mutation IssueCreate($input: IssueCreateInput!) {
      issueCreate(input: $input) {
        success
        issue { id identifier title }
      }
    }
  `;

  const input: Record<string, unknown> = {
    title,
    description,
    teamId: LINEAR_TEAM_ID,
  };
  if (LINEAR_PROJECT_ID) input.projectId = LINEAR_PROJECT_ID;

  const res = await fetch('https://api.linear.app/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: LINEAR_API_KEY,
    },
    body: JSON.stringify({ query: mutation, variables: { input } }),
  });

  if (!res.ok) {
    console.error('[feedbackService] Linear API error:', res.status, await res.text());
  }
}

/**
 * Submits a feedback payload to Linear (creates an issue).
 * Email notifications are handled by Linear's native subscriber notifications —
 * subscribe candrews@empowered.vote and feedback@empowered.vote to the project
 * in Linear settings to receive emails on each new issue.
 */
export async function submitFeedback(payload: FeedbackPayload): Promise<void> {
  await createLinearIssue(payload);
}
