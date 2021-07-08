//
//  CoachingOverlayView.swift
//  CollaboratAR (iOS)
//
//  Created by Max Cobb on 08/07/2021.
//

#if canImport(ARKit)
import ARKit

extension CustomARView: ARCoachingOverlayViewDelegate {
    func addCoaching() {
        // Create a ARCoachingOverlayView object
        let coachingOverlay = ARCoachingOverlayView()
        // Make sure it rescales if the device orientation changes
        coachingOverlay.autoresizingMask = [
            .flexibleWidth, .flexibleHeight
        ]
        self.addSubview(coachingOverlay)
        // Set the Augmented Reality goal
        coachingOverlay.goal = .horizontalPlane
        // Set the ARSession
        coachingOverlay.session = self.session
        // Activate
        coachingOverlay.setActive(true, animated: true)
    }
}
#endif
