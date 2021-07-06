//
//  RTM_CollaboratARApp.swift
//  Shared
//
//  Created by Max Cobb on 15/05/2021.
//

import SwiftUI
import Combine
import simd

@main
struct RTM_CollaboratARApp: App {

    private let keyInputSubject = KeyInputSubjectWrapper()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(keyInputSubject) {
                    print("Key pressed: \($0)")
                    let sharedIntroEntry = CollaborationExpEntity.shared
                    switch $0 {
                    case .delete, .escape:
                        if let selectedBox = sharedIntroEntry.selectedBox {
                            sharedIntroEntry.removeCollabModel(selectedBox, sendUpdate: true)
                        } else if sharedIntroEntry.showDrawer {
                            sharedIntroEntry.clickedChannelData = nil
                        }
                        return
                    case .return:
                        if sharedIntroEntry.showDrawer {
                            sharedIntroEntry.createChannel()
                        }
                    default: break
                    }
                    let rotAngle = -Float.pi / 32
                    guard let camAnchor = CollaborationExpEntity.shared.arView?.scene.findEntity(named: "camAnchor")
                    else { return }

                    var endTransform = camAnchor.transform
                    print(endTransform)
                    switch $0 {
                    case .leftArrow:
                        endTransform.rotation *= simd_quatf(angle: rotAngle, axis: [0, 1, 0])
                    case .rightArrow:
                        endTransform.rotation *= simd_quatf(angle: rotAngle, axis: [0, -1, 0])
                    case .upArrow:
                        endTransform.rotation *= simd_quatf(angle: rotAngle, axis: [1, 0, 0])
                    case .downArrow:
                        endTransform.rotation *= simd_quatf(angle: rotAngle, axis: [-1, 0, 0])
                    default:
                        endTransform.rotation = .init(angle: .zero, axis: [0, 1, 0])
//                        return
                    }
                    camAnchor.move(to: endTransform, relativeTo: nil, duration: 0.2)
                }
                .environmentObject(keyInputSubject)

        }
        .commands { CommandMenu("Input") {
            keyInput(.leftArrow)
            keyInput(.rightArrow)
            keyInput(.upArrow)
            keyInput(.downArrow)
            keyInput(.space)
            keyInput(.delete)
            keyInput(.escape)
            keyInput(.return)
        }}
    }
}

public func keyboardShortcut<Sender, Label>(
    _ key: KeyEquivalent,
    sender: Sender,
    modifiers: EventModifiers = .none,
    @ViewBuilder label: () -> Label
) -> some View where Label: View, Sender: Subject, Sender.Output == KeyEquivalent {
    Button(action: { sender.send(key) }, label: label)
        .keyboardShortcut(key, modifiers: modifiers)
}

public extension EventModifiers {
    static let none = Self()
}

private extension RTM_CollaboratARApp {
    func keyInput(_ key: KeyEquivalent, modifiers: EventModifiers = .none) -> some View {
        keyboardShortcut(key, sender: keyInputSubject, modifiers: modifiers, label: {})
    }
}


extension KeyEquivalent: Equatable {
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.character == rhs.character
    }
}

public typealias KeyInputSubject = PassthroughSubject<KeyEquivalent, Never>

public final class KeyInputSubjectWrapper: ObservableObject, Subject {
    public func send(_ value: Output) {
        objectWillChange.send(value)
    }

    public func send(completion: Subscribers.Completion<Failure>) {
        objectWillChange.send(completion: completion)
    }

    public func send(subscription: Subscription) {
        objectWillChange.send(subscription: subscription)
    }


    public typealias ObjectWillChangePublisher = KeyInputSubject
    public let objectWillChange: ObjectWillChangePublisher
    public init(subject: ObjectWillChangePublisher = .init()) {
        objectWillChange = subject
    }
}

// MARK: Publisher Conformance
public extension KeyInputSubjectWrapper {
    typealias Output = KeyInputSubject.Output
    typealias Failure = KeyInputSubject.Failure

    func receive<S>(subscriber: S) where S : Subscriber, S.Failure == Failure, S.Input == Output {
        objectWillChange.receive(subscriber: subscriber)
    }
}
