import { useEffect, useState, useCallback } from 'react';
import { useAuthStore } from '../store/authStore';
import { workosEnabled, hasWorkosSession } from '../lib/workosAuth';

interface FCPost {
  postId: string;
  threadId: string;
  threadTitle: string;
  communityId: string;
  communityName: string;
  communitySlug: string;
  postExcerpt: string;
  createdAt: string;       // ISO timestamp
  isEdited: boolean;
  authorPseudonym: string;
}

interface FCPostsResponse {
  data: FCPost[];
  meta: { cursor: string | null; hasMore: boolean };
}

type LoadState = 'idle' | 'loading' | 'loaded' | 'error-access' | 'error-generic';

export default function PostHistory() {
  const { user, accessToken } = useAuthStore();

  const [posts, setPosts] = useState<FCPost[]>([]);
  const [cursor, setCursor] = useState<string | null>(null);
  const [hasMore, setHasMore] = useState(false);
  const [state, setState] = useState<LoadState>('idle');
  const [loadingMore, setLoadingMore] = useState(false);

  const loadPage = useCallback(async (afterCursor: string | null) => {
    if (!user || !accessToken) return;

    let url = `https://fc.empowered.vote/api/users/${user.id}/posts`;
    if (afterCursor) {
      url += `?cursor=${encodeURIComponent(afterCursor)}`;
    }

    try {
      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${accessToken}` },
      });

      if (res.status === 401) {
        // fc cannot verify WorkOS-issued tokens until it gets the dual-issuer
        // port (decision 0002) — its 401 says nothing about OUR session then,
        // so never nuke the whole login over it.
        if (workosEnabled && hasWorkosSession()) {
          setState('error-generic');
          return;
        }
        useAuthStore.getState().clearAuth();
        return;
      }

      if (res.status === 403) {
        setState('error-access');
        return;
      }

      if (!res.ok) {
        setState('error-generic');
        return;
      }

      const json = await res.json() as FCPostsResponse;

      if (afterCursor === null) {
        setPosts(json.data);
      } else {
        setPosts((prev) => [...prev, ...json.data]);
      }

      setCursor(json.meta.cursor);
      setHasMore(json.meta.hasMore);
      setState('loaded');
    } catch {
      setState('error-generic');
    }
  }, [user, accessToken]);

  useEffect(() => {
    setState('loading');
    loadPage(null);
  }, [user?.id]); // eslint-disable-line react-hooks/exhaustive-deps

  const handleLoadMore = useCallback(async () => {
    setLoadingMore(true);
    await loadPage(cursor);
    setLoadingMore(false);
  }, [cursor, loadPage]);

  const handleRetry = useCallback(() => {
    setState('loading');
    loadPage(null);
  }, [loadPage]);

  if (state === 'loading' && posts.length === 0) {
    return (
      <div className="space-y-4">
        <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5 flex items-center justify-center">
          <p className="text-sm text-gray-400">Loading your posts&hellip;</p>
        </div>
      </div>
    );
  }

  if (state === 'error-access') {
    return (
      <div className="space-y-4">
        <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5">
          <p className="text-sm font-medium text-ev-red">Access denied</p>
          <p className="text-xs text-gray-500 mt-1">You don&apos;t have permission to view post history.</p>
        </div>
      </div>
    );
  }

  if (state === 'error-generic') {
    return (
      <div className="space-y-4">
        <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5">
          <p className="text-sm font-medium text-ev-black dark:text-white">Failed to load post history</p>
          <button
            onClick={handleRetry}
            className="mt-3 px-4 py-2 bg-ev-teal text-white rounded-xl text-sm font-semibold hover:bg-ev-teal/90 transition-colors"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  if (state === 'loaded' && posts.length === 0) {
    return (
      <div className="space-y-4">
        <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 p-5">
          <p className="text-sm text-gray-400">No posts yet</p>
          <p className="text-xs text-gray-500 mt-1">When you post in a community, it&apos;ll show up here.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {posts.length > 0 && (
        <div className="bg-white dark:bg-gray-950 rounded-2xl border border-gray-100 dark:border-gray-800 divide-y divide-gray-100 dark:divide-gray-800">
          {posts.map((post) => (
            <div key={post.postId} className="p-5 space-y-1.5">
              {/* Community breadcrumb */}
              <p className="text-xs font-semibold text-gray-400 uppercase tracking-wider">
                {post.communityName}
              </p>

              {/* Thread title link */}
              <a
                href={`https://fc.empowered.vote/communities/${post.communitySlug}/threads/${post.threadId}`}
                target="_blank"
                rel="noopener noreferrer"
                className="block text-sm font-semibold text-ev-teal hover:underline"
              >
                {post.threadTitle}
              </a>

              {/* Post excerpt */}
              <p className="text-sm text-ev-black dark:text-white leading-snug">{post.postExcerpt}</p>

              {/* Footer: author + timestamp + edited badge */}
              <div className="flex items-center gap-2 text-xs text-gray-500 pt-1">
                <span className="font-medium">{post.authorPseudonym}</span>
                <span className="text-gray-300 dark:text-gray-600">&bull;</span>
                <time dateTime={post.createdAt} className="tabular-nums">
                  {new Date(post.createdAt).toLocaleString(undefined, { dateStyle: 'medium', timeStyle: 'short' })}
                </time>
                {post.isEdited && (
                  <span className="ml-1 text-[11px] font-medium text-gray-400 italic">(edited)</span>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {hasMore && posts.length > 0 && (
        <button
          onClick={handleLoadMore}
          disabled={loadingMore}
          className="w-full py-2.5 px-4 bg-white dark:bg-gray-950 border border-gray-200 dark:border-gray-700 text-ev-teal rounded-xl text-sm font-semibold hover:border-ev-teal/50 transition-colors disabled:opacity-50"
        >
          {loadingMore ? 'Loading\u2026' : 'Load more'}
        </button>
      )}
    </div>
  );
}
