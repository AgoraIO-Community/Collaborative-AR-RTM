# Multi-User Collaborative iOS AR Experiences with Agora (Part 1 of 2)

Agora is much more than a video streaming SDK. One other SDK available from Agora is the Real-time Messaging SDK.

The Agora Real-time messaging SDK can be used to send chunks of data across the network, including encoded structs, files, and plain text.

CollaboratAR is an example project where people can either join an active session or create a new one, located at a place of their choosing on a 3D globe floating in front of them. Once joined, users can add, modify, and remove objects from the scene, with updates sent to everyone else in the channel.

When joining a session, the users also join an audio channel using the Agora Audio SDK, so they can hear each other as well as see each other's location.

![macos ios transform example](media/transform-objects-both.gif)

This is what the session might look like from the macOS view, which does not have augmented reality:

![macOS VR Overview](media/vr-overview.png)

This post shows you how to use the app to connect with other people around the world. If you want to see how the app is made, go to the follow-up blog post here:

TODO: ADD LINK

## App Flow

On first launching the app, the user is instructed to find a horizontal surface that the globe will spawn from. After finding a good horizontal surface, the globe is spawned. Any active channels will appear on the globe in the form of red and orange circular targets.

The user can either select one of these targets to join a current room, or create a room by clicking elsewhere on the globe model.

![macos vr globe view](media/vr-globe-view.png)

![macos vr hitpoint](media/vr-globe-hitpoint.png)

After a user joins a channel, the following things will happen:

- The user will join an audio channel and can hear all other users who have their microphones connected.
- A collection of models appear at the bottom that the user can place in the scene.
- The locations of all remote users appear in the form of a translucent sphere and a visible microphone if their microphones are on.
- Any models that have already been placed into the scene will appear in the place set by other users.

![macos collab view closer](media/vr-closer-collabview.png)

The user can tap on their model of choice and then tap on the scene to place the model anywhere they like. Any placements of objects will be immediately shared with everyone else in the channel at the relevant location of the scene for them.

A user can select a model to delete, scale, rotate, or move it around the scene. These updates are sent across the network. On receiving the update, the local session will animate the object from the old transform to the new one.

## Technologies Used

- [Agora Real-time Messaging SDK](https://docs.agora.io/en/Real-time-Messaging/product_rtm?platform=iOS)
- [Agora Audio SDK](https://docs.agora.io/en/Voice/landing-page?platform=iOS)
- [RealityKit](https://developer.apple.com/documentation/realitykit)


## How It Works

To see how the sample app works, you can check out our in-depth blog post on how each part interacts with the Agora Real-time Messaging SDK as well as the Agora Audio SDK:

TODO: ADD LINK

The full source code is available here:

https://github.com/AgoraIO-Community/Collaborative-AR-RTM

## What You Can Do with This Technology

Using the techniques outlined in this project, you could create experiences for people to share ideas in augmented reality or virtual reality, as well as in 2D. Anything that someone does on their own device anywhere in the world could easily be represented in another user's experience using the Agora Real-time messaging SDK.

The same techniques could be used to make a multiplayer game, live interactive support, or something more basic, like a live chat feature.


## Other Resources <a name="other-resources"/>

For more information about building applications using the Agora Video and Audio Streaming SDKs, take a look at the[ Agora Video Call Quickstart Guide](https://docs.agora.io/en/Video/start_call_ios?platform=iOS&utm_source=medium&utm_medium=blog&utm_campaign=swiftpm) and the[ Agora API Reference](https://docs.agora.io/en/Video/API Reference/oc/docs/headers/Agora-Objective-C-API-Overview.html?utm_source=medium&utm_medium=blog&utm_campaign=swiftpm).

I also invite you to join the [Agora Developer Slack community](https://www.agora.io/en/join-slack/).

