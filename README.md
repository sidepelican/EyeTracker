# EyeTracker
[![Language](https://img.shields.io/badge/language-Swift%204.2.0-blue.svg)](https://swift.org)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/EyeTracker.svg?style=flat)](https://cocoapods.org/pods/EyeTracker)

Track gazing position 👀 with ARKit

![](https://user-images.githubusercontent.com/19257572/46901260-48464000-ceeb-11e8-8869-250cacd92f67.gif)

## Usage

See `EyeTrackerSample` for more details.

```swift
private let eyeTracker = EyeTracker()

override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)

    if EyeTracker.isSupported {
        eyeTracker.delegate = self
        eyeTracker.start()
    }
}

// MARK: - EyeTrackerDelegate

func eyeTracker(_ eyeTracker: EyeTracker, didUpdateTrackingState state: EyeTracker.TrackingState) {
    switch state {
    case .screenIn(let screenPos):
        // ...
    case .screenOut(let edge):
        // ...
    case .notTracked:
        // ...
    case .pausing:
        // ...
    }
}
```


## Installation
#### CocoaPods
You can use [CocoaPods](http://cocoapods.org/) to install `EyeTracker` by adding it to your `Podfile`:

```ruby
platform :ios, '12.0'
use_frameworks!
pod 'EyeTracker'
```

#### Carthage
Create a `Cartfile` that lists the framework and run `carthage bootstrap`. Follow the [instructions](https://github.com/Carthage/Carthage#if-youre-building-for-ios) to add `$(SRCROOT)/Carthage/Build/iOS/YourLibrary.framework` to an iOS project.

```
github "sidepelican/EyeTracker"
```

## License
MIT