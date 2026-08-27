import { useParams } from 'react-router';
import { InviteTree } from '../../components/InviteTree';

export function InviteTreePage() {
  const { userId } = useParams<{ userId?: string }>();
  return (
    <div>
      <div className="mb-4 flex items-center justify-between">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          {userId ? 'User Invite Subtree' : 'Full Invite Tree'}
        </h1>
        <div className="flex gap-4">
          <div className="flex items-center gap-2">
            <span className="inline-block w-4 h-4 rounded" style={{ background: '#94a3b8' }}></span>
            <span className="text-sm text-gray-600 dark:text-gray-400">Inform</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="inline-block w-4 h-4 rounded" style={{ background: '#3b82f6' }}></span>
            <span className="text-sm text-gray-600 dark:text-gray-400">Connected</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="inline-block w-4 h-4 rounded" style={{ background: '#22c55e' }}></span>
            <span className="text-sm text-gray-600 dark:text-gray-400">Empowered</span>
          </div>
          <div className="flex items-center gap-2">
            <span className="inline-block w-4 h-4 rounded border-2 border-red-500" style={{ background: '#fff' }}></span>
            <span className="text-sm text-gray-600 dark:text-gray-400">Suspended</span>
          </div>
        </div>
      </div>
      <div className="bg-white dark:bg-gray-900 rounded-lg shadow">
        <InviteTree rootUserId={userId} />
      </div>
    </div>
  );
}
