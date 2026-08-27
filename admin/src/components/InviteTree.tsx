import { useCallback, useEffect } from 'react';
import {
  ReactFlow,
  Background,
  Controls,
  MiniMap,
  useNodesState,
  useEdgesState,
  type Node,
  type Edge,
} from '@xyflow/react';
import dagre from '@dagrejs/dagre';
import { useNavigate } from 'react-router';
import { apiFetch } from '../lib/api';

const TIER_COLORS: Record<string, string> = {
  inform: '#94a3b8',
  connected: '#3b82f6',
  empowered: '#22c55e',
};

const NODE_WIDTH = 200;
const NODE_HEIGHT = 60;

function getLayoutedElements(nodes: Node[], edges: Edge[]) {
  const g = new dagre.graphlib.Graph();
  g.setDefaultEdgeLabel(() => ({}));
  g.setGraph({ rankdir: 'TB', ranksep: 80, nodesep: 40 });

  nodes.forEach((node) => g.setNode(node.id, { width: NODE_WIDTH, height: NODE_HEIGHT }));
  edges.forEach((edge) => g.setEdge(edge.source, edge.target));
  dagre.layout(g);

  return {
    nodes: nodes.map((node) => {
      const { x, y } = g.node(node.id);
      return { ...node, position: { x: x - NODE_WIDTH / 2, y: y - NODE_HEIGHT / 2 } };
    }),
    edges,
  };
}

interface RpcNode {
  id: string;
  data: { label: string; tier: string; account_standing: string | null };
}
interface RpcEdge { id: string; source: string; target: string }
interface TreeData {
  nodes: RpcNode[];
  edges: RpcEdge[];
}

export function InviteTree({ rootUserId }: { rootUserId?: string }) {
  const navigate = useNavigate();
  const [nodes, setNodes, onNodesChange] = useNodesState<Node>([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState<Edge>([]);

  useEffect(() => {
    const path = rootUserId
      ? `/admin/invites/tree/${rootUserId}`
      : '/admin/invites/tree';
    apiFetch<TreeData>(path).then((data) => {
      const rfNodes: Node[] = data.nodes.map((n) => ({
        id: n.id,
        data: { label: `${n.data.label}\n${n.data.tier}` },
        position: { x: 0, y: 0 },
        style: {
          background: TIER_COLORS[n.data.tier] || '#94a3b8',
          color: '#fff',
          border:
            n.data.account_standing === 'suspended'
              ? '3px solid #ef4444'
              : '1px solid #e5e7eb',
          borderRadius: '8px',
          padding: '10px',
          width: NODE_WIDTH,
          fontSize: '12px',
          textAlign: 'center' as const,
          cursor: 'pointer',
        },
      }));

      const rfEdges: Edge[] = data.edges.map((e, i) => ({
        id: `e-${i}`,
        source: e.source,
        target: e.target,
        type: 'smoothstep',
        style: { stroke: '#94a3b8' },
      }));

      const layouted = getLayoutedElements(rfNodes, rfEdges);
      setNodes(layouted.nodes);
      setEdges(layouted.edges);
    }).catch(() => {
      // Silently fail — tree shows empty state when API is unavailable
    });
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [rootUserId]);

  const onNodeClick = useCallback(
    (_: React.MouseEvent, node: Node) => {
      navigate(`/admin/accounts/${node.id}`);
    },
    [navigate]
  );

  return (
    <div style={{ height: '600px', width: '100%' }}>
      <ReactFlow
        nodes={nodes}
        edges={edges}
        onNodesChange={onNodesChange}
        onEdgesChange={onEdgesChange}
        onNodeClick={onNodeClick}
        fitView
        proOptions={{ hideAttribution: true }}
      >
        <Background />
        <Controls />
        <MiniMap
          nodeColor={(node) => {
            const tier = String(node.data?.label ?? '').split('\n')[1] ?? '';
            return TIER_COLORS[tier] || '#94a3b8';
          }}
        />
      </ReactFlow>
    </div>
  );
}
