//
//  EventDetailView.swift
//  junto
//
//  Luma-style event detail. The event poster is blurred into a full-screen
//  ambient backdrop; a sharp poster card, title, host/date/time meta, and a
//  share action sit on top. Reuses PostDetailTopNav (.overlay) so it reads as
//  the same nav family as the post detail. Figma node 70:1084.
//
//  Scope note: this is the redesigned hero only. The lower sections (About,
//  Hosted by, Attendees, Feedback) and RSVP/calendar logic from the previous
//  design were intentionally dropped for now — the action button is a Share
//  placeholder until the creator-set custom CTA lands. History in git.
//

import SwiftUI
import MapKit
import CoreLocation

struct EventDetailView: View {
    let event: EventWithRsvpResponse

    @Environment(\.dismiss) private var dismiss
    @State private var showShareSheet = false
    @State private var calendarFile: CalendarFile?
    @State private var locationCoordinate: CLLocationCoordinate2D?
    @State private var selectedProfile: UserResponse?

    /// Identifiable wrapper so the generated .ics can drive a `.sheet(item:)`.
    private struct CalendarFile: Identifiable {
        let id = UUID()
        let url: URL
    }

    var body: some View {
        VStack(spacing: 0) {
            PostDetailTopNav(
                title: "Event",
                style: .overlay,
                onBack: { dismiss() },
                onShare: { showShareSheet = true }
            )

            ScrollView(showsIndicators: false) {
                heroContent
                    .padding(Spacing.lg)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        // Ambient backdrop lives in .background() so the blurred fill image can
        // never drive the content's layout size (a sibling .fill image would).
        .background(ambientBackground.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [shareText])
        }
        .sheet(item: $calendarFile) { file in
            ShareSheet(items: [file.url])
        }
        .fullScreenCover(item: $selectedProfile) { user in
            ProfileView(user: user)
        }
        .task {
            AnalyticsService.shared.track(.eventViewed(
                eventId: event._id,
                eventType: event.eventType.rawValue,
                hostId: event.createdBy
            ))
            await geocodeLocation()
        }
    }

    // MARK: - Ambient Background (Luma-style)

    private var ambientBackground: some View {
        ZStack {
            Color.black

            if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                CachedAsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.clear
                }
                .blur(radius: 50)
                .opacity(0.3)
            }
        }
    }

    // MARK: - Hero Content

    private var heroContent: some View {
        VStack(spacing: Spacing.lg) {
            posterCard

            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.lg) {
                    Text(event.title)
                        .font(.heading1)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    metaRows

                    actionButtons
                }

                if event.location != nil || event.fullAddress != nil {
                    locationSection
                }

                if event.host != nil {
                    hostsSection
                }

                if event.goingCount > 0 {
                    goingSection
                }

                if let description = event.description, !description.isEmpty {
                    aboutSection(description)
                }

                if let category = event.category, !category.isEmpty {
                    tagsSection(category)
                }
            }
            .padding(.bottom, Spacing.xl)
        }
    }

    // MARK: - Section Header (Junto take on the Luma section label + divider)

    private func sectionHeader(_ title: String, trailing: String? = nil, trailingAction: (() -> Void)? = nil) -> some View {
        VStack(spacing: Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.bodyLargeSemibold)
                    .foregroundColor(.white)
                Spacer(minLength: 0)
                if let trailing {
                    Button(action: { trailingAction?() }) {
                        Text(trailing)
                            .font(.bodyLarge)
                            .foregroundColor(.appSecondaryOnDark)
                    }
                    .buttonStyle(.plain)
                }
            }
            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(height: 1)
        }
    }

    // MARK: - Location

    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader("Location")

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let location = event.location, !location.isEmpty {
                    Text(location)
                        .font(.bodyLargeSemibold)
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let address = event.fullAddress, !address.isEmpty {
                    Text(address)
                        .font(.bodyLarge)
                        .foregroundColor(.appSecondaryOnDark)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            if let coordinate = locationCoordinate {
                mapCard(coordinate)
            }
        }
    }

    private func mapCard(_ coordinate: CLLocationCoordinate2D) -> some View {
        Map(initialPosition: .region(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
        ))) {
            Marker(event.location ?? "Event", coordinate: coordinate)
                .tint(Color.appPrimary)
        }
        .frame(height: 180)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        // Static map (no pan/zoom inside the scroll); tap opens Apple Maps.
        .allowsHitTesting(false)
        .overlay(
            Button(action: { openInMaps(coordinate) }) {
                Color.clear.contentShape(Rectangle())
            }
        )
    }

    // MARK: - Hosts

    private var hostsSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader("Hosts")

            if let host = event.host {
                Button(action: { openHostProfile(host) }) {
                    HStack(spacing: Spacing.sm) {
                        AvatarView(avatarUrl: host.avatarUrl, name: host.name, size: 44)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(host.name)
                                .font(.bodyLargeSemibold)
                                .foregroundColor(.white)
                            if let headline = host.headline, !headline.isEmpty {
                                Text(headline)
                                    .font(.bodyLarge)
                                    .foregroundColor(.appSecondaryOnDark)
                                    .lineLimit(1)
                            }
                        }
                        Spacer(minLength: 0)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressableScale(0.98))
            }
        }
    }

    private func openHostProfile(_ host: EventWithRsvpResponse.EventHost) {
        Task {
            if let user = try? await ConvexClientManager.shared.fetchUser(id: host.id) {
                await MainActor.run { selectedProfile = user }
            }
        }
    }

    // MARK: - Going

    private var goingSection: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader("\(event.goingCount) Going")

            if let previews = event.attendeePreviews, !previews.isEmpty {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    attendeeAvatarStack(previews)
                    Text(attendeeNamesText(previews))
                        .font(.bodyLarge)
                        .foregroundColor(.appSecondaryOnDark)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func attendeeAvatarStack(_ previews: [EventWithRsvpResponse.AttendeePreview]) -> some View {
        let shown = Array(previews.prefix(4))
        let remaining = max(0, event.goingCount - shown.count)
        return HStack(spacing: -10) {
            ForEach(shown) { person in
                AvatarView(avatarUrl: person.avatarUrl, name: person.name, size: 36)
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
            }
            if remaining > 0 {
                Text("+\(remaining)")
                    .font(.captionSemibold)
                    .foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Color.white.opacity(0.15))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.black, lineWidth: 2))
            }
        }
    }

    private func attendeeNamesText(_ previews: [EventWithRsvpResponse.AttendeePreview]) -> String {
        let names = previews.prefix(4).map { $0.name }
        let remaining = max(0, event.goingCount - names.count)
        var text = names.joined(separator: ", ")
        if remaining > 0 {
            text += text.isEmpty ? "\(remaining) going" : ", and \(remaining) more"
        }
        return text
    }

    // MARK: - About

    private func aboutSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader("About")
            Text(description)
                .font(.bodyLarge)
                .foregroundColor(.appSecondaryOnDark)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    // MARK: - Tags

    private func tagsSection(_ category: String) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            sectionHeader("Tags")
            HStack {
                Text(category)
                    .font(.bodyMedium)
                    .foregroundColor(.white)
                    .padding(.horizontal, Spacing.md)
                    .padding(.vertical, Spacing.sm)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Location helpers

    private func geocodeLocation() async {
        let query = [event.fullAddress, event.location]
            .compactMap { $0 }
            .first { !$0.isEmpty }
        guard let query else { return }
        // async API keeps the geocoder alive across the request (a local
        // CLGeocoder() with a completion handler would deinit and cancel).
        let placemarks = try? await CLGeocoder().geocodeAddressString(query)
        if let coordinate = placemarks?.first?.location?.coordinate {
            locationCoordinate = coordinate
            return
        }
        #if DEBUG
        // Geocoding is unreliable in the simulator — fall back so the preview
        // rig still shows the map. Production geocodes the real address above.
        if ProcessInfo.processInfo.environment["JUNTO_PREVIEW_FEED"] == "1" {
            locationCoordinate = CLLocationCoordinate2D(latitude: 40.8136, longitude: -96.7026)
        }
        #endif
    }

    private func openInMaps(_ coordinate: CLLocationCoordinate2D) {
        let item = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        item.name = event.location ?? event.title
        item.openInMaps()
    }

    // Fixed-size rounded box drives the layout; the image is an overlay clipped
    // to it. A sibling `.aspectRatio(.fill)` image would expand the frame and
    // break the hero's padding (title clipping at the edge). Same pattern as
    // FeedEventCard's banner.
    private var posterCard: some View {
        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
            .fill(Color.white.opacity(0.08))
            .frame(height: 208)
            .frame(maxWidth: .infinity)
            .overlay {
                if let imageUrl = event.imageUrl, let url = URL(string: imageUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.clear
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
    }

    // MARK: - Meta Rows

    private var metaRows: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let host = event.host {
                HStack(spacing: Spacing.sm) {
                    AvatarView(avatarUrl: host.avatarUrl, name: host.name, size: 16)
                    Text(host.name)
                        .font(.bodyLarge)
                        .foregroundColor(.white)
                }
            }

            metaRow(icon: "feed.calendar", text: dateText)
            metaRow(icon: "event.clock", text: timeText)
        }
    }

    private func metaRow(icon: String, text: String) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(icon)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 16, height: 16)
                .foregroundColor(.appSecondaryOnDark)

            Text(text)
                .font(.bodyLarge)
                .foregroundColor(.appSecondaryOnDark)
        }
    }

    // MARK: - Action Buttons — Register (primary) + Add to Calendar (secondary)
    // Figma 70:1391: two equal-width buttons, icon stacked above a 12pt label.

    private var actionButtons: some View {
        HStack(spacing: Spacing.sm) {
            actionButton(icon: "event.ticket", label: "Register", primary: true) {
                // TODO: event registration flow
            }
            actionButton(icon: "feed.calendar", label: "Add to Calendar", primary: false) {
                addToCalendar()
            }
        }
        .padding(.top, Spacing.xxs)
    }

    private func actionButton(icon: String, label: String, primary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: Spacing.xxs) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                Text(label)
                    .font(.captionSemibold)
            }
            .foregroundColor(primary ? Color(red: 0.176, green: 0.176, blue: 0.176) : .white.opacity(0.8))
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(primary ? Color.white : Color.white.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: Radius.xl, style: .continuous))
        }
        .buttonStyle(.pressableScale(0.97))
    }

    // MARK: - Add to Calendar
    // Generates a standard .ics and hands it to the share sheet, which surfaces
    // the system "Add to Calendar" action — no calendar permission needed.

    private func addToCalendar() {
        let stamp = DateFormatter()
        stamp.locale = Locale(identifier: "en_US_POSIX")
        stamp.dateFormat = "yyyyMMdd'T'HHmmss"
        let start = stamp.string(from: event.dateValue)
        let end = stamp.string(from: event.endDateValue ?? event.dateValue.addingTimeInterval(3600))

        var lines = [
            "BEGIN:VCALENDAR", "VERSION:2.0", "PRODID:-//Junto//Event//EN",
            "BEGIN:VEVENT", "UID:\(event._id)@junto",
            "DTSTART:\(start)", "DTEND:\(end)", "SUMMARY:\(event.title)"
        ]
        if let location = event.location { lines.append("LOCATION:\(location)") }
        if let description = event.description { lines.append("DESCRIPTION:\(description)") }
        lines += ["END:VEVENT", "END:VCALENDAR"]

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(event._id).ics")
        try? lines.joined(separator: "\r\n").data(using: .utf8)?.write(to: url)
        calendarFile = CalendarFile(url: url)
    }

    // MARK: - Helpers

    private var shareText: String {
        var parts = [event.title, "\(dateText) · \(timeText)"]
        if let location = event.location {
            parts.append(location)
        }
        return parts.joined(separator: "\n")
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: event.dateValue) + ordinalSuffix(for: event.dateValue)
    }

    private func ordinalSuffix(for date: Date) -> String {
        let day = Calendar.current.component(.day, from: date)
        switch day {
        case 11, 12, 13:
            return "th"
        default:
            switch day % 10 {
            case 1: return "st"
            case 2: return "nd"
            case 3: return "rd"
            default: return "th"
            }
        }
    }

    private var timeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        let start = formatter.string(from: event.dateValue)

        if let endDate = event.endDateValue {
            return "\(start) - \(formatter.string(from: endDate))"
        }
        return start
    }
}

// MARK: - Preview

#Preview {
    EventDetailView(
        event: EventWithRsvpResponse(
            _id: "event_1",
            title: "Open Pitch Night #3",
            description: "Low stakes, casual environment. Share an idea or practice a pitch. Offer and receive help from faculty and peers.",
            date: Date().addingTimeInterval(86400 * 3).timeIntervalSince1970 * 1000,
            endDate: Date().addingTimeInterval(86400 * 3 + 10800).timeIntervalSince1970 * 1000,
            location: "Center for Entrepreneurship (HLH 315)",
            fullAddress: "Center for Entrepreneurship, Lincoln, NE 68508",
            type: "in_person",
            category: "Pitch",
            imageUrl: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=800&h=600&fit=crop",
            createdBy: "mock_1",
            createdAt: Date().timeIntervalSince1970 * 1000,
            goingCount: 5,
            interestedCount: 3,
            host: EventWithRsvpResponse.EventHost(
                id: "mock_1",
                name: "Center of Entrepreneurship",
                avatarUrl: nil,
                headline: "UNL"
            ),
            attendeePreviews: [
                EventWithRsvpResponse.AttendeePreview(id: "mock_2", name: "Sarah Chen", avatarUrl: nil),
                EventWithRsvpResponse.AttendeePreview(id: "mock_3", name: "Marcus Williams", avatarUrl: nil)
            ]
        )
    )
}
