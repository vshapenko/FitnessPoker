import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var timeLimit: TimeInterval = 60

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func setTimeLimit(_ seconds: TimeInterval) {
        timeLimit = seconds
        if !isRunning {
            timeRemaining = timeLimit
        }
    }

    func start() {
        guard !isRunning else { return }

        if timeRemaining <= 0 {
            timeRemaining = timeLimit
        }

        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tick()
        }
    }

    func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }

    func stop() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        timeRemaining = timeLimit
    }

    func reset() {
        stop()
        timeRemaining = timeLimit
    }

    private func tick() {
        if timeRemaining > 0 {
            timeRemaining -= 1
        } else {
            pause()
        }
    }

    var isExpired: Bool {
        return timeRemaining <= 0
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    deinit {
        timer?.invalidate()
    }
}