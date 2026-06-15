"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useTheme } from "next-themes";
import {
  ReactFlow,
  Background,
  Controls,
  MiniMap,
  Panel,
  Handle,
  Position,
  useNodesState,
  useEdgesState,
  type Node as RFNode,
  type Edge as RFEdge,
  type NodeProps,
  type ReactFlowInstance,
} from "@xyflow/react";
import "@xyflow/react/dist/style.css";
import {
  forceSimulation,
  forceManyBody,
  forceLink,
  forceX,
  forceY,
  forceCollide,
  type Simulation,
} from "d3-force";
import { Button } from "@/components/ui/button";
import { useDash } from "@/hooks/use-dash";
import { disciplineColor } from "@/lib/disciplines";
import { initials } from "@/lib/format";

type GNode = { id: string; degree: number; group: string; name: string; avatar: string | null };
type Net = {
  nodes: GNode[];
  edges: { source: string; target: string; cross: boolean }[];
  totalMembers: number;
  totalConnections: number;
};

type StudentData = { name: string; avatar: string | null; color: string; size: number; showLabel: boolean };

// A simulation node (d3 mutates x/y/vx/vy and reads fx/fy).
type SimNode = GNode & { x: number; y: number; vx?: number; vy?: number; fx?: number | null; fy?: number | null };

const sizeFor = (degree: number) => 40 + Math.min(degree, 8) * 5;

// Both handles pinned to the node center so edges run center-to-center
// (the avatar sits on top, so a line visually meets each circle's edge).
const centerHandle: React.CSSProperties = {
  top: "50%",
  left: "50%",
  width: 1,
  height: 1,
  minWidth: 0,
  minHeight: 0,
  border: 0,
  transform: "translate(-50%, -50%)",
  opacity: 0,
  pointerEvents: "none",
};

function StudentNode({ data }: NodeProps) {
  const d = data as StudentData;
  return (
    <div style={{ width: d.size, height: d.size }} className="group relative">
      <Handle type="target" position={Position.Top} style={centerHandle} isConnectable={false} />
      <Handle type="source" position={Position.Bottom} style={centerHandle} isConnectable={false} />
      <div className="size-full overflow-hidden rounded-full bg-muted shadow-sm" style={{ border: `2.5px solid ${d.color}` }} title={d.name}>
        {d.avatar ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img src={d.avatar} alt={d.name} className="size-full object-cover" draggable={false} />
        ) : (
          <div className="flex size-full items-center justify-center text-[11px] font-medium text-muted-foreground">{initials(d.name)}</div>
        )}
      </div>
      {/* Name: always shown for connectors (3+), revealed on hover for everyone else. */}
      <div
        className={`pointer-events-none absolute left-1/2 top-full z-10 mt-1 -translate-x-1/2 whitespace-nowrap rounded-md bg-background/80 px-1.5 text-[11px] font-medium backdrop-blur-sm transition-opacity ${
          d.showLabel ? "opacity-100" : "opacity-0 group-hover:opacity-100"
        }`}
      >
        {d.name}
      </div>
    </div>
  );
}

const nodeTypes = { student: StudentNode };

const edgeStyle = (cross: boolean) => ({
  stroke: "var(--foreground)",
  strokeOpacity: cross ? 0.45 : 0.2,
  strokeWidth: cross ? 2 : 1.25,
});

export default function MapPage() {
  const { resolvedTheme } = useTheme();
  const data = useDash<Net>("center:network");
  const [crossOnly, setCrossOnly] = useState(false);
  const [nodes, setNodes, onNodesChange] = useNodesState<RFNode>([]);
  const [edges, setEdges, onEdgesChange] = useEdgesState<RFEdge>([]);

  const allEdges = useRef<RFEdge[]>([]);
  const simRef = useRef<Simulation<SimNode, undefined> | null>(null);
  const simById = useRef<Map<string, SimNode>>(new Map());
  const dragId = useRef<string | null>(null);
  const rf = useRef<ReactFlowInstance | null>(null);

  // Build + run a LIVE d3-force simulation; positions stream into React Flow each tick.
  useEffect(() => {
    if (!data || data.nodes.length === 0) return;
    const n = data.nodes.length;
    const simNodes: SimNode[] = data.nodes.map((nd, i) => ({
      ...nd,
      x: Math.cos((i / n) * 2 * Math.PI) * 250,
      y: Math.sin((i / n) * 2 * Math.PI) * 180,
    }));
    simById.current = new Map(simNodes.map((s) => [s.id, s]));
    const links = data.edges.map((e) => ({ source: e.source, target: e.target }));

    setNodes(
      simNodes.map((s) => {
        const size = sizeFor(s.degree);
        return {
          id: s.id,
          type: "student",
          position: { x: s.x - size / 2, y: s.y - size / 2 },
          data: { name: s.name, avatar: s.avatar, color: disciplineColor(s.group), size, showLabel: s.degree >= 3 } satisfies StudentData,
        };
      })
    );
    const rfEdges: RFEdge[] = data.edges.map((e, i) => ({
      id: `e${i}`,
      source: e.source,
      target: e.target,
      type: "straight",
      style: edgeStyle(e.cross),
      data: { cross: e.cross },
    }));
    allEdges.current = rfEdges;
    setEdges(rfEdges);

    const sim = forceSimulation<SimNode>(simNodes)
      .force("charge", forceManyBody().strength(-360))
      .force("link", forceLink<SimNode, { source: string; target: string }>(links).id((d) => d.id).distance(92).strength(0.5))
      .force("x", forceX(0).strength(0.07))
      .force("y", forceY(0).strength(0.09))
      .force("collide", forceCollide(36))
      .alphaDecay(0.018)
      .on("tick", () => {
        setNodes((prev) =>
          prev.map((node) => {
            if (node.id === dragId.current) return node; // RF owns the dragged node
            const s = simById.current.get(node.id);
            if (!s) return node;
            const size = (node.data as StudentData).size;
            return { ...node, position: { x: s.x - size / 2, y: s.y - size / 2 } };
          })
        );
      });
    simRef.current = sim;

    const t = setTimeout(() => rf.current?.fitView({ padding: 0.3, duration: 500 }), 800);
    return () => {
      clearTimeout(t);
      sim.stop();
    };
  }, [data, setNodes, setEdges]);

  useEffect(() => {
    setEdges(crossOnly ? allEdges.current.filter((e) => (e.data as { cross?: boolean })?.cross) : allEdges.current);
  }, [crossOnly, setEdges]);

  // Dragging pins the node (fx/fy) so the rest of the graph reacts to it.
  const pin = useCallback((node: RFNode) => {
    const s = simById.current.get(node.id);
    if (!s) return;
    const size = (node.data as StudentData).size;
    s.fx = node.position.x + size / 2;
    s.fy = node.position.y + size / 2;
  }, []);

  const onNodeDragStart = useCallback(
    (_: React.MouseEvent, node: RFNode) => {
      dragId.current = node.id;
      pin(node);
      simRef.current?.alphaTarget(0.3).restart();
    },
    [pin]
  );
  const onNodeDrag = useCallback((_: React.MouseEvent, node: RFNode) => pin(node), [pin]);
  const onNodeDragStop = useCallback((_: React.MouseEvent, node: RFNode) => {
    const s = simById.current.get(node.id);
    if (s) {
      s.fx = null;
      s.fy = null;
    }
    dragId.current = null;
    simRef.current?.alphaTarget(0);
  }, []);

  const legend = useMemo(() => {
    const s = new Set<string>();
    data?.nodes.forEach((nd) => s.add(nd.group));
    return [...s];
  }, [data]);

  return (
    // Full bleed: cancel the layout's content padding so the graph fills edge to edge.
    <div className="-m-6 h-[calc(100%+3rem)] md:-m-8 md:h-[calc(100%+4rem)]">
      {nodes.length > 0 && (
        <ReactFlow
          colorMode={resolvedTheme === "dark" ? "dark" : "light"}
          nodes={nodes}
          edges={edges}
          onNodesChange={onNodesChange}
          onEdgesChange={onEdgesChange}
          onNodeDragStart={onNodeDragStart}
          onNodeDrag={onNodeDrag}
          onNodeDragStop={onNodeDragStop}
          onInit={(instance) => {
            rf.current = instance;
          }}
          nodeTypes={nodeTypes}
          fitView
          fitViewOptions={{ padding: 0.3 }}
          minZoom={0.2}
          maxZoom={3}
          proOptions={{ hideAttribution: true }}
          nodesConnectable={false}
          elementsSelectable
          className="h-full w-full bg-background"
        >
          <Background gap={24} size={1} color="var(--border)" />
          <Controls showInteractive={false} />
          <MiniMap pannable zoomable nodeColor={(node) => (node.data as StudentData).color} nodeStrokeWidth={0} />

          <Panel position="top-left">
            <div className="flex max-w-md flex-col gap-1.5 rounded-2xl border border-border bg-background/85 px-3.5 py-3 backdrop-blur-sm">
              <p className="text-sm font-medium">The Map</p>
              <p className="text-xs text-muted-foreground">
                {data ? `${data.totalMembers} students · ${data.totalConnections} connections · drag a node` : ""}
              </p>
              <div className="mt-1 flex max-w-xs flex-wrap gap-x-3 gap-y-1">
                {legend.map((g) => (
                  <span key={g} className="inline-flex items-center gap-1.5 text-xs text-muted-foreground">
                    <span className="size-2 rounded-full" style={{ background: disciplineColor(g) }} />
                    {g}
                  </span>
                ))}
              </div>
            </div>
          </Panel>

          <Panel position="top-right">
            <Button variant={crossOnly ? "default" : "outline"} size="sm" className="rounded-full" onClick={() => setCrossOnly((v) => !v)}>
              Cross-discipline only
            </Button>
          </Panel>
        </ReactFlow>
      )}
    </div>
  );
}
