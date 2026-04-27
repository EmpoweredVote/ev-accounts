import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';

interface InformConstraintsModalProps {
  open: boolean;
  onClose: () => void;
  onContinue: () => void;
  onUseInviteCode: () => void;
}

export default function InformConstraintsModal({
  open,
  onClose,
  onContinue,
  onUseInviteCode,
}: InformConstraintsModalProps) {
  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="w-full max-w-md bg-white dark:bg-gray-900 rounded-2xl border border-ev-yellow/30 shadow-xl p-6">
          <DialogTitle className="text-lg font-semibold text-gray-900 dark:text-white mb-3">
            What is an Inform Account?
          </DialogTitle>

          <p className="text-sm text-gray-600 dark:text-gray-300 mb-4">
            Inform Accounts are for anyone who wants to understand their civic world — no invite required.
            Here's what you get:
          </p>

          <ul className="space-y-3 mb-6">
            <li className="flex items-start gap-2.5 text-sm text-gray-700 dark:text-gray-300">
              <span className="text-ev-yellow font-bold mt-0.5 shrink-0">✓</span>
              <span>
                <span className="font-medium text-gray-900 dark:text-white">Full Inform access</span>
                {' '}— Compass, Essentials, Read &amp; Rank, Civics Test
              </span>
            </li>
            <li className="flex items-start gap-2.5 text-sm text-gray-700 dark:text-gray-300">
              <span className="text-ev-yellow font-bold mt-0.5 shrink-0">✓</span>
              <span>
                <span className="font-medium text-gray-900 dark:text-white">Observe Connected and Empowered features</span>
                {' '}— read-only, no participation in Validation Quests or Focused Communities
              </span>
            </li>
            <li className="flex items-start gap-2.5 text-sm text-gray-700 dark:text-gray-300">
              <span className="text-ev-yellow font-bold mt-0.5 shrink-0">✓</span>
              <span>
                <span className="font-medium text-gray-900 dark:text-white">Earn yellow gems</span>
                {' '}for Inform activity (no red or teal gems)
              </span>
            </li>
          </ul>

          <button
            type="button"
            onClick={onContinue}
            className="bg-ev-yellow hover:bg-ev-yellow/90 text-ev-black font-semibold rounded-xl py-2.5 px-4 w-full text-sm transition-colors"
          >
            Got it — Create my Inform Account
          </button>

          <p className="text-center text-xs text-gray-500 dark:text-gray-500 mt-3">
            <button
              type="button"
              onClick={onUseInviteCode}
              className="text-ev-teal dark:text-ev-teal-light hover:underline"
            >
              Have an invite code? Create a Connected Account →
            </button>
          </p>
        </DialogPanel>
      </div>
    </Dialog>
  );
}
