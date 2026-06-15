import { SidebarProvider, SidebarInset, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "@/components/app-sidebar";
import { HeaderTitle } from "@/components/header-title";
import { CohortLens } from "@/components/cohort-lens";
import { TimeframeLens } from "@/components/timeframe-lens";
import { ModeToggle } from "@/components/mode-toggle";

export default function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <SidebarProvider>
      <AppSidebar />
      <SidebarInset className="h-svh overflow-hidden">
        <header className="flex h-14 shrink-0 items-center gap-2 border-b border-border bg-background px-4">
          <SidebarTrigger className="-ml-1 text-muted-foreground" />
          <HeaderTitle />
          {/* Global lenses — persist across every surface */}
          <div className="ml-auto flex items-center gap-2">
            <CohortLens />
            <TimeframeLens />
            <ModeToggle />
          </div>
        </header>
        <main className="min-h-0 flex-1 overflow-y-auto p-6 md:p-8">{children}</main>
      </SidebarInset>
    </SidebarProvider>
  );
}
