import { Dialog, DialogPanel, DialogTitle } from '@headlessui/react';
import { Link } from 'react-router-dom';

interface ConnectedExplainerModalProps {
  open: boolean;
  onClose: () => void;
}

export default function ConnectedExplainerModal({ open, onClose }: ConnectedExplainerModalProps) {
  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/40" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4">
        <DialogPanel className="w-full max-w-md bg-white dark:bg-gray-900 rounded-2xl border border-ev-teal/30 shadow-xl p-6 space-y-4">
          <DialogTitle className="text-lg font-semibold text-gray-900 dark:text-white">
            Connected Accounts
          </DialogTitle>

          <p className="text-sm text-gray-600 dark:text-gray-300">
            Connected Accounts unlock the participatory side of Empowered Vote — contributing to
            Validation Quests, posting in Focused Communities, and voting with your values.
          </p>

          <ul className="space-y-3">
            <li className="text-sm text-gray-700 dark:text-gray-300">
              <span className="font-semibold text-gray-900 dark:text-white">
                Identity verified, privately.
              </span>{' '}
              One real person, one voice. Your identity is verified but your participation is
              pseudonymous.
            </li>
            <li className="text-sm text-gray-700 dark:text-gray-300">
              <span className="font-semibold text-gray-900 dark:text-white">
                Alpha access via invite code.
              </span>{' '}
              During Alpha, Connected Accounts require an invite code from an existing member.
            </li>
          </ul>

          <Link
            to="/signup"
            onClick={onClose}
            className="block w-full text-center py-2.5 px-4 bg-ev-teal hover:bg-ev-teal/90 text-white font-semibold rounded-xl text-sm transition-colors"
          >
            I have an invite code →
          </Link>

          <button
            type="button"
            onClick={onClose}
            className="block w-full text-center py-2 text-sm text-gray-400 hover:text-gray-600 dark:hover:text-gray-200 transition-colors"
          >
            Close
          </button>
        </DialogPanel>
      </div>
    </Dialog>
  );
}
