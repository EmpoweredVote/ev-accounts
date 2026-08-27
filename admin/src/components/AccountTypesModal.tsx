import { Dialog, DialogPanel } from '@headlessui/react';
import { Link } from 'react-router';

interface AccountTypesModalProps {
  open: boolean;
  onClose: () => void;
}

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

const pillars = [
  {
    key: 'inform',
    label: 'Inform',
    tagline: 'For everyone',
    headerBg: '#F0E5A2',
    circleBg: '#FED12E',
    dotColor: '#FED12E',
    subtitleColor: '#9A6800',
    labelColor: '#FED12E',
    icon: <EyeIcon />,
    identity: 'Anonymous',
    loginRequired: 'No — open access',
    interaction: 'Browse & read only',
    whyItExists: 'Broad access to trustworthy civic information — no barriers, no account needed.',
    progressColor: '#FED12E',
    progressLabel: 'ANONYMOUS',
    footerTagline: 'Explore freely',
  },
  {
    key: 'connect',
    label: 'Connect',
    tagline: 'Optional participation',
    headerBg: '#B5E3EE',
    circleBg: '#00657C',
    dotColor: '#59B0C4',
    subtitleColor: '#00657C',
    labelColor: '#59B0C4',
    icon: <ChatIcon />,
    identity: 'Verified · private',
    loginRequired: 'Yes — authenticated account',
    interaction: 'Pseudonym · 1 person = 1 voice',
    whyItExists: 'Healthier, accountable conversations — real people, protected identities.',
    progressColor: '#59B0C4',
    progressLabel: 'VERIFIED & PRIVATE',
    footerTagline: 'Join the conversation',
  },
  {
    key: 'empower',
    label: 'Empower',
    tagline: 'Choose public visibility',
    headerBg: '#FFD0C8',
    circleBg: '#FF5740',
    dotColor: '#FF5740',
    subtitleColor: '#C03820',
    labelColor: '#FF7A65',
    icon: <BullhornIcon />,
    identity: 'Public · real name',
    loginRequired: 'Yes — authenticated account',
    interaction: 'Public stances · discoverable',
    whyItExists: 'Public accountability — help people find leaders whose values align with theirs.',
    progressColor: '#FF7A65',
    progressLabel: 'PUBLIC & TRANSPARENT',
    footerTagline: 'Lead publicly',
  },
];

export default function AccountTypesModal({ open, onClose }: AccountTypesModalProps) {
  return (
    <Dialog open={open} onClose={onClose} className="relative z-50">
      <div className="fixed inset-0 bg-black/60" aria-hidden="true" />
      <div className="fixed inset-0 flex items-center justify-center p-4 overflow-y-auto">
        <DialogPanel className="w-full max-w-3xl bg-[#141414] rounded-2xl shadow-2xl overflow-hidden my-auto">

          {/* Header */}
          <div className="px-7 pt-7 pb-5 text-center">
            <p className="text-[10px] font-semibold tracking-[0.16em] text-ev-teal-light uppercase mb-3">
              EMPOWERED VOTE · PLATFORM OVERVIEW
            </p>
            <h2 className="text-2xl font-bold text-white tracking-tight mb-1.5">
              How participation works
            </h2>
            <p className="text-sm text-gray-500">
              Three levels of engagement — go as far as you choose
            </p>
          </div>

          {/* Progress bar */}
          <div className="px-7 mb-2">
            <div className="flex gap-1 h-1.5">
              {pillars.map((p) => (
                <div key={p.key} className="flex-1 rounded-full" style={{ background: p.progressColor }} />
              ))}
            </div>
          </div>
          <div className="px-7 flex mb-5">
            {pillars.map((p) => (
              <p key={p.key} className="flex-1 text-center text-[9px] font-semibold tracking-widest uppercase text-gray-600">
                {p.progressLabel}
              </p>
            ))}
          </div>

          {/* Cards */}
          <div className="px-7 grid grid-cols-3 gap-3 mb-5">
            {pillars.map((p) => (
              <div key={p.key} className="rounded-xl overflow-hidden">
                {/* Card header */}
                <div className="p-4" style={{ background: p.headerBg }}>
                  <div
                    className="w-10 h-10 rounded-full flex items-center justify-center mb-3"
                    style={{ background: p.circleBg }}
                  >
                    {p.icon}
                  </div>
                  <h3 className="text-xl font-bold text-[#1c1c1c] leading-tight">{p.label}</h3>
                  <p className="text-xs font-medium mt-0.5" style={{ color: p.subtitleColor }}>{p.tagline}</p>
                </div>
                {/* Card details */}
                <div className="bg-[#1e1e1e] p-3.5 flex flex-col gap-3">
                  <div>
                    <span className="block text-[8.5px] font-bold tracking-wider uppercase text-[#4a4a4a] mb-1">IDENTITY</span>
                    <span className="inline-flex items-center gap-1.5 bg-[#2a2a2a] rounded-full px-2.5 py-1 text-xs text-gray-300 font-medium">
                      <span className="w-1.5 h-1.5 rounded-full flex-shrink-0" style={{ background: p.dotColor }} />
                      {p.identity}
                    </span>
                  </div>
                  <div>
                    <span className="block text-[8.5px] font-bold tracking-wider uppercase text-[#4a4a4a] mb-1">LOGIN REQUIRED</span>
                    <p className="text-xs text-gray-300 font-medium">{p.loginRequired}</p>
                  </div>
                  <div>
                    <span className="block text-[8.5px] font-bold tracking-wider uppercase text-[#4a4a4a] mb-1">INTERACTION</span>
                    <p className="text-xs text-gray-300 font-medium">{p.interaction}</p>
                  </div>
                  <p className="text-[11px] text-gray-600 leading-relaxed">
                    <span className="text-gray-500 font-semibold">Why it exists: </span>
                    {p.whyItExists}
                  </p>
                </div>
              </div>
            ))}
          </div>

          {/* Footer taglines */}
          <div className="px-7 flex items-center mb-6">
            {pillars.map((p, i) => (
              <>
                <div key={p.key} className="flex-1 flex flex-col items-center gap-1">
                  <span className="text-[9px] font-bold tracking-[0.15em] uppercase" style={{ color: p.labelColor }}>
                    {p.label.toUpperCase()}
                  </span>
                  <span className="text-sm font-medium text-white">{p.footerTagline}</span>
                </div>
                {i < pillars.length - 1 && (
                  <span key={`arrow-${i}`} className="text-gray-600 text-base flex-shrink-0 px-1 mb-0.5">→</span>
                )}
              </>
            ))}
          </div>

          {/* Actions */}
          <div className="px-7 pb-7 flex flex-col gap-3">
            <button
              type="button"
              onClick={onClose}
              className="w-full py-2.5 px-4 bg-gray-800 hover:bg-gray-700 text-white font-semibold rounded-xl text-sm transition-colors"
            >
              Got it
            </button>
            <p className="text-center text-xs text-gray-500">
              Have an invite code?{' '}
              <Link to="/signup" onClick={onClose} className="text-ev-teal dark:text-ev-teal-light hover:underline font-medium">
                Create a Connected Account →
              </Link>
            </p>
          </div>

        </DialogPanel>
      </div>
    </Dialog>
  );
}
