# fcl-auth-swift

`FCLAuthSwift` is a Swift library for the [Flow Client Library (FCL)](https://docs.onflow.org/fcl/) that enables Flow wallet authentication on iOS devices.

## Installation

This library is a Swift package that can be installed via Xcode with the URL of this repository:

`https://github.com/zed-io/fcl-auth-swift.git`

## Configuration

You will need to configure your app information before you use the authentication library:

```swift

import FCLAuthSwift

FCL.shared.config(
    app: FlowAppData(
        title: "FCL iOS Demo",
        icon: URL(string: "https://foo.com/bar.png")!
    ),
    // default providers are  [.dapper, .blocto]
    providers: [.dapper, .blocto, .custom(service)]
)
```

## Authenticate 

```swift
FCL.shared.authenticate(provider: .dapper) { result in
    switch result {
    case let .success(data):
        print(data)
    case let .failure(error):
        print(error)
    }
}
```

## Delegate

The authentication library has an optional delegate to handle custom events or settings. 

```swift
FCL.shared.delegate = self

public protocol FlowAuthDelegate {
    // Show loading while waiting for network response
    func showLoading()
    // Hide loading when api call is completed 
    func hideLoading()
}

extension FlowAuthDelegate {
    // Configure which place to show authentication webview
    // The default value is ASPresentationAnchor()
    func presentationAnchor() -> UIWindow {
        return ASPresentationAnchor()
    }
}
```
