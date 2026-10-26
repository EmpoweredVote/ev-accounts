const RESEND_API_KEY = process.env.RESEND_API_KEY;

export async function sendEmail(opts: {
  to: string | string[];
  subject: string;
  html: string;
}): Promise<boolean> {
  if (!RESEND_API_KEY) {
    console.warn('[emailService] RESEND_API_KEY not set — skipping email:', opts.subject);
    return false;
  }

  try {
    const res = await fetch('https://api.resend.com/emails', {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${RESEND_API_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        from: 'Empowered Vote <noreply@empowered.vote>',
        to: opts.to,
        subject: opts.subject,
        html: opts.html,
      }),
    });

    if (!res.ok) {
      const body = await res.text();
      console.error('[emailService] send failed:', res.status, body);
      return false;
    }
    return true;
  } catch (err) {
    console.error('[emailService] send failed:', err);
    // Do NOT throw — email failure should not break the request flow. Callers that
    // must know (the job-health alarm) read the returned boolean instead.
    return false;
  }
}
