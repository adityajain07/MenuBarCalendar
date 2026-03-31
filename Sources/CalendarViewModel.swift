import Foundation
import EventKit
import AppKit
import UserNotifications

struct CalendarEvent: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let calendarName: String
    let calendarColor: NSColor
    let isAllDay: Bool
}

final class CalendarViewModel: ObservableObject {
    @Published var events: [CalendarEvent] = []
    @Published var selectedCalendarIDs: Set<String> = []
    @Published var availableCalendars: [(id: String, title: String, color: NSColor)] = []
    @Published var hasAccess = false
    @Published var reminderMinutes: Int {
        didSet { UserDefaults.standard.set(reminderMinutes, forKey: "reminderMinutes") }
    }

    private var store = EKEventStore()
    private var refreshTimer: Timer?
    private var notifiedEventIDs: Set<String> = []

    var nextEvent: CalendarEvent? {
        let now = Date()
        return events.first { !$0.isAllDay && $0.startDate > now }
    }

    var menuBarText: String {
        guard let next = nextEvent else { return "No upcoming" }
        let mins = Int(next.startDate.timeIntervalSince(Date()) / 60)
        let title = next.title.count > 20 ? String(next.title.prefix(20)) + "..." : next.title
        if mins < 1 {
            return "\(title) now"
        } else if mins < 60 {
            return "\(title) in \(mins)m"
        } else {
            let h = mins / 60
            let m = mins % 60
            return m > 0 ? "\(title) in \(h)h \(m)m" : "\(title) in \(h)h"
        }
    }

    init() {
        let saved = UserDefaults.standard.integer(forKey: "reminderMinutes")
        self.reminderMinutes = saved > 0 ? saved : 10
        loadSelectedCalendars()
        requestAccess()
        requestNotificationPermission()
        startAutoRefresh()
        observeCalendarChanges()
    }

    // MARK: - Access

    private func requestAccess() {
        if #available(macOS 14.0, *) {
            store.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.hasAccess = granted
                    if granted {
                        self?.loadCalendars()
                        self?.fetchEvents()
                    }
                }
            }
        } else {
            store.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.hasAccess = granted
                    if granted {
                        self?.loadCalendars()
                        self?.fetchEvents()
                    }
                }
            }
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    // MARK: - Calendars

    private func loadCalendars() {
        let cals = store.calendars(for: .event)
        availableCalendars = cals.map { (id: $0.calendarIdentifier, title: $0.title, color: $0.color ?? .gray) }

        if selectedCalendarIDs.isEmpty {
            selectedCalendarIDs = Set(cals.map { $0.calendarIdentifier })
            saveSelectedCalendars()
        }
    }

    func toggleCalendar(_ id: String) {
        if selectedCalendarIDs.contains(id) {
            selectedCalendarIDs.remove(id)
        } else {
            selectedCalendarIDs.insert(id)
        }
        saveSelectedCalendars()
        fetchEvents()
    }

    private func saveSelectedCalendars() {
        UserDefaults.standard.set(Array(selectedCalendarIDs), forKey: "selectedCalendars")
    }

    private func loadSelectedCalendars() {
        if let saved = UserDefaults.standard.stringArray(forKey: "selectedCalendars") {
            selectedCalendarIDs = Set(saved)
        }
    }

    // MARK: - Events

    func fetchEvents() {
        store = EKEventStore()
        let now = Date()
        let endOfDay = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let predicate = store.predicateForEvents(withStart: now, end: endOfDay, calendars: nil)
        let ekEvents = store.events(matching: predicate)

        events = ekEvents
            .filter { selectedCalendarIDs.contains($0.calendar.calendarIdentifier) }
            .map { ev in
                CalendarEvent(
                    id: ev.eventIdentifier,
                    title: ev.title ?? "Untitled",
                    startDate: ev.startDate,
                    endDate: ev.endDate,
                    calendarName: ev.calendar.title,
                    calendarColor: ev.calendar.color ?? .gray,
                    isAllDay: ev.isAllDay
                )
            }
            .sorted { a, b in
                if a.isAllDay != b.isAllDay { return !a.isAllDay }
                return a.startDate < b.startDate
            }

        checkUpcomingNotifications()
    }

    // MARK: - Auto Refresh

    private func startAutoRefresh() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.fetchEvents()
            }
        }
    }

    private func observeCalendarChanges() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.loadCalendars()
            self?.fetchEvents()
        }
    }

    // MARK: - Notifications

    private func checkUpcomingNotifications() {
        let now = Date()
        for event in events where !event.isAllDay {
            let minsUntil = event.startDate.timeIntervalSince(now) / 60
            if minsUntil > 0 && minsUntil <= Double(reminderMinutes) && !notifiedEventIDs.contains(event.id) {
                notifiedEventIDs.insert(event.id)
                sendNotification(for: event, minutesUntil: Int(minsUntil))
            }
        }
    }

    private func sendNotification(for event: CalendarEvent, minutesUntil: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Upcoming: \(event.title)"
        content.body = minutesUntil <= 1
            ? "Starting now!"
            : "Starts in \(minutesUntil) minutes"
        content.sound = .default
        let request = UNNotificationRequest(identifier: event.id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
