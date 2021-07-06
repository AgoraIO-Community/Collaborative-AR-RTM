//
//  USDZPickerItem.swift
//  RTM-CollaboratAR
//
//  Created by Max Cobb on 21/06/2021.
//

import QuickLookThumbnailing
import SwiftUI

struct USDZPickerItem: View {
    let placeholder = Image(systemName: "photo")
    @State var thumbnailImage: Image?
    var usdzRoot: String
    var idx: Int
    @ObservedObject var sharedIntroEntry: CollaborationExpEntity
    var body: some View {
        Button(action: {
            sharedIntroEntry.selectedUSDZ = idx
        }, label: {
            VStack {
                self.thumbnailImage ?? self.placeholder
            }.onAppear(perform: {
                self.generateThumbnail(for: usdzRoot, withExtension: "usdz", size: CGSize(width: 100, height: 100))
            })
        })
        .buttonStyle(PlainButtonStyle())
        .background(Color.gray)
        .cornerRadius(7.0)
        .overlay(
            RoundedRectangle(cornerRadius: 7.0, style: .continuous)
                .stroke(sharedIntroEntry.selectedUSDZ == idx ? Color.green : Color.clear, lineWidth: 3)
        )

    }
    func generateThumbnail(for resource: String, withExtension ext: String, size: CGSize) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: ext) else {
            return
        }
        #if os(iOS)
        let scale = UIScreen.main.scale
        #else
        let scale = NSScreen.main!.backingScaleFactor
        #endif

        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: scale, representationTypes: .thumbnail)
        QLThumbnailGenerator.shared.generateRepresentations(for: request) { thumbnailRep, repType, err in
            DispatchQueue.main.async {
                guard let thumbnail = thumbnailRep, err == nil else {
                    print("error generating thumbnail: \(err?.localizedDescription ?? "no error")")
                    return
                }
                #if os(iOS)
                self.thumbnailImage = Image(uiImage: thumbnail.uiImage)
                #else
                self.thumbnailImage = Image(nsImage: thumbnail.nsImage).resizable()
                #endif
            }
        }
    }
}
