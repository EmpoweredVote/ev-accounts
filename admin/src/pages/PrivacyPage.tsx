import { Link } from 'react-router';

export default function PrivacyPage() {
  return (
    <div className="min-h-screen flex flex-col items-center bg-gray-50 dark:bg-ev-black px-4 py-12">

      {/* Wordmark */}
      <div className="mb-8 text-center space-y-1">
        <Link to="/login">
          <h1 className="text-3xl font-bold text-ev-teal dark:text-ev-teal-light tracking-tight">
            empowered.vote
          </h1>
        </Link>
      </div>

      <div className="bg-white dark:bg-gray-900 rounded-2xl border border-gray-200 dark:border-gray-800 shadow-sm p-8 w-full max-w-2xl space-y-8">

        {/* Title */}
        <div>
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">Privacy Policy</h2>
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">Effective date: March 24, 2026</p>
          <p className="mt-3 text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            Empowered Vote operates civic engagement tools including Empowered Accounts
            (login.empowered.vote), CompassV2, Essentials, Validation Quests, and related
            applications. This policy explains what data we collect, how we use it, and your rights
            as a user.
          </p>
        </div>

        {/* 1. Information We Collect */}
        <div className="space-y-2">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">1. Information We Collect</h2>
          <ul className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed list-disc list-inside space-y-1">
            <li>
              <span className="font-medium">Account information</span> — email address and legal name
              provided at registration. Legal name is used for identity accountability within the
              platform and is never displayed publicly.
            </li>
            <li>
              <span className="font-medium">Usage data</span> — pages visited, features used, and
              session activity to maintain and improve the platform.
            </li>
            <li>
              <span className="font-medium">Compass responses</span> — your stance selections on civic
              topics, stored to power comparison and recommendation features. Visibility is controlled
              by your account settings.
            </li>
          </ul>
        </div>

        {/* 2. How We Use Your Information */}
        <div className="space-y-2">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">2. How We Use Your Information</h2>
          <ul className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed list-disc list-inside space-y-1">
            <li>
              <span className="font-medium">Account management</span> — authenticating your identity,
              maintaining your session, and providing access to platform features appropriate to your
              account tier.
            </li>
            <li>
              <span className="font-medium">Civic engagement features</span> — personalizing your
              Compass experience, connecting you with relevant civic information, and powering
              community tools.
            </li>
            <li>
              <span className="font-medium">Platform security</span> — detecting abuse, enforcing
              community standards, and protecting the integrity of civic data.
            </li>
          </ul>
        </div>

        {/* 3. Data Sharing */}
        <div className="space-y-2">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">3. Data Sharing</h2>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            We do not sell your personal data. We share limited data only with infrastructure
            providers necessary to operate the platform:
          </p>
          <ul className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed list-disc list-inside space-y-1">
            <li>
              <span className="font-medium">Supabase</span> — database and authentication
              infrastructure hosted on AWS. Data is stored in the United States.
            </li>
          </ul>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            We do not share data with advertising networks, data brokers, or third-party analytics
            services.
          </p>
        </div>

        {/* 4. Cookies and Local Storage */}
        <div className="space-y-3">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">4. Cookies and Local Storage</h2>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            Empowered Vote uses one first-party cookie to maintain your authenticated session across
            applications. This cookie is strictly necessary for the platform to function — without it,
            you cannot remain signed in. Under the ePrivacy Directive and GDPR, strictly necessary
            cookies do not require prior consent.
          </p>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            Because this cookie is strictly necessary for authentication,{' '}
            <strong>no opt-in consent banner is required under the ePrivacy Directive.</strong>
          </p>

          {/* Cookie disclosure table */}
          <div className="overflow-x-auto rounded-xl border border-gray-200 dark:border-gray-700 mt-2">
            <table className="w-full text-sm text-left">
              <thead>
                <tr className="bg-gray-100 dark:bg-gray-800">
                  <th className="px-3 py-2 font-medium text-gray-900 dark:text-white">Name</th>
                  <th className="px-3 py-2 font-medium text-gray-900 dark:text-white">Purpose</th>
                  <th className="px-3 py-2 font-medium text-gray-900 dark:text-white">Domain</th>
                  <th className="px-3 py-2 font-medium text-gray-900 dark:text-white">Duration</th>
                  <th className="px-3 py-2 font-medium text-gray-900 dark:text-white">Type</th>
                  <th className="px-3 py-2 font-medium text-gray-900 dark:text-white">Classification</th>
                </tr>
              </thead>
              <tbody>
                <tr className="border-b border-gray-200 dark:border-gray-700">
                  <td className="px-3 py-2 font-mono text-gray-800 dark:text-gray-200">ev_session</td>
                  <td className="px-3 py-2 text-gray-700 dark:text-gray-300">
                    Session continuity across Empowered Vote apps
                  </td>
                  <td className="px-3 py-2 text-gray-700 dark:text-gray-300 font-mono">.empowered.vote</td>
                  <td className="px-3 py-2 text-gray-700 dark:text-gray-300">
                    Session (until logout or browser close)
                  </td>
                  <td className="px-3 py-2 text-gray-700 dark:text-gray-300">
                    First-party, HttpOnly, Secure, SameSite=Lax
                  </td>
                  <td className="px-3 py-2 text-gray-700 dark:text-gray-300 font-medium">
                    Strictly necessary
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            We do not use tracking cookies, advertising cookies, or third-party analytics cookies.
            Some features may use browser <code className="text-xs bg-gray-100 dark:bg-gray-800 px-1 py-0.5 rounded">localStorage</code> to
            store non-personal preferences (such as UI state). This data never leaves your device.
          </p>
        </div>

        {/* 5. Your Rights */}
        <div className="space-y-2">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">5. Your Rights</h2>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            Depending on your jurisdiction, you may have the right to access, correct, or delete your
            personal data. You can:
          </p>
          <ul className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed list-disc list-inside space-y-1">
            <li>
              Update your profile information at any time via{' '}
              <Link to="/profile" className="text-ev-teal dark:text-ev-teal-light hover:underline">
                your profile page
              </Link>
              .
            </li>
            <li>
              Request a copy of your data, correction of inaccurate data, or deletion of your account
              by emailing{' '}
              <a
                href="mailto:privacy@empowered.vote"
                className="text-ev-teal dark:text-ev-teal-light hover:underline"
              >
                privacy@empowered.vote
              </a>
              .
            </li>
            <li>
              Lodge a complaint with your local data protection authority if you believe your rights
              have been violated.
            </li>
          </ul>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            We will respond to verifiable data requests within 30 days.
          </p>
        </div>

        {/* 6. Data Retention */}
        <div className="space-y-2">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">6. Data Retention</h2>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            Your account data is retained for as long as your account is active. If you request
            account deletion, we will remove your personal data within 30 days, except where
            retention is required by law or necessary to resolve disputes. Aggregated, anonymized
            data may be retained indefinitely.
          </p>
        </div>

        {/* 7. Security */}
        <div className="space-y-2">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">7. Security</h2>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            We implement technical and organizational measures to protect your data, including:
          </p>
          <ul className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed list-disc list-inside space-y-1">
            <li>Encryption in transit via HTTPS for all data exchanged with our servers.</li>
            <li>
              Database-level Row Level Security (RLS) enforced by Supabase PostgreSQL — your data
              can only be accessed by you and authorized platform functions.
            </li>
            <li>HttpOnly, Secure, SameSite=Lax cookies to prevent cross-site scripting attacks.</li>
          </ul>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            No method of transmission over the internet is 100% secure. We encourage you to use a
            strong, unique password for your account.
          </p>
        </div>

        {/* 8. Changes to This Policy */}
        <div className="space-y-2">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">8. Changes to This Policy</h2>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            We may update this Privacy Policy from time to time. The effective date at the top of
            this page reflects the date of the most recent revision. Continued use of the platform
            after changes are posted constitutes acceptance of the updated policy. For material
            changes, we will make reasonable efforts to notify users.
          </p>
        </div>

        {/* 9. Contact */}
        <div className="space-y-2">
          <h2 className="text-xl font-semibold text-gray-900 dark:text-white">9. Contact</h2>
          <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
            For privacy inquiries, data access requests, or questions about this policy, contact us
            at{' '}
            <a
              href="mailto:privacy@empowered.vote"
              className="text-ev-teal dark:text-ev-teal-light hover:underline"
            >
              privacy@empowered.vote
            </a>
            .
          </p>
        </div>

        {/* Footer nav */}
        <div className="pt-4 border-t border-gray-200 dark:border-gray-700">
          <Link
            to="/login"
            className="text-sm text-ev-teal dark:text-ev-teal-light hover:underline"
          >
            &larr; Back to sign in
          </Link>
        </div>

      </div>
    </div>
  );
}
