import type { LocationResult } from './LocationStep';

interface Props {
  result: LocationResult;
  onContinue: () => void;
}

const DISTRICT_LABELS: { key: keyof LocationResult['jurisdiction']; label: string }[] = [
  { key: 'congressional_district_name', label: 'U.S. Congress' },
  { key: 'state_senate_district_name', label: 'State Senate' },
  { key: 'state_house_district_name', label: 'State House' },
  { key: 'county_name', label: 'County' },
  { key: 'school_district_name', label: 'School District' },
];

export function LocationCelebrationStep({ result, onContinue }: Props) {
  const districts = DISTRICT_LABELS.filter((d) => result.jurisdiction[d.key]);

  return (
    <div className="flex flex-col items-center justify-center min-h-screen px-6 text-center">
      <div className="max-w-md w-full space-y-8">

        {/* Icon */}
        <div className="flex justify-center">
          <div className="w-20 h-20 rounded-full bg-ev-yellow/20 flex items-center justify-center">
            <svg className="w-10 h-10 text-ev-yellow" fill="currentColor" viewBox="0 0 24 24">
              <path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z" />
            </svg>
          </div>
        </div>

        {/* Headline */}
        <div className="space-y-3">
          <h2 className="text-3xl font-bold text-ev-black dark:text-white tracking-tight">
            You're grounded.
          </h2>
          {result.jurisdiction.congressional_district_name && (
            <p className="text-ev-teal font-medium text-lg leading-snug">
              {result.jurisdiction.congressional_district_name}
            </p>
          )}
        </div>

        {/* District list */}
        {districts.length > 0 && (
          <div className="bg-white dark:bg-gray-900 border border-gray-100 dark:border-gray-800 rounded-2xl divide-y divide-gray-100 dark:divide-gray-800 text-left">
            {districts.map(({ key, label }) => (
              <div key={key} className="flex items-center justify-between px-4 py-3">
                <span className="text-sm text-gray-500 dark:text-gray-400">{label}</span>
                <span className="text-sm font-medium text-ev-black dark:text-white text-right max-w-[60%]">
                  {result.jurisdiction[key]}
                </span>
              </div>
            ))}
          </div>
        )}

        <p className="text-sm text-gray-500 dark:text-gray-400 leading-relaxed">
          These are the people making decisions that affect your daily life.
          Now you'll know who they are.
        </p>

        <button
          onClick={onContinue}
          className="w-full bg-ev-teal text-white rounded-xl py-3.5 font-semibold text-base hover:bg-ev-teal/90 transition-colors"
        >
          One last thing →
        </button>
      </div>
    </div>
  );
}
