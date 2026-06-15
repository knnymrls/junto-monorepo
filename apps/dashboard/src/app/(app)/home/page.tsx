import { Briefing } from "@/components/home/briefing";
import { NetworkBand } from "@/components/home/network-band";
import { ActivityFeed } from "@/components/home/activity-feed";
import { NeedsAttention } from "@/components/home/needs-attention";

export default function HomePage() {
  return (
    <div className="mx-auto flex w-full max-w-6xl flex-col gap-8">
      {/* The verdict — answer "is it working?" in one read */}
      <Briefing />

      {/* The one visual — cross-college collaboration made visible */}
      <NetworkBand />

      {/* The story (what happened) + the to-do (what needs you) */}
      <div className="grid gap-x-12 gap-y-8 lg:grid-cols-5">
        <div className="lg:col-span-3">
          <ActivityFeed />
        </div>
        <div className="lg:col-span-2">
          <NeedsAttention />
        </div>
      </div>
    </div>
  );
}
