//
//  SkillCategoryStyle.swift
//  junto
//
//  Junto's maker taxonomy — the 12 ways a student can contribute to building a
//  venture. Short, recognizable labels (the chip is just the label; the deeper
//  skills live in the backend catalog under each). Every skill maps to exactly
//  one of these, so a person with infinite skills still collapses to a bounded,
//  browseable set.
//
//  Two surfaces draw from this:
//   • Discover's "Browse By Category" chips — colored icon per category.
//   • Feed / event-card category tags (TopicTag) — same icons, rendered gray.
//
//  `match(_:)` is a transitional heuristic that buckets free-form skill strings
//  onto a category until the backend returns each skill's real category.
//

import SwiftUI

enum SkillCategory: String, CaseIterable {
    case software
    case ai
    case design
    case hardware
    case data
    case business
    case finance
    case marketing
    case content
    case science
    case health
    case impact
    case leadership

    /// Short display label.
    var label: String {
        switch self {
        case .software:   return "Software"
        case .ai:         return "AI"
        case .design:     return "Design"
        case .hardware:   return "Hardware"
        case .data:       return "Data"
        case .business:   return "Business"
        case .finance:    return "Finance"
        case .marketing:  return "Marketing"
        case .content:    return "Content"
        case .science:    return "Science"
        case .health:     return "Health"
        case .impact:     return "Impact"
        case .leadership: return "Leadership"
        }
    }

    /// Streamline Flex line icon asset (template-rendered).
    var icon: ImageResource {
        switch self {
        case .software:   return .topicCode
        case .ai:         return .topicAi
        case .design:     return .topicDesign
        case .hardware:   return .topicEngineering
        case .data:       return .topicAnalytics
        case .business:   return .topicBusiness
        case .finance:    return .topicFinance
        case .marketing:  return .topicMarketing
        case .content:    return .topicContent
        case .science:    return .topicSciences
        case .health:     return .topicHealth
        case .impact:     return .topicImpact
        case .leadership: return .topicCommunication
        }
    }

    /// Brand accent for the category — a 12-color categorical palette spread
    /// across the hue wheel so the chip row reads as one designed set.
    var color: Color {
        switch self {
        case .software:   return Color(hex: 0x0051FF) // blue
        case .ai:         return Color(hex: 0x6741D9) // deep violet
        case .design:     return Color(hex: 0x7C3AED) // violet
        case .hardware:   return Color(hex: 0xE8590C) // orange
        case .data:       return Color(hex: 0x0CA678) // teal
        case .business:   return Color(hex: 0x2F9E44) // green
        case .finance:    return Color(hex: 0xB7791F) // gold
        case .marketing:  return Color(hex: 0xE8388A) // pink
        case .content:    return Color(hex: 0xAE3EC9) // grape
        case .science:    return Color(hex: 0x4263EB) // indigo
        case .health:     return Color(hex: 0xE03131) // red
        case .impact:     return Color(hex: 0x1098AD) // cyan
        case .leadership: return Color(hex: 0xF08C00) // amber
        }
    }

    /// Normalize a free-form category/skill string onto a canonical case.
    /// Tries the short label first, then a keyword fallback for the looser
    /// values that show up in profile skills and AI-tagged topics.
    static func match(_ raw: String) -> SkillCategory? {
        let s = raw.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !s.isEmpty else { return nil }

        // Exact label match.
        if let exact = allCases.first(where: { $0.label.lowercased() == s }) {
            return exact
        }

        // Keyword fallback. Order matters — check the more specific buckets
        // before the broader ones.
        func has(_ needles: [String]) -> Bool { needles.contains { s.contains($0) } }

        if has(["ui", "ux", "design", "graphic", "figma", "brand", "typography", "industrial design", "motion"]) { return .design }
        if has(["artificial intelligence", "machine learning", "llm", "gpt", "neural", "computer vision", "generative", "genai", "ai agent", "prompt eng", "deep learning", "nlp"]) { return .ai }
        if has(["data", "analytics", "statistic", "sql", "database", "visualization"]) { return .data }
        if has(["software", "develop", "programming", "coding", "web", "frontend", "backend", "full stack", "fullstack", "ios", "android", "app", "devops", "cloud"]) { return .software }
        if has(["hardware", "mechanical", "electrical", "robotics", "embedded", "cad", "prototyp", "manufactur", "aerospace", "circuit", "3d"]) { return .hardware }
        if has(["finance", "financ", "accounting", "investing", "investment", "fundraising", "venture", "capital", "fintech", "trading", "banking"]) { return .finance }
        if has(["marketing", "growth", "seo", "sem", "advertising", "sales", "social media", "crm", "partnership"]) { return .marketing }
        if has(["content", "video", "photo", "music", "audio", "podcast", "film", "editing", "creator", "copywriting", "writing", "journalism", "animation"]) { return .content }
        if has(["science", "research", "biology", "chemistry", "physics", "lab", "environmental", "materials", "agricultur", "agronomy"]) { return .science }
        if has(["health", "wellness", "medicine", "medical", "fitness", "nursing", "nutrition", "biotech", "clinical", "mental health", "sports science"]) { return .health }
        if has(["impact", "policy", "nonprofit", "non-profit", "sustainability", "education", "teaching", "advocacy", "government", "social work", "law", " legal", "economics"]) { return .impact }
        if has(["leadership", "management", "public speaking", "organizing", "mentor", "recruiting", "people ops", "project management", "community", "operations", "consulting"]) { return .leadership }
        if has(["business", "strategy", "entrepreneur", "startup", "product management", "supply chain"]) { return .business }

        return nil
    }
}

// MARK: - Color hex init

extension Color {
    /// Create a Color from a 0xRRGGBB integer.
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}
