import { AppNav } from '../components/AppNav';

const HERO_FEATURES = [
  {
    name: 'Empowered Essentials',
    description: 'Know your representatives and their positions.',
    baseUrl: 'https://essentials.empowered.vote',
    dot: 'bg-ev-yellow',
  },
  {
    name: 'Empowered Compass',
    description: 'Map your political values across key issues.',
    baseUrl: 'https://compass.empowered.vote',
    dot: 'bg-ev-yellow',
  },
  {
    name: 'Treasury Tracker',
    description: 'Track government spending and financial accountability.',
    baseUrl: 'https://treasurytracker.empowered.vote',
    dot: 'bg-ev-yellow',
  },
  {
    name: 'Fallacy Finders',
    description: 'Spot logical fallacies in political messaging.',
    baseUrl: '#',
    dot: 'bg-ev-yellow',
    comingSoon: true,
  },
  {
    name: 'Empowered Badges',
    description: 'Earn badges that recognize your civic learning.',
    baseUrl: '#',
    dot: 'bg-ev-yellow',
    comingSoon: true,
  },
];

const CIVIC_SPACES = [
  {
    name: 'Civic Spaces',
    description: 'Connect with your geographic community — your city, county, and districts.',
    color: 'bg-ev-teal',
  },
  {
    name: 'Common Ground',
    description: 'Find areas of agreement with people who hold different views.',
    color: 'bg-ev-teal-light',
  },
  {
    name: 'Symposium',
    description: 'Discuss policy in structured, good-faith conversations.',
    color: 'bg-ev-blue',
  },
];

export default function InformLandingPage() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-ev-black">
      <AppNav>
        <a
          href="https://login.empowered.vote/login"
          className="text-sm font-medium text-gray-500 hover:text-ev-teal dark:text-gray-400 dark:hover:text-ev-teal-light transition-colors"
        >
          Sign in
        </a>
        <a
          href="https://login.empowered.vote/signup"
          className="text-sm font-semibold bg-ev-teal text-white px-4 py-1.5 rounded-lg hover:bg-ev-teal/90 transition-colors"
        >
          Create account
        </a>
      </AppNav>

      <main className="max-w-2xl mx-auto px-4 py-10 space-y-12">

        {/* HERO SECTION (LAND-02) */}
        <section>
          <h1 className="text-3xl sm:text-4xl font-bold text-ev-black dark:text-white">
            Understand your world
          </h1>
          <p className="text-base text-gray-600 dark:text-gray-300 mt-3 leading-relaxed">
            Empowered Vote is a civic platform built on transparency. Explore facts about your government, your representatives, and the issues that shape your community — at your own pace.
          </p>
          <p className="text-sm text-ev-teal dark:text-ev-teal-light font-medium mt-4">
            No account required. Just curiosity.
          </p>

          <div className="grid grid-cols-2 gap-3 mt-8">
            {HERO_FEATURES.map((f) => {
              const isStub = f.baseUrl === '#';
              if (isStub) {
                return (
                  <div
                    key={f.name}
                    className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 space-y-2 opacity-75"
                  >
                    <div className={`w-2 h-2 rounded-full ${f.dot}`} />
                    <p className="text-sm font-semibold text-ev-black dark:text-white leading-snug">{f.name}</p>
                    <p className="text-xs text-gray-400 leading-snug">{f.description}</p>
                    <p className="text-xs text-gray-400 font-medium italic">Coming soon</p>
                  </div>
                );
              }
              return (
                <a
                  key={f.name}
                  href={f.baseUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-4 space-y-2 hover:border-ev-teal/40 transition-colors group"
                >
                  <div className={`w-2 h-2 rounded-full ${f.dot}`} />
                  <p className="text-sm font-semibold text-ev-black dark:text-white leading-snug">{f.name}</p>
                  <p className="text-xs text-gray-400 leading-snug">{f.description}</p>
                  <p className="text-xs text-ev-teal font-medium group-hover:underline">Explore →</p>
                </a>
              );
            })}
          </div>
        </section>

        {/* PARTICIPATE SECTION (LAND-03) — NO CTA BUTTON */}
        <section>
          <h2 className="text-2xl font-bold text-ev-black dark:text-white">
            Participate with your community
          </h2>
          <p className="text-base text-gray-600 dark:text-gray-300 mt-3">
            When you're ready to engage — not just learn — Empowered Vote includes spaces designed for productive civic conversation.
          </p>

          <div className="mt-6 space-y-3">
            {CIVIC_SPACES.map((s) => (
              <div
                key={s.name}
                className="flex items-start gap-4 bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-4"
              >
                <div className={`w-8 h-8 rounded-full ${s.color} flex-shrink-0 mt-0.5`} />
                <div className="space-y-1">
                  <p className="text-sm font-semibold text-ev-black dark:text-white">{s.name}</p>
                  <p className="text-xs text-gray-500 dark:text-gray-400 leading-relaxed">{s.description}</p>
                </div>
              </div>
            ))}
          </div>

          <p className="text-sm text-gray-600 dark:text-gray-300 mt-6 leading-relaxed">
            These spaces require a Connected account — a small commitment that helps keep conversations grounded in real people, not anonymous noise. It's not a paywall or a funnel. It's how we protect the signal.
          </p>
        </section>

        {/* JOIN THE CONVERSATION (LAND-04) */}
        <section>
          <h2 className="text-2xl font-bold text-ev-black dark:text-white">
            Join the conversation
          </h2>
          <p className="text-base text-gray-600 dark:text-gray-300 mt-3 leading-relaxed">
            Empowered accounts are for those seeking shared solutions — people who want to find common ground with their neighbors and move forward together. If that sounds like you, we'd love to have you.
          </p>
          <div className="mt-6 flex flex-col sm:flex-row gap-3">
            <a
              href="https://login.empowered.vote/signup"
              className="inline-flex items-center justify-center bg-ev-blue text-white rounded-xl px-6 py-3 font-bold text-base hover:bg-ev-blue/90 transition-colors"
            >
              Create account
            </a>
            <a
              href="https://login.empowered.vote/login"
              className="inline-flex items-center justify-center bg-white dark:bg-gray-950 text-ev-black dark:text-white border border-gray-200 dark:border-gray-700 rounded-xl px-6 py-3 font-bold text-base hover:border-ev-teal-light/50 transition-colors"
            >
              Sign in
            </a>
          </div>
        </section>

      </main>
    </div>
  );
}
