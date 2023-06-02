# AV360

[![CI Status](https://img.shields.io/travis/sajidnawaz993/AV360.svg?style=flat)](https://travis-ci.org/sajidnawaz993@gmail.com/AV360)
[![Version](https://img.shields.io/cocoapods/v/AV360.svg?style=flat)](https://cocoapods.org/pods/AV360)
[![License](https://img.shields.io/cocoapods/l/AV360.svg?style=flat)](https://cocoapods.org/pods/AV360)
[![Platform](https://img.shields.io/cocoapods/p/AV360.svg?style=flat)](https://cocoapods.org/pods/AV360)

# iOS Example App

Barebones Swift iOS app showcasing basic ParticleSetup / Particle-SDK cocoapods usage / getting started.

Built using XCode 14.1 (Swift 5)

### How to run the example?

1. Clone this repo
1. Open shell window and navigate to project folder
1. Run `pod install`
1. Open `ios-app-particle-setup.xcworkspace` and run the project on selected device or simulator

### How was it created?

1. Open XCode. File->New->Project->Single View App->Your project name
1. Create Podfile with your target name, add pod 'AV360' in podfile and Particle pods reference (see file)
1. Close XCode Project
1. Open shell window and navigate to the project folder
1. Run `pod install` (make sure your have latest [Cocoapods](https://guides.cocoapods.org/using/getting-started.html#installation)  installed), pods will be installed and new XCode workspace file will be created.
1. in XCode open the new `<your project name>.xcworkspace`
1. Create the source code and storyboard for your app (see `ViewController.swift` and `Main.storyboard` for reference)
1. Build and run - works on simulator and device (no need to do any modifications to Keychain settings)
1. Click "Start setup" on the phone and onboard a new Photon to your account.

### Code

See ViewController requesting particle setup AV360 player with event id and bearer token.
.

To invoke setup:

```
let vc = PlayerVC.getPlayerVC(eventId: "6364efc88644b4cfc5bdafad", bearerToken: "")
self.present(vc, animated: true)

```

For questions - refer to Particle mobile knowledgebase/community here: https://community.particle.io/c/mobile

Good luck!

## Author

"Sajid Nawaz", sajidnawaz993@gmail.com

## License

AV360 is available under the MIT license. See the LICENSE file for more info.
