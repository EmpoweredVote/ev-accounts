import { Dialog, DialogPanel } from '@headlessui/react';
import { Link } from 'react-router';
import { useState } from 'react';
import { apiFetch } from '../lib/api';

interface ConnectedExplainerModalProps {
  open: boolean;
  onClose: () => void;
  tier?: 'inform' | 'connect' | 'empower';
}

// ── Icons ─────────────────────────────────────────────────────────────────────

function EyeIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="white" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
      <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
      <circle cx="12" cy="12" r="3"/>
    </svg>
  );
}

function ChatIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 24 24" fill="white">
      <path d="M20 2H4C2.9 2 2 2.9 2 4v18l4-4h14c1.1 0 2-.9 2-2V4c0-1.1-.9-2-2-2z"/>
    </svg>
  );
}

function BullhornIcon() {
  return (
    <svg width="22" height="22" viewBox="0 0 20 20" fill="white">
      <path fillRule="evenodd" d="M18 3a1 1 0 00-1.447-.894L8.763 6H5a3 3 0 000 6h.28l1.771 5.316A1 1 0 008 18h1a1 1 0 001-1v-4.382l6.553 3.276A1 1 0 0018 15V3z" clipRule="evenodd"/>
    </svg>
  );
}

function CheckIcon() {
  return (
    <svg width="10" height="10" viewBox="0 0 12 12" fill="none">
      <path d="M2 6l3 3 5-5" stroke="#00657C" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round"/>
    </svg>
  );
}

// ── Tier card ─────────────────────────────────────────────────────────────────

interface TierCardProps {
  headerBg: string;
  circleBg: string;
  icon: React.ReactNode;
  name: string;
  subtitle: string;
  subtitleClass: string;
  identity: string;
  dotBg: string;
  login: string;
  interaction: string;
  whyExists: string;
}

function TierCard({ headerBg, circleBg, icon, name, subtitle, subtitleClass, identity, dotBg, login, interaction, whyExists }: TierCardProps) {
  return (
    <div className="rounded-xl overflow-hidden flex flex-col">
      {/* Header stays light-pastel in both modes — same as the original dark HTML */}
      <div className={`p-5 ${headerBg}`}>
        <div className={`w-11 h-11 rounded-full flex items-center justify-center mb-4 ${circleBg}`}>
          {icon}
        </div>
        <h3 className="text-xl font-bold text-gray-900 tracking-tight mb-0.5">{name}</h3>
        <p className={`text-xs font-semibold ${subtitleClass}`}>{subtitle}</p>
      </div>
      {/* Detail area — dark in dark mode, light in light mode */}
      <div className="bg-gray-50 dark:bg-[#1e1e1e] flex-1 p-4 space-y-3">
        <div>
          <span className="block text-[9px] font-bold tracking-widest uppercase text-gray-400 dark:text-[#4a4a4a] mb-1">IDENTITY</span>
          <span className="inline-flex items-center gap-1.5 bg-white dark:bg-[#2a2a2a] border border-gray-200 dark:border-gray-700 rounded-full px-2.5 py-0.5 text-xs text-gray-700 dark:text-gray-300 font-medium">
            <span className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${dotBg}`} />
            {identity}
          </span>
        </div>
        <div>
          <span className="block text-[9px] font-bold tracking-widest uppercase text-gray-400 dark:text-[#4a4a4a] mb-1">LOGIN</span>
          <p className="text-xs text-gray-700 dark:text-gray-300">{login}</p>
        </div>
        <div>
          <span className="block text-[9px] font-bold tracking-widest uppercase text-gray-400 dark:text-[#4a4a4a] mb-1">INTERACTION</span>
          <p className="text-xs text-gray-700 dark:text-gray-300">{interaction}</p>
        </div>
        <p className="text-[11px] text-gray-400 dark:text-gray-500 leading-relaxed">
          <span className="font-semibold text-gray-500 dark:text-gray-400">Why: </span>{whyExists}
        </p>
      </div>
    </div>
  );
}

// ── Modal ─────────────────────────────────────────────────────────────────────

export default function ConnectedExplainerModal({ open, onClose, tier = 'inform' }: ConnectedExplainerModalProps) {
  const [connectClicked, setConnectClicked] = useState(false);

  function handleConnectClick() {
    setConnectClicked(true);
    apiFetch('/events/track', {
      method: 'POST',
      body: JSON.stringify({ event: 'connect_account_cta_click' }),
    }).catch(() => {});
  }

  function handleClose() {
    setConnectClicked(false);
    onClose();
  }

  return (
    <Dialog open={open} onClose={handleClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/50" aria-hidden="true" />
      <div className="fixed inset-0 overflow-y-auto">
        <div className="flex min-h-full items-center justify-center p-4">
          <DialogPanel className="w-full max-w-4xl bg-white dark:bg-[#111] rounded-2xl shadow-2xl">

            {/* Header */}
            <div className="px-8 pt-8 pb-5 text-center">
              <p className="text-[10px] font-bold tracking-widest uppercase text-ev-teal-light mb-2">
                EMPOWERED VOTE · PLATFORM OVERVIEW
              </p>
              <h2 className="text-3xl font-bold text-gray-900 dark:text-white tracking-tight mb-1.5">
                How participation works
              </h2>
              <p className="text-sm text-gray-500 dark:text-gray-400">
                Three levels of engagement — go as far as you choose
              </p>
            </div>

            {/* Progress bar */}
            <div className="px-8 mb-5">
              <div className="flex h-1.5 gap-1 mb-1.5">
                <div className="flex-1 rounded-full bg-ev-yellow" />
                <div className="flex-1 rounded-full bg-ev-teal-light" />
                <div className="flex-1 rounded-full" style={{ background: '#FF7A65' }} />
              </div>
              <div className="flex text-[8.5px] font-bold tracking-wider uppercase text-gray-400 dark:text-gray-500">
                <span className="flex-1 text-center">ANONYMOUS</span>
                <span className="flex-1 text-center">VERIFIED &amp; PRIVATE</span>
                <span className="flex-1 text-center">PUBLIC &amp; TRANSPARENT</span>
              </div>
            </div>

            {/* Tier cards */}
            <div className="px-6 pb-5 grid grid-cols-1 sm:grid-cols-3 gap-4">
              <TierCard
                headerBg="bg-[#F0E5A2]"
                circleBg="bg-ev-yellow"
                icon={<EyeIcon />}
                name="Inform"
                subtitle="For everyone"
                subtitleClass="text-[#9A6800]"
                identity="Anonymous"
                dotBg="bg-ev-yellow"
                login="No — open access"
                interaction="Browse &amp; read only"
                whyExists="Broad access to trustworthy civic information — no barriers, no account needed."
              />
              <TierCard
                headerBg="bg-[#B5E3EE]"
                circleBg="bg-ev-teal"
                icon={<ChatIcon />}
                name="Connect"
                subtitle="Optional participation"
                subtitleClass="text-ev-teal"
                identity="Verified · private"
                dotBg="bg-ev-teal-light"
                login="Yes — authenticated"
                interaction="Pseudonym · 1 person = 1 voice"
                whyExists="Healthier, accountable conversations — real people, protected identities."
              />
              <TierCard
                headerBg="bg-[#FFD0C8]"
                circleBg="bg-ev-red"
                icon={<BullhornIcon />}
                name="Empower"
                subtitle="Choose public visibility"
                subtitleClass="text-ev-red"
                identity="Public · real name"
                dotBg="bg-ev-red"
                login="Yes — authenticated"
                interaction="Public stances · discoverable"
                whyExists="Public accountability — help people find leaders whose values align with theirs."
              />
            </div>

            {/* Bottom tagline */}
            <div className="px-8 pt-4 pb-5 flex items-center border-t border-gray-100 dark:border-gray-800">
              <div className="flex-1 flex flex-col items-center gap-0.5">
                <span className="text-[9px] font-bold tracking-widest uppercase text-ev-yellow">INFORM</span>
                <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Explore freely</span>
              </div>
              <span className="text-gray-300 dark:text-gray-600 px-1 text-lg leading-none">→</span>
              <div className="flex-1 flex flex-col items-center gap-0.5">
                <span className="text-[9px] font-bold tracking-widest uppercase text-ev-teal-light">CONNECT</span>
                <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Join the conversation</span>
              </div>
              <span className="text-gray-300 dark:text-gray-600 px-1 text-lg leading-none">→</span>
              <div className="flex-1 flex flex-col items-center gap-0.5">
                <span className="text-[9px] font-bold tracking-widest uppercase" style={{ color: '#FF7A65' }}>EMPOWER</span>
                <span className="text-sm font-medium text-gray-700 dark:text-gray-300">Lead publicly</span>
              </div>
            </div>

            {/* CTA area */}
            <div className="px-8 py-6 border-t border-gray-100 dark:border-gray-800 space-y-3">
              {tier === 'inform' && !connectClicked ? (
                <button
                  type="button"
                  onClick={handleConnectClick}
                  className="w-full py-3 bg-ev-teal hover:bg-ev-teal/90 text-white font-semibold rounded-xl text-sm transition-colors"
                >
                  Connect Account
                </button>
              ) : tier === 'inform' && connectClicked ? (
                <div className="space-y-4">
                  <p className="text-sm font-semibold text-gray-900 dark:text-white">To connect your account:</p>
                  <ul className="space-y-3">
                    <li className="flex items-start gap-2.5 text-sm text-gray-700 dark:text-gray-300">
                      <span className="w-5 h-5 rounded-full bg-ev-teal/10 dark:bg-ev-teal/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                        <CheckIcon />
                      </span>
                      <span>
                        <span className="font-semibold text-gray-900 dark:text-white">Verified identity, kept private.</span>{' '}
                        Your identity is confirmed but your participation remains pseudonymous.
                      </span>
                    </li>
                    <li className="flex items-start gap-2.5 text-sm text-gray-700 dark:text-gray-300">
                      <span className="w-5 h-5 rounded-full bg-ev-teal/10 dark:bg-ev-teal/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                        <CheckIcon />
                      </span>
                      <span>
                        <span className="font-semibold text-gray-900 dark:text-white">Each person gets one voice.</span>{' '}
                        Verified accounts ensure every voice counts equally — no duplicates, no bots.
                      </span>
                    </li>
                    <li className="flex items-start gap-2.5 text-sm text-gray-700 dark:text-gray-300">
                      <span className="w-5 h-5 rounded-full bg-ev-teal/10 dark:bg-ev-teal/20 flex items-center justify-center flex-shrink-0 mt-0.5">
                        <CheckIcon />
                      </span>
                      <span>
                        <span className="font-semibold text-gray-900 dark:text-white">Invite code required during Alpha.</span>{' '}
                        Access is invite-only while we build responsibly.
                      </span>
                    </li>
                  </ul>
                  <Link
                    to="/signup"
                    onClick={handleClose}
                    className="block w-full text-center py-3 bg-ev-teal hover:bg-ev-teal/90 text-white font-semibold rounded-xl text-sm transition-colors"
                  >
                    I have an invite code →
                  </Link>
                </div>
              ) : null}
              <button
                type="button"
                onClick={handleClose}
                className="block w-full text-center py-2 text-sm text-gray-400 dark:text-gray-500 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
              >
                Close
              </button>
            </div>

          </DialogPanel>
        </div>
      </div>
    </Dialog>
  );
}
