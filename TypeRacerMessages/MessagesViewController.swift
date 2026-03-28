import UIKit
import Messages
import SwiftUI
import FirebaseCore

class MessagesViewController: MSMessagesAppViewController {

    private var gameState = GameState()

    override func viewDidLoad() {
        super.viewDidLoad()
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        presentUI(for: conversation, with: presentationStyle)
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        guard let conversation = activeConversation else { return }
        presentUI(for: conversation, with: presentationStyle)
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)

        guard let url = message.url,
              let decoded = MessageURLCoder.decode(url: url) else { return }

        if decoded.status == .finished {
            gameState.phase = .finished
            gameState.joinRace(raceId: decoded.raceId)
        } else {
            requestPresentationStyle(.expanded)
            gameState.joinRace(raceId: decoded.raceId)
        }
    }

    private func presentUI(for conversation: MSConversation, with presentationStyle: MSMessagesAppPresentationStyle) {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }

        let rootView = ExtensionRootView(
            gameState: gameState,
            isCompact: presentationStyle == .compact,
            onRequestExpanded: { [weak self] in
                self?.requestPresentationStyle(.expanded)
            },
            onSendMessage: { [weak self] raceId, status, winnerName, winnerWPM in
                self?.sendRaceMessage(
                    conversation: conversation,
                    raceId: raceId,
                    status: status,
                    winnerName: winnerName,
                    winnerWPM: winnerWPM
                )
            }
        )

        let hostingController = UIHostingController(rootView: rootView)
        addChild(hostingController)
        hostingController.view.frame = view.bounds
        hostingController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
    }

    private func sendRaceMessage(conversation: MSConversation, raceId: String, status: RaceStatus, winnerName: String?, winnerWPM: Int?) {
        guard let encodedURL = MessageURLCoder.encode(raceId: raceId, status: status, winnerName: winnerName, winnerWPM: winnerWPM) else {
            print("Failed to encode message URL")
            return
        }
        let session = conversation.selectedMessage?.session ?? MSSession()
        let message = MSMessage(session: session)
        message.url = encodedURL

        let layout = MSMessageTemplateLayout()
        switch status {
        case .waiting:
            layout.caption = "Type Race! Tap to join"
            layout.subcaption = "Race your friends to type a sentence"
        case .racing, .countdown:
            layout.caption = "Type Race in progress..."
            layout.subcaption = "Tap to spectate"
        case .finished:
            if let name = winnerName, let wpm = winnerWPM {
                layout.caption = "\(name) wins! \(wpm) WPM"
                layout.subcaption = "Tap to see full results"
            } else {
                layout.caption = "Race finished!"
                layout.subcaption = "Tap to see results"
            }
        }
        message.layout = layout

        conversation.insert(message) { error in
            if let error {
                print("Failed to insert message: \(error)")
            }
        }
    }

    override func didResignActive(with conversation: MSConversation) {
        super.didResignActive(with: conversation)
    }
}

// MARK: - SwiftUI Root View

struct ExtensionRootView: View {
    @ObservedObject var gameState: GameState
    let isCompact: Bool
    let onRequestExpanded: () -> Void
    let onSendMessage: (String, RaceStatus, String?, Int?) -> Void

    var body: some View {
        Group {
            if isCompact {
                CompactView(onStartRace: {
                    onRequestExpanded()
                })
            } else {
                switch gameState.phase {
                case .compact:
                    CompactView(onStartRace: {
                        gameState.createRace()
                        if let raceId = gameState.race?.id {
                            onSendMessage(raceId, .waiting, nil, nil)
                        }
                    })
                case .lobby:
                    LobbyView(gameState: gameState, onStartRace: {
                        gameState.startCountdown()
                    })
                case .countdown(let seconds):
                    CountdownOverlay(seconds: seconds)
                case .racing:
                    RaceView(gameState: gameState)
                case .finished:
                    ResultsView(gameState: gameState, onShareResults: {
                        if let race = gameState.race {
                            let winner = race.winner
                            onSendMessage(race.id, .finished, winner?.nickname, winner?.wpm)
                        }
                    }, onRematch: {
                        gameState.requestRematch()
                    })
                }
            }
        }
    }
}

struct CountdownOverlay: View {
    let seconds: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
            Text("\(seconds)")
                .font(.system(size: 120, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .scaleEffect(1.2)
                .animation(.easeOut(duration: 0.3), value: seconds)
        }
        .ignoresSafeArea()
    }
}
