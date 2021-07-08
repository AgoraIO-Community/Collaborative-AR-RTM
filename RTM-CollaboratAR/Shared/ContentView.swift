//
//  ContentView.swift
//  Shared
//
//  Created by Max Cobb on 15/05/2021.
//

import SwiftUI
import RealityKit
import RealityUI
#if canImport(ARKit)
import ARKit
#endif

struct ContentView: View {
    @ObservedObject var sharedIntroEntry = CollaborationExpEntity.shared
    var body: some View {
        ZStack {
            ARViewInitial().ignoresSafeArea()
            VStack {
                HStack {
                    containedView().padding()
                    Spacer()
                }
                Spacer()
                if let selectedBox = sharedIntroEntry.selectedBox {
                    Button(action: {
                        sharedIntroEntry.removeCollabModel(selectedBox, sendUpdate: true)
                    }, label: {
                        Image(systemName: "trash")
                            .padding()
                            .background(Color.red).cornerRadius(7.0)
                    }).buttonStyle(PlainButtonStyle())
                }
                if sharedIntroEntry.showConfirm {
                    Button(action: {
                        sharedIntroEntry.showConfirm = false
                        sharedIntroEntry.collab?.positionSet()
                    }, label: {
                        Text("Confirm Position")
                            .padding()
                            .background(Color.green)
                            .cornerRadius(7.0)
                    }).buttonStyle(PlainButtonStyle())
                    .padding()
                }
                if sharedIntroEntry.showUSDZTray {
                    ScrollView(.horizontal, showsIndicators: /*@START_MENU_TOKEN@*/true/*@END_MENU_TOKEN@*/, content: {
                        HStack {
                            if let usdzGroup = sharedIntroEntry.usdzForRoom {
                            ForEach(0..<usdzGroup.count) { idx in
                                USDZPickerItem(
                                    usdzRoot: usdzGroup[idx], idx: idx, sharedIntroEntry: sharedIntroEntry)
                                    .frame(width: 100, height: 100, alignment: .center)
                            }
                        }
                        }
                        .padding(4)
//                        .padding()
                    })
                }
                if sharedIntroEntry.showDrawer {
                    JoinCollab(sharedIntroEntry: sharedIntroEntry)
                        .frame(height: 100, alignment: .bottom)
                }
            }
        }
    }
    func containedView() -> AnyView? {
        switch self.sharedIntroEntry.collabState {
        case .collab(_):
            return AnyView(Button(action: {
                self.sharedIntroEntry.setState(to: .globe)
            }, label: {
                Label("Back", systemImage: "globe")
                    .padding().background(Color.green)
                    .cornerRadius(7.0)
            }).buttonStyle(PlainButtonStyle()))
        case .globe:
            return AnyView(EmptyView())
        }
    }
}

#if os(macOS)
extension NSColor {
    static var systemBackground: NSColor = .windowBackgroundColor
}
#endif

struct JoinCollab: View {
    @EnvironmentObject private var keyInputSubjectWrapper: KeyInputSubjectWrapper

    @ObservedObject var sharedIntroEntry: CollaborationExpEntity
    var body: some View {
        VStack {
            Image(
                systemName: sharedIntroEntry.clickedChannelData?.systemImage
                    ?? sharedIntroEntry.roomStyles[sharedIntroEntry.roomStyle].systemName
            ).font(.system(size: 40)).scaledToFill().padding()
            if sharedIntroEntry.clickedChannelData?.channelID == "new" {
                Picker("Room Style", selection: $sharedIntroEntry.roomStyle) {
                    ForEach(0..<sharedIntroEntry.roomStyles.count) { idx in
                        Text(sharedIntroEntry.roomStyles[idx].displayname).tag(idx)
                    }
                }.pickerStyle(SegmentedPickerStyle())
            }
            Spacer()
            HStack {
                Spacer()
                Button(action: {
//                    CollaborationExpEntity.shared.showDrawer = false
                    sharedIntroEntry.clickedChannelData = nil
                }, label: {
                    Text("Cancel")
                        .frame(minWidth: 100).padding()
                        .background(Color.red).cornerRadius(7.0)
                }).buttonStyle(PlainButtonStyle())
                Spacer()
                Button(action: {
                    sharedIntroEntry.selectedUSDZ = 0
                    sharedIntroEntry.createChannel()
                }, label: {
                    Text(
                        sharedIntroEntry.isNewChannel ?
                            "Create" : "Join"
                    ).frame(minWidth: 100).padding().background(Color.green).cornerRadius(7.0)
                }).buttonStyle(PlainButtonStyle())
                Spacer()
            }
        }.padding().background(
            Color(.systemBackground)
        )
        .cornerRadius(15.0).ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

#if os(iOS)
typealias MPViewRep = UIViewRepresentable
#else
typealias MPViewRep = NSViewRepresentable
#endif

struct ARViewInitial: MPViewRep {
    func makeNSView(context: Context) -> CustomARView {
        self.makeUIView(context: context)
    }

    func updateNSView(_ nsView: CustomARView, context: Context) {
        self.updateUIView(nsView, context: context)
    }


    func makeUIView(context: Context) -> CustomARView {
        let custy = CustomARView()
        PeerDataComponent.registerComponent()
        CollabComponent.registerComponent()
        BoundingBoxComponent.registerComponent()
        CollaborationExpEntity.shared.arView = custy
        custy.positionEntities()
        defer {RealityUI.enableGestures(.tap, on: custy)}
        return custy
    }

    func updateUIView(_ uiView: CustomARView, context: Context) {
        // updated view
    }

    typealias NSViewType = CustomARView
    typealias UIViewType = CustomARView
}
