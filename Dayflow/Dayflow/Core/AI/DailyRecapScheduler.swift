//
//  DailyRecapScheduler.swift
//  Dayflow
//

import Foundation

final class DailyRecapScheduler: @unchecked Sendable {
  static let shared = DailyRecapScheduler()

  private let queue = DispatchQueue(label: "com.dayflow.dailyRecapScheduler", qos: .utility)
  private var timer: DispatchSourceTimer?
  private var isRunningCheck = false
  private let attemptBudget = DailyRecapAttemptBudget()

  private let checkInterval: TimeInterval = 5 * 60
  private let sourceLookbackWindowDays = 3
  private let priorStandupHistoryLimit = 3

  private init() {}

  func start() {
    queue.async { [weak self] in
      self?.startOnQueue()
    }
  }

  func stop() {
    queue.async { [weak self] in
      self?.stopOnQueue()
    }
  }

  private func startOnQueue() {
    stopOnQueue()

    let timer = DispatchSource.makeTimerSource(queue: queue)
    timer.schedule(deadline: .now() + checkInterval, repeating: checkInterval)
    timer.setEventHandler { [weak self] in
      self?.triggerCheckOnQueue(reason: "interval")
    }
    timer.resume()
    self.timer = timer

    triggerCheckOnQueue(reason: "startup")
  }

  private func stopOnQueue() {
    timer?.setEventHandler {}
    timer?.cancel()
    timer = nil
    // An in-flight check still owns this flag until its defer runs.
  }

  private func triggerCheckOnQueue(reason: String) {
    guard !isRunningCheck else {
      return
    }

    isRunningCheck = true
    Task.detached(priority: .utility) { [weak self] in
      await self?.runCheck(reason: reason)
    }
  }

  private func runCheck(reason: String) async {
    defer {
      queue.async { [weak self] in
        self?.isRunningCheck = false
      }
    }

    guard UserDefaults.standard.bool(forKey: "isDailyUnlocked") else {
      return
    }

    let now = Date()
    let hour = Calendar.current.component(.hour, from: now)

    guard hour >= 4 else {
      return
    }

    let currentDay = now.getDayInfoFor4AMBoundary()
    let targetDay = currentDay.dayString

    guard StorageManager.shared.fetchDailyStandup(forDay: targetDay) == nil else {
      return
    }

    let minimumActivityMinutes = 180
    guard
      let sourceDay = recapSourceDay(
        before: currentDay.startOfDay,
        targetDayString: targetDay,
        minimumActivityMinutes: minimumActivityMinutes
      )
    else {
      return
    }

    let sourceDayString = sourceDay.dayString
    let sourceStart = sourceDay.startOfDay
    let sourceEnd = sourceDay.endOfDay
    let selectedProvider = DailyRecapGenerator.shared.selectedProvider()
    let providerAvailability =
      DailyRecapGenerator.shared.availabilitySnapshot()[selectedProvider]
      ?? DailyRecapProviderAvailability(
        isAvailable: true,
        detail: selectedProvider.pickerSubtitle
      )
    var providerProps: [String: Any] = [
      "daily_provider": selectedProvider.analyticsName,
      "daily_provider_label": selectedProvider.displayName,
      "daily_runtime": selectedProvider.runtimeLabel,
      "daily_model_or_tool": selectedProvider.modelOrTool as Any,
    ]

    guard selectedProvider.canGenerate else {
      AnalyticsService.shared.capture(
        "daily_auto_generation_check_skipped",
        providerProps.merging(
          [
            "trigger": reason,
            "target_day": targetDay,
            "source_day": sourceDayString,
            "reason": "no_provider_selected",
          ],
          uniquingKeysWith: { _, new in new }
        ))
      return
    }

    guard providerAvailability.isAvailable else {
      AnalyticsService.shared.capture(
        "daily_auto_generation_check_skipped",
        providerProps.merging(
          [
            "trigger": reason,
            "target_day": targetDay,
            "source_day": sourceDayString,
            "reason": "provider_unavailable",
            "provider_detail": providerAvailability.detail,
          ],
          uniquingKeysWith: { _, new in new }
        ))
      return
    }

    // Reserve before generation so failures and app restarts cannot restart the retry loop.
    guard let attempt = attemptBudget.reserveAttempt(forDay: targetDay) else {
      return
    }
    providerProps["attempt_number"] = attempt
    providerProps["max_attempts"] = DailyRecapAttemptBudget.maxAttempts

    let usesDayflowInputs = selectedProvider.usesDayflowInputs

    let cards = StorageManager.shared.fetchTimelineCards(forDay: sourceDayString)
    let observations =
      usesDayflowInputs
      ? StorageManager.shared.fetchObservations(
        startTs: Int(sourceStart.timeIntervalSince1970),
        endTs: Int(sourceEnd.timeIntervalSince1970)
      ) : []
    let priorEntries =
      usesDayflowInputs
      ? StorageManager.shared.fetchRecentDailyStandups(
        limit: priorStandupHistoryLimit,
        excludingDay: sourceDayString
      ) : []

    let cardsText = DailyRecapGenerator.makeCardsText(day: sourceDayString, cards: cards)
    let observationsText =
      usesDayflowInputs
      ? DailyRecapGenerator.makeObservationsText(day: sourceDayString, observations: observations)
      : ""
    let priorDailyText =
      usesDayflowInputs ? DailyRecapGenerator.makePriorDailyText(entries: priorEntries) : ""
    let preferencesText =
      usesDayflowInputs
      ? DailyRecapGenerator.makePreferencesText(
        highlightsTitle: "Yesterday's highlights",
        tasksTitle: "Today's tasks",
        blockersTitle: "Blockers"
      ) : ""
    AnalyticsService.shared.capture(
      "daily_auto_generation_check_started",
      providerProps.merging(
        [
          "trigger": reason,
          "target_day": targetDay,
          "source_day": sourceDayString,
        ],
        uniquingKeysWith: { _, new in new }
      ))

    AnalyticsService.shared.capture(
      "daily_auto_generation_payload_built",
      providerProps.merging(
        [
          "trigger": reason,
          "target_day": targetDay,
          "source_day": sourceDayString,
          "input_mode": usesDayflowInputs ? "cards_observations_prior" : "cards_only",
          "cards_count": cards.count,
          "observations_count": observations.count,
          "prior_daily_count": priorEntries.count,
          "cards_text_chars": cardsText.count,
          "observations_text_chars": observationsText.count,
          "prior_daily_text_chars": priorDailyText.count,
          "preferences_text_chars": preferencesText.count,
        ],
        uniquingKeysWith: { _, new in new }
      ))

    let startedAt = Date()
    do {
      let context = DailyRecapGenerationContext(
        targetDayString: targetDay,
        sourceDayString: sourceDayString,
        cards: cards,
        observations: observations,
        priorEntries: priorEntries,
        highlightsTitle: "Yesterday's highlights",
        tasksTitle: "Today's tasks",
        blockersTitle: "Blockers"
      )
      let draft = try await DailyRecapGenerator.shared.generate(context: context)
      guard let payloadJSON = draft.encodedJSONString() else {
        AnalyticsService.shared.capture(
          "daily_auto_generation_failed",
          providerProps.merging(
            [
              "trigger": reason,
              "target_day": targetDay,
              "source_day": sourceDayString,
              "failure_reason": "payload_encoding_failed",
            ],
            uniquingKeysWith: { _, new in new }
          ))
        return
      }

      StorageManager.shared.saveDailyStandup(forDay: targetDay, payloadJSON: payloadJSON)
      guard StorageManager.shared.fetchDailyStandup(forDay: targetDay) != nil else {
        AnalyticsService.shared.capture(
          "daily_auto_generation_failed",
          providerProps.merging(
            [
              "trigger": reason,
              "target_day": targetDay,
              "source_day": sourceDayString,
              "failure_reason": "db_save_verification_failed",
            ],
            uniquingKeysWith: { _, new in new }
          ))
        return
      }
      AnalyticsService.shared.capture(
        "daily_auto_generation_succeeded",
        providerProps.merging(
          [
            "trigger": reason,
            "target_day": targetDay,
            "source_day": sourceDayString,
            "latency_ms": Int(Date().timeIntervalSince(startedAt) * 1000),
            "highlights_count": draft.highlights.count,
            "tasks_count": draft.tasks.count,
            "unfinished_count": draft.tasks.count,
            "blockers_count": draft.blockersBody
              .split(whereSeparator: \.isNewline)
              .count,
          ],
          uniquingKeysWith: { _, new in new }
        ))

      await MainActor.run {
        NotificationService.shared.scheduleDailyRecapReadyNotification(forDay: targetDay)
      }
    } catch {
      let nsError = error as NSError
      AnalyticsService.shared.capture(
        "daily_auto_generation_failed",
        providerProps.merging(
          [
            "trigger": reason,
            "target_day": targetDay,
            "source_day": sourceDayString,
            "failure_reason": "api_error",
            "error_domain": nsError.domain,
            "error_code": nsError.code,
          ],
          uniquingKeysWith: { _, new in new }
        ))
    }
  }

  private func recapSourceDay(
    before targetStart: Date,
    targetDayString: String,
    minimumActivityMinutes: Int
  ) -> (dayString: String, startOfDay: Date, endOfDay: Date)? {
    let consumedSourceDays = DailyRecapSourceDayResolver.consumedSourceDays(
      from: StorageManager.shared.fetchAllDailyStandups(excludingDay: targetDayString)
    )
    guard
      let candidate = DailyRecapSourceDayResolver.sourceDay(
        before: targetStart,
        lookbackWindowDays: sourceLookbackWindowDays,
        consumedSourceDays: consumedSourceDays,
        hasMinimumActivity: { dayString in
          StorageManager.shared.hasMinimumTimelineActivity(
            forDay: dayString,
            minimumMinutes: minimumActivityMinutes
          )
        })
    else {
      return nil
    }

    return (
      dayString: candidate.dayString,
      startOfDay: candidate.startOfDay,
      endOfDay: candidate.endOfDay
    )
  }

  private static func makePersistedDailyDraftJSON(from response: DayflowDailyGenerationResponse)
    -> String?
  {
    let highlights = normalizedUniqueLines(from: response.highlights).map {
      PersistedDailyBulletItem(text: $0)
    }
    let tasks = normalizedUniqueLines(from: response.unfinished).map {
      PersistedDailyBulletItem(text: $0)
    }
    let blockers = normalizedBlockersText(from: response.blockers)

    let draft = PersistedDailyStandupDraft(
      highlightsTitle: "Yesterday's highlights",
      highlights: highlights,
      tasksTitle: "Today's tasks",
      tasks: tasks,
      blockersTitle: "Blockers",
      blockersBody: blockers
    )

    guard let data = try? JSONEncoder().encode(draft) else { return nil }
    return String(data: data, encoding: .utf8)
  }

  private static func normalizedUniqueLines(from values: [String]) -> [String] {
    var seen: Set<String> = []
    return values.compactMap { raw in
      let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !trimmed.isEmpty else { return nil }
      guard seen.insert(trimmed).inserted else { return nil }
      return trimmed
    }
  }

  private static func normalizedBlockersText(from values: [String]) -> String {
    values
      .compactMap { value -> String? in
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
      }
      .joined(separator: "\n")
  }
}

private struct PersistedDailyBulletItem: Codable {
  let id: UUID
  let text: String

  init(text: String) {
    self.id = UUID()
    self.text = text
  }
}

private struct PersistedDailyStandupDraft: Codable {
  let highlightsTitle: String
  let highlights: [PersistedDailyBulletItem]
  let tasksTitle: String
  let tasks: [PersistedDailyBulletItem]
  let blockersTitle: String
  let blockersBody: String
}
