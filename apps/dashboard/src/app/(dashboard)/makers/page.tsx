"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import {
  ReactFlow,
  Background,
  Controls,
  type Node,
  type Edge,
  useNodesState,
  useEdgesState,
  type NodeProps,
  Handle,
  Position,
  ConnectionMode,
} from "@xyflow/react";
import "@xyflow/react/dist/style.css";
import {
  forceSimulation,
  forceLink,
  forceManyBody,
  forceCenter,
  forceCollide,
  forceX,
  forceY,
  type Simulation,
  type SimulationNodeDatum,
  type SimulationLinkDatum,
} from "d3-force";
import { useRouter } from "next/navigation";
import { Badge } from "@/components/ui/badge";
import { useConvexQuery } from "@/hooks/use-convex-query";

type GraphNode = {
  id: string;
  name: string;
  username: string;
  avatarUrl: string | null;
  headline: string | null;
  skills: string[];
  interests: string[];
  lookingFor: string | null;
  canHelpWith: string | null;
  createdAt: number;
};

type GraphEdge = {
  id: string;
  source: string;
  target: string;
  connectedAt: number;
};

type NetworkData = {
  nodes: GraphNode[];
  edges: GraphEdge[];
};

interface SimNode extends SimulationNodeDatum {
  id: string;
  fx?: number | null;
  fy?: number | null;
}

function getInitials(name: string) {
  return name
    .split(" ")
    .map((n) => n[0])
    .join("")
    .slice(0, 2)
    .toUpperCase();
}

function MakerNode({ data }: NodeProps) {
  const d = data as GraphNode & {
    connectionCount: number;
    dimmed: boolean;
    onHoverStart: (id: string) => void;
    onHoverEnd: () => void;
  };
  const [hovered, setHovered] = useState(false);

  const size = Math.max(40, Math.min(56, 36 + d.connectionCount * 2));
  const opacity = d.dimmed ? 0.15 : 1;

  return (
    <div
      className="relative cursor-pointer"
      style={{ zIndex: hovered ? 9999 : 1, opacity, transition: "opacity 200ms ease" }}
      onMouseEnter={() => {
        setHovered(true);
        d.onHoverStart(d.id);
      }}
      onMouseLeave={() => {
        setHovered(false);
        d.onHoverEnd();
      }}
    >
      <Handle
        type="target"
        position={Position.Left}
        className="!border-0 !bg-transparent !w-1 !h-1"
        style={{ left: size / 2, top: size / 2 }}
      />
      <Handle
        type="source"
        position={Position.Right}
        className="!border-0 !bg-transparent !w-1 !h-1"
        style={{ left: size / 2, top: size / 2 }}
      />

      <div
        className="rounded-full shadow-md transition-transform duration-150 ring-2 ring-background hover:ring-primary/50 hover:scale-110 hover:shadow-lg"
        style={{ width: size, height: size }}
      >
        {d.avatarUrl ? (
          <img
            src={d.avatarUrl}
            alt={d.name}
            className="rounded-full object-cover"
            style={{ width: size, height: size }}
          />
        ) : (
          <div
            className="flex items-center justify-center rounded-full bg-primary/10 font-semibold text-primary"
            style={{ width: size, height: size, fontSize: size * 0.3 }}
          >
            {getInitials(d.name)}
          </div>
        )}
      </div>

      <p
        className="absolute left-1/2 -translate-x-1/2 text-[10px] font-medium text-foreground whitespace-nowrap"
        style={{ top: size + 4 }}
      >
        {d.name.split(" ")[0]}
      </p>

      {hovered && (
        <div className="absolute z-[9999] left-1/2 -translate-x-1/2 bottom-full mb-3 pointer-events-none">
          <div className="bg-popover border border-border rounded-xl shadow-lg px-4 py-3 min-w-[200px] max-w-[260px] animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center gap-2.5 mb-2">
              {d.avatarUrl ? (
                <img
                  src={d.avatarUrl}
                  alt={d.name}
                  className="h-9 w-9 rounded-full object-cover"
                />
              ) : (
                <div className="flex h-9 w-9 items-center justify-center rounded-full bg-primary/10 text-xs font-semibold text-primary">
                  {getInitials(d.name)}
                </div>
              )}
              <div className="min-w-0">
                <p className="text-sm font-semibold text-foreground truncate">
                  {d.name}
                </p>
                <p className="text-xs text-muted-foreground">@{d.username}</p>
              </div>
            </div>
            {d.headline && (
              <p className="text-xs text-muted-foreground mb-2 line-clamp-2">
                {d.headline}
              </p>
            )}
            {d.skills.length > 0 && (
              <div className="flex flex-wrap gap-1 mb-2">
                {d.skills.slice(0, 4).map((skill) => (
                  <Badge
                    key={skill}
                    variant="secondary"
                    className="text-[10px] px-1.5 py-0"
                  >
                    {skill}
                  </Badge>
                ))}
                {d.skills.length > 4 && (
                  <span className="text-[10px] text-muted-foreground">
                    +{d.skills.length - 4}
                  </span>
                )}
              </div>
            )}
            <div className="flex items-center gap-3 text-[10px] text-muted-foreground border-t border-border pt-2 mt-1">
              <span>
                <strong className="text-foreground">{d.connectionCount}</strong>{" "}
                connection{d.connectionCount !== 1 ? "s" : ""}
              </span>
              <span className="text-muted-foreground/50">click to view</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const nodeTypes = { maker: MakerNode };

export default function MakersPage() {
  const router = useRouter();
  const { data, loading } =
    useConvexQuery<NetworkData>("dashboard:networkGraph");

  const [nodes, setNodes, onNodesChange] = useNodesState<Node>([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState<Edge>([]);

  const simulationRef = useRef<Simulation<SimNode, SimulationLinkDatum<SimNode>> | null>(null);
  const simNodesRef = useRef<SimNode[]>([]);
  const animFrameRef = useRef<number>(0);
  const draggingRef = useRef<string | null>(null);
  const [hoveredNodeId, setHoveredNodeId] = useState<string | null>(null);

  // Build adjacency map for hover highlighting
  const adjacency = useMemo(() => {
    const map = new Map<string, Set<string>>();
    if (!data) return map;
    for (const e of data.edges) {
      if (!map.has(e.source)) map.set(e.source, new Set());
      if (!map.has(e.target)) map.set(e.target, new Set());
      map.get(e.source)!.add(e.target);
      map.get(e.target)!.add(e.source);
    }
    return map;
  }, [data]);

  // Stable hover callbacks
  const onNodeHoverStart = useCallback((id: string) => setHoveredNodeId(id), []);
  const onNodeHoverEnd = useCallback(() => setHoveredNodeId(null), []);

  // Update node dimming and edge styles when hover changes
  useEffect(() => {
    if (!data) return;

    setNodes((prev) =>
      prev.map((node) => {
        const isDimmed =
          hoveredNodeId !== null &&
          node.id !== hoveredNodeId &&
          !adjacency.get(hoveredNodeId)?.has(node.id);
        return {
          ...node,
          data: {
            ...node.data,
            dimmed: isDimmed,
            onHoverStart: onNodeHoverStart,
            onHoverEnd: onNodeHoverEnd,
          },
        };
      })
    );

    setEdges((prev) =>
      prev.map((edge) => {
        const isActive =
          hoveredNodeId === null ||
          edge.source === hoveredNodeId ||
          edge.target === hoveredNodeId;
        return {
          ...edge,
          style: {
            stroke: isActive && hoveredNodeId ? "#666" : "#d4d4d4",
            strokeWidth: isActive && hoveredNodeId ? 1.5 : 1,
            opacity: isActive ? 1 : 0.08,
            transition: "opacity 200ms ease, stroke 200ms ease",
          },
        };
      })
    );
  }, [hoveredNodeId, adjacency, data, setNodes, setEdges, onNodeHoverStart, onNodeHoverEnd]);

  // Connection counts for sizing
  const connectionCounts = useMemo(() => {
    const counts = new Map<string, number>();
    if (!data) return counts;
    for (const e of data.edges) {
      counts.set(e.source, (counts.get(e.source) ?? 0) + 1);
      counts.set(e.target, (counts.get(e.target) ?? 0) + 1);
    }
    return counts;
  }, [data]);

  // Initialize simulation when data arrives
  useEffect(() => {
    if (!data || data.nodes.length === 0) return;

    // Create sim nodes
    const r0 = Math.max(300, data.nodes.length * 10);
    const simNodes: SimNode[] = data.nodes.map((n, i) => {
      const angle = (2 * Math.PI * i) / data.nodes.length;
      return {
        id: n.id,
        x: 600 + r0 * Math.cos(angle),
        y: 400 + r0 * Math.sin(angle),
      };
    });
    simNodesRef.current = simNodes;

    // Create sim links
    const simLinks: SimulationLinkDatum<SimNode>[] = data.edges.map((e) => ({
      source: e.source,
      target: e.target,
    }));

    // Build edges for React Flow (once)
    setEdges(
      data.edges.map((e) => ({
        id: e.id,
        source: e.source,
        target: e.target,
        type: "straight",
        style: { stroke: "#d4d4d4", strokeWidth: 1 },
      }))
    );

    // Set initial React Flow nodes with data (once — data doesn't change per tick)
    setNodes(
      data.nodes.map((n, i) => {
        const angle = (2 * Math.PI * i) / data.nodes.length;
        return {
          id: n.id,
          type: "maker" as const,
          position: { x: 600 + r0 * Math.cos(angle), y: 400 + r0 * Math.sin(angle) },
          data: { ...n, connectionCount: connectionCounts.get(n.id) ?? 0, dimmed: false, onHoverStart: onNodeHoverStart, onHoverEnd: onNodeHoverEnd },
        };
      })
    );

    // Create simulation
    const nodeCount = simNodes.length;
    const spread = Math.max(800, nodeCount * 24);
    const cx = 600, cy = 400;

    const sim = forceSimulation<SimNode>(simNodes)
      .force(
        "link",
        forceLink<SimNode, SimulationLinkDatum<SimNode>>(simLinks)
          .id((d) => d.id)
          .distance(120)
          .strength(0.4)
      )
      .force("charge", forceManyBody().strength(-500).distanceMax(spread))
      .force("center", forceCenter(cx, cy).strength(0.04))
      .force("x", forceX(cx).strength(0.02))
      .force("y", forceY(cy).strength(0.02))
      .force(
        "collide",
        forceCollide<SimNode>()
          .radius(() => 50)
          .strength(0.9)
      )
      .alphaDecay(0.025)
      .velocityDecay(0.35)
      .on("tick", () => {
        // Only update positions — preserve existing node data references
        // Skip the dragged node so React Flow fully owns it during drag
        setNodes((prev) =>
          prev.map((node) => {
            if (node.id === draggingRef.current) return node;
            const simNode = simNodesRef.current.find((n) => n.id === node.id);
            if (!simNode) return node;
            return {
              ...node,
              position: { x: simNode.x ?? 0, y: simNode.y ?? 0 },
            };
          })
        );
      });

    simulationRef.current = sim;

    return () => {
      sim.stop();
      cancelAnimationFrame(animFrameRef.current);
    };
  }, [data, connectionCounts, setNodes, setEdges, onNodeHoverStart, onNodeHoverEnd]);

  // When user starts dragging — pin that node
  const onNodeDragStart = useCallback(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (_: any, node: any) => {
      draggingRef.current = node.id;
      const sim = simulationRef.current;
      if (!sim) return;

      // Reheat simulation
      sim.alphaTarget(0.3).restart();

      // Pin the dragged node
      const simNode = simNodesRef.current.find((n) => n.id === node.id);
      if (simNode) {
        simNode.fx = node.position.x;
        simNode.fy = node.position.y;
      }
    },
    []
  );

  // While dragging — update pinned position
  const onNodeDrag = useCallback(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (_: any, node: any) => {
      const simNode = simNodesRef.current.find((n: SimNode) => n.id === node.id);
      if (simNode) {
        simNode.fx = node.position.x;
        simNode.fy = node.position.y;
      }
    },
    []
  );

  // When drag ends — unpin and cool down
  const onNodeDragStop = useCallback(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (_: any, node: any) => {
      draggingRef.current = null;
      const sim = simulationRef.current;
      if (!sim) return;

      sim.alphaTarget(0);

      const simNode = simNodesRef.current.find((n) => n.id === node.id);
      if (simNode) {
        simNode.fx = null;
        simNode.fy = null;
      }
    },
    []
  );

  const onNodeClick = useCallback(
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    (_: any, node: any) => {
      router.push(`/makers/${node.id}`);
    },
    [router]
  );

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <p className="text-sm text-muted-foreground">Loading network...</p>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 lg:left-60">
      <div className="h-full w-full bg-card overflow-hidden relative">
        {/* Floating header */}
        <div className="absolute top-4 left-4 z-10">
          <h2 className="text-lg font-bold tracking-tight">Maker Network</h2>
          <p className="text-xs text-muted-foreground">
            {data?.nodes.length ?? 0} makers, {data?.edges.length ?? 0}{" "}
            connections — drag to explore, click to view
          </p>
        </div>
        <ReactFlow
          nodes={nodes}
          edges={edges}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          onNodeClick={onNodeClick}
          onNodeDragStart={onNodeDragStart}
          onNodeDrag={onNodeDrag}
          onNodeDragStop={onNodeDragStop}
          nodeTypes={nodeTypes}
          connectionMode={ConnectionMode.Loose}
          fitView
          fitViewOptions={{ padding: 0.3 }}
          minZoom={0.2}
          maxZoom={2.5}
          proOptions={{ hideAttribution: true }}
          defaultEdgeOptions={{
            type: "straight",
            style: { stroke: "#d4d4d4", strokeWidth: 1 },
          }}
        >
          <Background gap={24} size={1} color="hsl(var(--border))" />
          <Controls
            showInteractive={false}
            className="!bg-card !border-border !shadow-sm [&>button]:!bg-card [&>button]:!border-border [&>button]:!text-foreground [&>button:hover]:!bg-accent"
          />
        </ReactFlow>
      </div>
    </div>
  );
}
