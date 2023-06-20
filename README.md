# Amazon IVS Real-time for iOS Demo

A demo SwiftUI iPhone application intended as an educational tool to demonstrate how you can build a real-time collaborative live streaming experience with [Amazon IVS](https://www.ivs.rocks/).

<img src="app-screenshot.png" alt="A screenshot of the demo application running on an iPhone." />

**This project is intended for education purposes only and not for production usage.**

## Prerequisites

You must deploy the [Amazon IVS Real-time Serverless Demo](https://github.com/aws-samples/amazon-ivs-real-time-serverless-demo). After deploying the serverless demo, note the outputs: `QR code`, `Customer ID` and `API key`.

## Setup

1. Clone the repository to your local machine.
2. Install the SDK dependency using CocoaPods: `pod install`
3. Open `IVS Real-time.xcworkspace`.
4. Since iPhone simulators don't currently support the use of cameras in this app, there are a couple changes you need to make before building and running the app on a physical device.
   1. Have an active Apple Developer account in order to build to physical devices.
   2. Modify the Bundle Identifier for the `IVS Real-time` target.
   3. Choose a Team for the target.
5. You can now build and run the project on a device.
6. When prompted, scan the `QR code` from the [Amazon IVS Real-time Serverless Demo](https://github.com/aws-samples/amazon-ivs-real-time-serverless-demo).
   - If you are unable to scan the QR code, paste the combined `Customer ID` and `API key` in this format: `{Customer ID}-{API key}` when prompted in the app. For example: `a1bcde23456f7g-abcDeFghIQaTbTxd0T95`

**IMPORTANT NOTE:** Joining a stage and streaming in the app will create and consume AWS resources, which will cost money.

## Known Issues

- This app has only been tested on devices running iOS 15 or later. While this app may work on devices running older versions of iOS, it has not been tested on them.
- A list of known issues for the Amazon IVS Broadcast SDK is available on the following page: [Amazon IVS Broadcast SDK: iOS Guide](https://docs.aws.amazon.com/ivs/latest/userguide/broadcast-ios-issues.html)

## More Documentation

- [Amazon IVS iOS Broadcast SDK Guide](https://docs.aws.amazon.com/ivs/latest/userguide/broadcast-ios.html)
- [Amazon IVS iOS Broadcast SDK Sample code](https://github.com/aws-samples/amazon-ivs-broadcast-ios-sample)
- [More code samples and demos](https://www.ivs.rocks/examples)

## License

This project is licensed under the MIT-0 License. See the LICENSE file.
