import { Link, useSearchParams } from 'react-router-dom';
import { AppNav } from '../components/AppNav';
import { AuthCard } from '../components/AuthCard';
import { PrimaryButton } from '../components/PrimaryButton';
import { SecondaryButton } from '../components/SecondaryButton';

export default function WelcomeScreen() {
  const [searchParams] = useSearchParams();
  const redirect = searchParams.get('redirect');
  const redirectSuffix = redirect ? `?redirect=${encodeURIComponent(redirect)}` : '';

  return (
    <div className="min-h-screen bg-ev-navy flex flex-col">
      <AppNav />
      <div className="flex-1 flex items-center justify-center px-4 py-12">
        <div className="w-full max-w-sm">
          <AuthCard>
            <div className="space-y-1 text-center">
              <h1 className="text-2xl font-bold text-white">Join to participate</h1>
              <p className="text-sm text-gray-400 leading-relaxed">
                Empowered Vote is a civic platform built on trust. You are welcome to
                explore freely — and if a topic moves you, you can join the conversation.
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
        </div>
      </div>
    </div>
  );
}
