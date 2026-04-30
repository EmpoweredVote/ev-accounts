import { env } from './env.js';

export interface FeedbackScreenshot {
  buffer: Buffer;
  contentType: string;
  filename: string;
}

export interface FeedbackPayload {
  body: string;           // full report text
  feature: string;        // feature label slug (compass, essentials, etc.)
  email?: string;         // optional reporter email
  url?: string;           // optional source URL
  ip?: string;            // from X-Forwarded-For (used for country only — not stored)
  timestamp: string;      // ISO string
  screenshot?: FeedbackScreenshot; // optional image attachment
}

const LINEAR_GRAPHQL = 'https://api.linear.app/graphql';

/**
 * Uploads an image to Linear via the two-step fileUpload + PUT flow.
 * Returns the public assetUrl on success, or null on any failure.
 *
 * Linear's CSP blocks browser uploads to its storage, so this MUST run
 * server-side. We base64-decode the screenshot from the form payload
 * and pipe the bytes through.
 *
 * @see https://linear.app/developers/how-to-upload-a-file-to-linear
 */
async function uploadScreenshotToLinear(
  screenshot: FeedbackScreenshot,
): Promise<string | null> {
  const { LINEAR_API_KEY } = env;
  if (!LINEAR_API_KEY) return null;

  // Step 1 — request a signed upload URL from Linear
  const uploadMutation = `
    mutation FileUpload($contentType: String!, $filename: String!, $size: Int!) {
      fileUpload(contentType: $contentType, filename: $filename, size: $size) {
        success
        uploadFile {
          uploadUrl
          assetUrl
          headers { key value }
        }
      }
    }
  `;

  const uploadReq = await fetch(LINEAR_GRAPHQL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: LINEAR_API_KEY,
    },
    body: JSON.stringify({
      query: uploadMutation,
      variables: {
        contentType: screenshot.contentType,
        filename: screenshot.filename,
        size: screenshot.buffer.length,
      },
    }),
  });

  if (!uploadReq.ok) {
    console.error('[feedbackService] fileUpload mutation HTTP error:', uploadReq.status, await uploadReq.text());
    return null;
  }

  const uploadJson = (await uploadReq.json()) as {
    data?: {
      fileUpload?: {
        success: boolean;
        uploadFile?: {
          uploadUrl: string;
          assetUrl: string;
          headers: { key: string; value: string }[];
        };
      };
    };
    errors?: unknown;
  };

  const file = uploadJson?.data?.fileUpload?.uploadFile;
  if (!file) {
    console.error('[feedbackService] fileUpload mutation response missing uploadFile:', JSON.stringify(uploadJson));
    return null;
  }

  // Step 2 — PUT the bytes to the signed URL with all required headers
  const putHeaders: Record<string, string> = {
    'Content-Type': screenshot.contentType,
    'Cache-Control': 'public, max-age=31536000',
  };
  for (const { key, value } of file.headers) {
    putHeaders[key] = value;
  }

  const putRes = await fetch(file.uploadUrl, {
    method: 'PUT',
    headers: putHeaders,
    // Wrap Buffer → Uint8Array for fetch's BodyInit type. The bytes are identical.
    body: new Uint8Array(screenshot.buffer),
  });

  if (!putRes.ok) {
    console.error('[feedbackService] file PUT failed:', putRes.status, await putRes.text());
    return null;
  }

  return file.assetUrl;
}

/**
 * Creates a Linear issue via GraphQL issueCreate mutation.
 * If a screenshot is attached, uploads it first and embeds it in the
 * issue description as markdown image syntax.
 *
 * Skips gracefully if LINEAR_API_KEY / LINEAR_TEAM_ID are missing.
 */
export async function createLinearIssue(payload: FeedbackPayload): Promise<void> {
  const { LINEAR_API_KEY, LINEAR_TEAM_ID, LINEAR_PROJECT_ID } = env;
  if (!LINEAR_API_KEY || !LINEAR_TEAM_ID) {
    console.warn('[feedbackService] LINEAR_API_KEY or LINEAR_TEAM_ID not set — skipping Linear');
    return;
  }

  // Upload screenshot first (if any) so we can embed it in the description
  let screenshotMarkdown = '';
  if (payload.screenshot) {
    const assetUrl = await uploadScreenshotToLinear(payload.screenshot);
    if (assetUrl) {
      screenshotMarkdown = `\n\n**Screenshot:**\n\n![Screenshot](${assetUrl})`;
    } else {
      screenshotMarkdown = '\n\n_(Screenshot upload failed — see API logs)_';
    }
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
  ].join('\n') + screenshotMarkdown;

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

  const res = await fetch(LINEAR_GRAPHQL, {
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
