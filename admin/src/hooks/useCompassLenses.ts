import { useEffect, useMemo, useState } from 'react';
import { apiFetch } from '../lib/api';

/**
 * The system (curated) compass lenses — Local / Federal / Judicial today, and
 * whatever else is seeded next (a School lens is planned). Data-driven on
 * purpose: this reads the same GET /api/compass/lenses the Compass and
 * Essentials apps read, so a new lens shows up in admin the moment its rows
 * exist, with no code change here. `topicIds` are inform.compass_topics ids in
 * the lens's own sort_order — the same id the Topics list and the Season
 * composition payload key their topics by.
 */
export interface CompassLens {
  key: string;
  name: string;
  description: string | null;
  color: string | null;
  icon: string | null;
  autoDistrictTypes: string[];
  topicIds: string[];
}

export interface CompassLensesState {
  lenses: CompassLens[];
  /** topic id → the lenses that hold it (in the load order of `lenses`). */
  byTopicId: Map<string, CompassLens[]>;
  loading: boolean;
  error: string | null;
}

/** "Local Lens" → "Local". Falls back to the full name if it has no suffix. */
export function shortLensName(name: string): string {
  return name.replace(/\s*lens$/i, '').trim() || name;
}

export function useCompassLenses(): CompassLensesState {
  const [lenses, setLenses] = useState<CompassLens[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let alive = true;
    apiFetch<CompassLens[]>('/compass/lenses')
      .then((data) => { if (alive) setLenses(data); })
      .catch((err) => { if (alive) setError(err instanceof Error ? err.message : 'Failed to load lenses'); })
      .finally(() => { if (alive) setLoading(false); });
    return () => { alive = false; };
  }, []);

  const byTopicId = useMemo(() => {
    const map = new Map<string, CompassLens[]>();
    for (const lens of lenses) {
      for (const id of lens.topicIds) {
        const list = map.get(id);
        if (list) list.push(lens);
        else map.set(id, [lens]);
      }
    }
    return map;
  }, [lenses]);

  return { lenses, byTopicId, loading, error };
}
