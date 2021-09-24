# FlowAuthenticationService

The Flow Authentication Service is a Swift library for Flow (https://www.onflow.org).

## Installation

This is a Swift Package, and can be installed via Xcode with the URL of this repository:

`https://github.com/zed-io/FlowAuthenticationService.git`

## Config 
You will need to config the appinfo before you use the authentication service

```swift

import FlowAuthenticationService

FCL.shared.config(app: FlowAppData(title: "FCL Demo",
                                   icon: URL(string: "https://foo.com/bar.png")!),
                  // default provider is  [.dapper, .blocto]
                  providers: [.dapper, .blocto, .custom(service)])
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

The Authentication Service has optional delegate to handle custom events or settings. 

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
