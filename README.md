# visionOS 2 Object Tracking Demo
visionOS 2 + Object Tracking + ARKit means: we can create visual highlights of real world objects around us and have those visualizations respond to the proximity of our hands.

This project is largely a quick repurposing and combining of Apple's [Scene Reconstruction sample project](https://developer.apple.com/documentation/visionos/incorporating-real-world-surroundings-in-an-immersive-experience) (which utilizes ARKit's `HandTrackingProvider`) and [Object Tracking sample project](https://developer.apple.com/documentation/visionos/exploring_object_tracking_with_arkit).

The full demo video with sound is [here](https://youtu.be/kiSOmFVfNpc).

Some details about putting together this demo are over [here](https://vision.engineer/posts/object-tracking-in-visionOS-2/).

## Build Instructions
1. Choose your Apple Developer Account in: Signing & Capabilities
1. Build

## Models Used in This Project
I live in Chicago and purchased the cereal and milk at a local Jewel in June 2024 – your local packaging may vary and prevent recognition. The three products used are:
1. [Cap'n Crunch (Large Size)](https://www.thefreshgrocer.com/sm/pickup/rsid/2000/product/capn-crunch-sweetened-corn-&-oat-cereal-large-size-18-oz-id-00030000573242/)
1. [Fairlife 2%](https://fairlife.com/ultra-filtered-milk/reduced-fat-2-percent-milk/)
1. [Lodge Dutch Oven](https://www.lodgecastiron.com/product/enameled-dutch-oven?sku=EC6D33)

## Using Your Own Models
If you want to strip out the three bundled objects and use your own:
1. You will need to train on a `.udsz` file to create a `.referenceObject`, I recommend using Apple's [Object Capture sample project](https://developer.apple.com/documentation/realitykit/guided-capture-sample) to create a `.usdz` file of your object
1. You will need to use Create ML (version 6, or higher, which comes bundled with Xcode 16) to train a `.referenceObject` from your `.usdz`, for me this process has taken anywhere from 4 - 16 hours per `.referenceObject`
1. You will need to bundle your new `.referenceObject` in the Xcode project
1. You will need to coordinate the naming of your new `.referenceObject` with the demo's `ObjectType` enum so everything plays nicely together

![visionOS 2 Object Tracking Demo Clip](https://github.com/robomex/visionOS-2-Object-Tracking-Demo/assets/2218937/ea1ec6c7-5311-4de5-af3c-f7f8eefa3dce)
