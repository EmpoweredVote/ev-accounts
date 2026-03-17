interface Props {
  onContinue: () => void;
}

export function WelcomeStep({ onContinue }: Props) {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen px-6 text-center">
      <div className="max-w-md w-full space-y-10">

        {/* Badge */}
        <div className="flex justify-center">
          <div className="w-20 h-20 rounded-full bg-ev-teal flex items-center justify-center">
            <svg className="w-10 h-10 text-white" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
            </svg>
          </div>
        </div>

        {/* Headline */}
        <div className="space-y-4">
          <h1 className="text-4xl font-bold text-ev-teal tracking-tight">
            You're Connected.
          </h1>
          <p className="text-lg text-gray-600 dark:text-gray-300 leading-relaxed">
            You've done something most people don't.
          </p>
        </div>

        {/* Trust moments */}
        <div className="space-y-3 text-left">
          <div className="flex items-start gap-3">
            <div className="w-5 h-5 rounded-full bg-ev-teal/15 flex items-center justify-center mt-0.5 shrink-0">
              <svg className="w-3 h-3 text-ev-teal" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
              </svg>
            </div>
            <p className="text-gray-700 dark:text-gray-200">
              You put your real name behind your civic voice.
            </p>
          </div>
          <div className="flex items-start gap-3">
            <div className="w-5 h-5 rounded-full bg-ev-teal/15 flex items-center justify-center mt-0.5 shrink-0">
              <svg className="w-3 h-3 text-ev-teal" fill="none" stroke="currentColor" strokeWidth={2.5} viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
              </svg>
            </div>
            <p className="text-gray-700 dark:text-gray-200">
              Someone trusted you enough to invite you here.
            </p>
          </div>
        </div>

        {/* Bridge to next step */}
        <p className="text-gray-500 dark:text-gray-400 text-sm leading-relaxed">
          Now we want to connect you to the place that's yours —
          your representatives, your community, your civic spaces.
        </p>

        <button
          onClick={onContinue}
          className="w-full bg-ev-teal text-white rounded-xl py-3.5 font-semibold text-base hover:bg-ev-teal/90 transition-colors"
        >
          Let's find your community →
        </button>
      </div>
    </div>
  );
}
