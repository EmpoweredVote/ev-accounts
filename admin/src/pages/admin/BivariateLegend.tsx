/**
 * 2D legend for the bivariate completeness map: a 3×3 Teal×Amber grid with
 * breadth on X (→) and depth on Y (↑), plus the separate "not started" grey.
 */
import { PALETTE, NOT_STARTED, type Bucket } from './coverageBivariate';

const ROWS: Bucket[] = ['high', 'med', 'low']; // top → bottom (deep → shallow)
const COLS: Bucket[] = ['low', 'med', 'high'];  // left → right (narrow → broad)

export function BivariateLegend() {
  return (
    <div className="flex items-end gap-4 text-[10px] text-gray-500 dark:text-gray-400">
      <div className="flex flex-col items-start">
        <div className="flex items-stretch gap-1">
          {/* Y axis caption */}
          <div className="flex flex-col justify-between py-0.5 pr-1 text-right leading-none text-gray-400">
            <span>deep</span>
            <span>shallow</span>
          </div>
          {/* 3×3 swatch grid */}
          <div className="grid grid-cols-3 grid-rows-3">
            {ROWS.map((r) =>
              COLS.map((c) => (
                <div key={`${r}-${c}`} style={{ background: PALETTE[r][c] }} className="h-4 w-4" title={`depth ${r} · breadth ${c}`} />
              )),
            )}
          </div>
        </div>
        {/* X axis caption */}
        <div className="mt-0.5 flex w-full justify-between pl-6 text-gray-400" style={{ maxWidth: 60 }}>
          <span>narrow</span>
          <span>broad</span>
        </div>
        <div className="mt-0.5 pl-6 text-gray-400">breadth →</div>
      </div>
      <span className="inline-flex items-center gap-1.5 pb-4">
        <span className="inline-block h-2.5 w-2.5 rounded-sm" style={{ background: NOT_STARTED }} />
        not started
      </span>
    </div>
  );
}
