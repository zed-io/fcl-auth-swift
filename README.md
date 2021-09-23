# FlowAuthenticationService

The Flow Authentication Service is a Swift library for Flow (https://www.onflow.org).

## Authenticate 

```swift
import FlowAuthenticationService

FlowAuthentication.shared.authenticate { result in
    DispatchQueue.main.async {
        switch result {
        case let .success(data):
            self.address = data.address
        case let .failure(error):
            self.address = error.localizedDescription
        }
    }
}
```

## Delegate

The Authentication Service has optional delegate to handle custom events or settings. 

```swift
FlowAuthentication.shared.delegate = self

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
