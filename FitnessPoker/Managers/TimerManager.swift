import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var timeLimit: TimeInterval = 0
    @Published var isExpired: Bool = false

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init() {
        timeLimit = 300
        timeRemaining = 300
    }

    func setTimeLimit(_ seconds: TimeInterval) {
        timeLimit = seconds
        timeRemaining = seconds
    }

    func start() {
        guard !isRunning, timeLimit > 0 else { return }

        // If timer was paused, just resume. Otherwise, start from the limit.
        if timeRemaining == 0 {
            timeRemaining = timeLimit
        }

        isRunning = true
        timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.tick()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
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
        isExpired = false
    }

    func reset() {
        stop()
    }

    private func tick() {
        guard timeRemaining > 0 else { return }

        timeRemaining -= 1
        if timeRemaining <= 0 {
            isExpired = true
            pause()
        }
    }

    var formattedTime: String {
        let minutes = Int(timeRemaining) / 60
        let seconds = Int(timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var formattedTimeLimit: String {
        if timeLimit <= 0 {
            return "No Limit"
        }
        let minutes = Int(timeLimit) / 60
        let seconds = Int(timeLimit) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    deinit {
        timer?.invalidate()
    }
}