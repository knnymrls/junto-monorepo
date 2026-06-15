/**
 * A page-level toolbar of "lenses" (filters). Each surface renders the lenses
 * relevant to it — cohort + timeframe on Home, a discipline lens on the Map, etc.
 */
export function LensBar({ children }: { children: React.ReactNode }) {
  return <div className="flex flex-wrap items-center gap-2">{children}</div>;
}
