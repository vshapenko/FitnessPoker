import Foundation
import Combine

class TimerManager: ObservableObject {
    @Published var timeElapsed: TimeInterval = 0
    @Published var isRunning: Bool = false
    @Published var timeLimit: TimeInterval = 0
    @Published var isExpired: Bool = false

    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    func setTimeLimit(_ seconds: TimeInterval) {
        timeLimit = seconds
    }

    func start() {
        guard !isRunning else { return }

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
        timeElapsed = 0
        isExpired = false
    }

    func reset() {
        stop()
        timeElapsed = 0
        isExpired = false
    }

    private func tick() {
        timeElapsed += 1
        let newIsExpired = timeLimit > 0 && timeElapsed >= timeLimit
        if isExpired != newIsExpired {
            isExpired = newIsExpired
        }
        if isExpired {
            pause()
        }
    }

    var formattedTime: String {
        let minutes = Int(timeElapsed) / 60
        let seconds = Int(timeElapsed) % 60
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