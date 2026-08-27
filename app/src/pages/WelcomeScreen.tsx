import { Link, useSearchParams } from 'react-router';
import { AuthPageLayout } from '../components/AuthPageLayout';
import { AuthCard } from '../components/AuthCard';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';

export default function WelcomeScreen() {
  const [searchParams] = useSearchParams();
  const redirect = searchParams.get('redirect');
  const redirectSuffix = redirect ? `?redirect=${encodeURIComponent(redirect)}` : '';

  return (
    <AuthPageLayout>
      <AuthCard>
        <div className="space-y-1 text-center">
          <h1 className="text-2xl font-bold text-white">Join to participate</h1>
          <p className="text-sm text-gray-400 leading-relaxed">
            Empowered Vote is a civic platform built on trust. You are welcome to
            explore freely — but to join the conversation you must authenticate your account.
          </p>
        </div>

        <div className="space-y-3">
          <Link to={`/signup${redirectSuffix}`} className="block">
            <PrimaryButton>Create account</PrimaryButton>
          </Link>
          <Link to={`/login${redirectSuffix}`} className="block">
            <SecondaryButton>Log in</SecondaryButton>
          </Link>
        </div>

        <div className="text-center pt-1">
          <Link
            to="/"
            className="text-sm text-ev-teal-light font-medium hover:underline"
          >
            Continue exploring
          </Link>
        </div>
      </AuthCard>
    </AuthPageLayout>
  );
}
