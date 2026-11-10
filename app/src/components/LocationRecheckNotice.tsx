import { Link } from 'react-router';

/**
 * Shown to a basic account whose county's district maps changed after it added its address
 * (`location_needs_confirmation` on GET /api/account/me — CA_0369). We keep no address for a
 * basic account, so the only way to refresh its districts is to ask for the address again.
 *
 * The districts stay on screen meanwhile: the maps changed, which does not mean this
 * person's districts did. The copy says exactly that much and no more.
 */
export const LOCATION_RECHECK_TEXT =
  'District maps in your area were updated after you added your address. ' +
  'Re-enter it to keep your representatives and elections correct.';

export default function LocationRecheckNotice({ showLink = true }: { showLink?: boolean }) {
  return (
    <div
      role="status"
      className="rounded-xl border border-amber-300/60 bg-amber-50 dark:bg-amber-950/30 dark:border-amber-700/50 p-3 space-y-2"
    >
      <p className="text-sm text-amber-900 dark:text-amber-200">{LOCATION_RECHECK_TEXT}</p>
      {showLink && (
        <Link
          to="/settings/location"
          className="inline-block text-sm font-semibold text-amber-900 dark:text-amber-200 underline hover:no-underline"
        >
          Re-enter your address →
        </Link>
      )}
    </div>
  );
}
