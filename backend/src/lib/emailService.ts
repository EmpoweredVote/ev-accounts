import { Resend } from 'resend';

const resend = process.env.RESEND_API_KEY
  ? new Resend(process.env.RESEND_API_KEY)
  : null;

export async function sendEmail(opts: {
  to: string;
  subject: string;
  html: string;
}): Promise<void> {
  if (!resend) {
    console.warn('[emailService] RESEND_API_KEY not set — skipping email:', opts.subject);
    return;
  }

  const { error } = await resend.emails.send({
    from: 'Empowered Vote <noreply@empowered.vote>',
    to: opts.to,
    subject: opts.subject,
    html: opts.html,
  });

  if (error) {
    console.error('[emailService] send failed:', error);
    // Do NOT throw — email failure should not break the request flow
  }
}
