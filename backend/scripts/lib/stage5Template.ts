/**
 * stage5Template.ts — fill a Stage 5 prompt template (`.claude/skills/season-topic-prep/templates/*.md`).
 *
 * 🔴 WHY THIS EXISTS: the theme template's `{{LADDER_TEXT}}` slot was filled by hand, and on 2026-11-05 the
 * Mississippi theme pass ran with it unfilled — it grouped the "doesn't fit" notes without the ladder they were
 * notes against, and nothing said so. An unfilled `{{…}}` reads to a subagent as plain text. So the filler
 * refuses one: every slot must be filled, and every value given must fill a slot.
 */

/** One served rung: its value (1–5) and its text. */
export interface Rung {
  value: number;
  text: string;
}

/** A slot name: the `X` in `{{X}}`. */
const SLOT_RE = /\{\{\s*([A-Za-z0-9_]+)\s*\}\}/g;

/** The note to the orchestrator at the top of each template ("fill every {{…}} and delete these comments"). */
const ORCHESTRATOR_COMMENT_RE = /<!--\s*Orchestrator:[\s\S]*?-->\n*/g;

export class TemplateFillError extends Error {}

/** Every slot name the template asks for, once each, in order. */
export function templateSlots(template: string): string[] {
  return [...new Set([...template.matchAll(SLOT_RE)].map((m) => m[1]))];
}

/**
 * Fill every `{{SLOT}}` from `values` and delete the orchestrator comment. Throws, naming them, when a slot has no
 * value, a value is empty, a value fills no slot, or any `{{` is left in the result. A value is inserted as is:
 * a value that itself holds `{{…}}` is refused too.
 */
export function fillTemplate(template: string, values: Record<string, string>): string {
  const slots = templateSlots(template);
  const missing = slots.filter((s) => !(s in values));
  const empty = slots.filter((s) => s in values && !values[s].trim());
  const unused = Object.keys(values).filter((k) => !slots.includes(k));
  const problems = [
    missing.length ? `no value for ${missing.map((s) => `{{${s}}}`).join(', ')}` : '',
    empty.length ? `empty value for ${empty.map((s) => `{{${s}}}`).join(', ')}` : '',
    unused.length ? `value given for no slot: ${unused.join(', ')}` : '',
  ].filter(Boolean);
  if (problems.length) throw new TemplateFillError(`template not filled: ${problems.join('; ')}`);

  const out = template
    .replace(ORCHESTRATOR_COMMENT_RE, '')
    .replace(SLOT_RE, (_m, name: string) => values[name]);
  const left = [...out.matchAll(/\{\{[^}]*\}\}?/g)].map((m) => m[0]);
  if (left.length) throw new TemplateFillError(`template not filled: ${left.join(', ')} left in the result`);
  return out;
}

/**
 * The question and its five rungs as the prompts show them. Refuses anything but exactly rungs 1–5, so a partial
 * ladder is never shown as the ladder.
 */
export function formatLadderText(questionText: string, rungs: Rung[]): string {
  const values = rungs.map((r) => r.value).sort((a, b) => a - b);
  if (values.join(',') !== '1,2,3,4,5') {
    throw new TemplateFillError(`expected rungs 1-5, got [${values.join(', ')}]`);
  }
  if (!questionText.trim()) throw new TemplateFillError('the question text is empty');
  const blank = rungs.filter((r) => !r.text.trim()).map((r) => r.value);
  if (blank.length) throw new TemplateFillError(`rung text is empty for rung ${blank.join(', ')}`);
  const lines = [...rungs].sort((a, b) => a.value - b.value).map((r) => `${r.value}. ${r.text.trim()}`);
  return `Question: ${questionText.trim()}\n\n${lines.join('\n')}`;
}
