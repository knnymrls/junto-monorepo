// DESIGN.md's 12-category palette. The Map / cohort coloring is the one place
// categorical color is earned (category identity IS the content there).
export const DISCIPLINE_COLORS: Record<string, string> = {
  software: "#0051FF", ai: "#6741D9", design: "#7C3AED", hardware: "#E8590C",
  data: "#0CA678", business: "#2F9E44", finance: "#B7791F", marketing: "#E8388A",
  content: "#AE3EC9", science: "#4263EB", health: "#E03131", impact: "#1098AD",
  leadership: "#F08C00",
};

export const disciplineColor = (group?: string) =>
  (group && DISCIPLINE_COLORS[group.toLowerCase()]) || "var(--co-other)";
