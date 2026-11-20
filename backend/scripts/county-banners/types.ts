/**
 * Shared record types for the county banner sourcing pipeline.
 *
 * Spec: docs/superpowers/specs/2026-11-19-county-banner-sourcing-design.md
 *
 * These are declarations only. The pipeline's four stages -- sweep, locate, filter,
 * render -- each take and return these shapes, so a stage can be rerun from the JSON
 * the stage before it wrote without repeating that stage's network work.
 */

/** One Commons file that might become a county banner. */
export interface CandidateFile {
  title: string;
  url: string;
  width: number;
  height: number;
  /** As published on the file description page. `null` means NOT READ -- never "free". */
  licence: string | null;
  /** As published on the file description page. A file we cannot credit cannot ship. */
  author: string | null;
  date: string | null;
  /** The category this file was first reached through. Recall only -- NEVER evidence of location. */
  sourceCategory: string;
  lat: number | null;
  lon: number | null;
}

/**
 * One county's result.
 *
 * `swept` is the field that separates "this county has no photographs" from "this county
 * was never looked at". A crashed run that left `swept` false must never be read as
 * genuine absence -- that is how counties get written off without anyone checking.
 */
export interface CountyCandidates {
  geoid: string;
  name: string;
  swept: boolean;
  candidates: CandidateFile[];
  rejected: Record<string, number>;
}
