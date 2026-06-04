/**
 * 2D legend for the bivariate completeness map: a 3×3 Teal×Amber grid with
 * breadth on X (→) and depth on Y (↑), plus the separate "not started" grey.
 * Rendered as an overlay inside the map area.
 */
import { PALETTE, NOT_STARTED, type Bucket } from './coverageBivariate';

const ROWS: Bucket[] = ['high', 'med', 'low']; // top → bottom (deep → shallow)
const COLS: Bucket[] = ['low', 'med', 'high'];  // left → right (narrow → broad)

const CELL = 26; // px per swatch
const GRID = CELL * 3;

export function BivariateLegend() {
  return (
    <div className="flex items-end gap-4 text-[11px] leading-none text-gray-500 dark:text-gray-400">
      <div>
        <div className="flex items-stretch gap-1.5">
          {/* Y axis caption */}
          <div className="flex w-12 flex-col justify-between py-1 text-right text-gray-400">
            <span>deep</span>
            <span>shallow</span>
          </div>
          <div>
            {/* 3×3 swatch grid */}
            <div
              className="grid overflow-hidden rounded"
              style={{ gridTemplateColumns: `repeat(3, ${CELL}px)`, gridTemplateRows: `repeat(3, ${CELL}px)`, width: GRID, height: GRID }}
            >
              {ROWS.map((r) =>
                COLS.map((c) => (
                  <div key={`${r}-${c}`} style={{ background: PALETTE[r][c] }} title={`depth ${r} · breadth ${c}`} />
                )),
              )}
            </div>
            {/* X axis caption */}
            <div className="mt-1 flex justify-between text-gray-400" style={{ width: GRID }}>
              <span>narrow</span>
              <span>broad</span>
            </div>
            <div className="mt-0.5 text-center text-gray-400" style={{ width: GRID }}>breadth →</div>
          </div>
        </div>
      </div>
      <span className="inline-flex items-center gap-1.5 pb-6">
        <span className="inline-block h-3.5 w-3.5 rounded-sm" style={{ background: NOT_STARTED }} />
        not started
      </span>
    </div>
  );
}
