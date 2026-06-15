"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import { ArrowUpRight } from "lucide-react";
import {
  forceSimulation,
  forceManyBody,
  forceLink,
  forceCenter,
  forceCollide,
  forceX,
  forceY,
} from "d3-force";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { useDash } from "@/hooks/use-dash";

// The Map is the one surface allowed categorical color (category identity IS
// the content). DESIGN.md's exact 12-category palette, kept modest.
const PALETTE: Record<string, string> = {
  software: "#0051FF", ai: "#6741D9", design: "#7C3AED", hardware: "#E8590C",
  data: "#0CA678", business: "#2F9E44", finance: "#B7791F", marketing: "#E8388A",
  content: "#AE3EC9", science: "#4263EB", health: "#E03131", impact: "#1098AD",
  leadership: "#F08C00",
};
const colorOf = (group: string) => PALETTE[group?.toLowerCase()] ?? "var(--co-other)";

type Net = {
  nodes: { id: string; degree: number; group: string }[];
  edges: { source: string; target: string; cross: boolean }[];
  totalMembers: number;
  totalConnections: number;
};

const W = 800;
const H = 150;
const PAD = 18;

type LaidNode = { id: string; degree: number; group: string; x: number; y: number };
type LaidEdge = { x1: number; y1: number; x2: number; y2: number; cross: boolean };

export function NetworkBand() {
  const data = useDash<Net>("center:network");
  const [laid, setLaid] = useState<{ nodes: LaidNode[]; edges: LaidEdge[] } | null>(null);

  useEffect(() => {
    if (!data || data.nodes.length === 0) return;

    const n = data.nodes.length;
    const nodes = data.nodes.map((node, i) => ({
      ...node,
      x: W / 2 + Math.cos((i / n) * 2 * Math.PI) * 120,
      y: H / 2 + Math.sin((i / n) * 2 * Math.PI) * 50,
    }));
    const links = data.edges.map((e) => ({ ...e }));

    const sim = forceSimulation(nodes as never[])
      .force("charge", forceManyBody().strength(-70))
      .force("link", forceLink(links as never[]).id((d) => (d as unknown as LaidNode).id).distance(38).strength(0.5))
      .force("center", forceCenter(W / 2, H / 2))
      .force("x", forceX(W / 2).strength(0.06))
      .force("y", forceY(H / 2).strength(0.12))
      .force("collide", forceCollide(11))
      .stop();
    for (let i = 0; i < 300; i++) sim.tick();

    // normalize to fit the band with padding
    const xs = nodes.map((d) => d.x);
    const ys = nodes.map((d) => d.y);
    const minX = Math.min(...xs), maxX = Math.max(...xs);
    const minY = Math.min(...ys), maxY = Math.max(...ys);
    const s = Math.min((W - 2 * PAD) / Math.max(1, maxX - minX), (H - 2 * PAD) / Math.max(1, maxY - minY));
    const ox = PAD + (W - 2 * PAD - (maxX - minX) * s) / 2;
    const oy = PAD + (H - 2 * PAD - (maxY - minY) * s) / 2;
    for (const d of nodes) {
      d.x = ox + (d.x - minX) * s;
      d.y = oy + (d.y - minY) * s;
    }

    const edges: LaidEdge[] = links.map((l) => {
      const src = l.source as unknown as LaidNode;
      const tgt = l.target as unknown as LaidNode;
      return { x1: src.x, y1: src.y, x2: tgt.x, y2: tgt.y, cross: l.cross };
    });

    setLaid({ nodes, edges });
  }, [data]);

  return (
    <Card className="gap-0 py-0">
      <div className="flex items-end justify-between gap-4 px-5 pt-5">
        <div className="flex flex-col gap-0.5">
          <p className="text-sm font-medium">Your network</p>
          <p className="text-xs text-muted-foreground">
            {data
              ? `${data.totalMembers} students · ${data.totalConnections} connections, colored by discipline`
              : "Loading the graph…"}
          </p>
        </div>
        <Link
          href="/map"
          className="inline-flex shrink-0 items-center gap-0.5 text-xs text-muted-foreground transition-colors hover:text-foreground"
        >
          Open the full map
          <ArrowUpRight className="size-3" />
        </Link>
      </div>

      <Link href="/map" className="block px-2 pt-1 pb-4" aria-label="Open the full map">
        {laid ? (
          <svg
            viewBox={`0 0 ${W} ${H}`}
            className="h-[150px] w-full text-foreground"
            preserveAspectRatio="xMidYMid meet"
            role="img"
            aria-label="Connection graph of students, colored by discipline, with cross-discipline bridges brighter"
          >
            {laid.edges.map((e, i) => (
              <line
                key={i}
                x1={e.x1} y1={e.y1} x2={e.x2} y2={e.y2}
                stroke="currentColor"
                strokeOpacity={e.cross ? 0.3 : 0.12}
                strokeWidth={e.cross ? 1.25 : 1}
              />
            ))}
            {laid.nodes.map((node) => (
              <circle
                key={node.id}
                cx={node.x} cy={node.y}
                r={3.5 + Math.min(node.degree, 6) * 1.1}
                fill={colorOf(node.group)}
                stroke="var(--background)"
                strokeWidth={1.5}
              />
            ))}
          </svg>
        ) : (
          <Skeleton className="mx-3 h-[150px] rounded-2xl" />
        )}
      </Link>
    </Card>
  );
}
