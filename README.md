# FCLAuthSwift

`FCLAuthSwift` is a Swift library for the [Flow Client Library (FCL)](https://docs.onflow.org/fcl/)
that enables Flow wallet authentication on iOS devices.

## Installation

- [Swift Package Manager](https://swift.org/package-manager/):

```swift
dependencies: [
  .package(url: "https://github.com/zed-io/fcl-auth-swift.git", from: "0.0.3-beta")
]
```

## Configuration

You will need to configure your app information before using the authentication library.

`FCLAuthSwift` ships with several built-in wallet providers (Dapper, Blocto),
but you can also define custom wallet providers if needed.

```swift
import FCLAuthSwift

// optional: define a custom wallet provider
let provider = FCLWalletProvider(
    id: "foo",
    name: "bar",
    method: .httpPost,
    endpoint: URL(string: "https://foo.com/api/")!
)
        
FCL.shared.config(
    appInfo: FCLAppInfo(
        title: "FCL iOS Demo",
        icon: URL(string: "https://foo.com/bar.png")!
    ),
    // default providers are [.dapper, .blocto]
    providers: [.dapper, .blocto, .custom(provider)]
)
```

## Authenticate 

```swift
FCL.shared.authenticate(provider: .dapper) { result in
    switch result {
    case let .success(data):
        print(data.address)
    case let .failure(error):
        print(error)
    }
}
```

The `data` variable is of type `FCLAuthnResponse`, which contains the user's wallet address:

```swift
public struct FCLAuthnResponse: Decodable {
    public let address: String
}
```

## Delegate

The authentication library has an optional delegate to handle custom events or settings. 

```swift
FCL.shared.delegate = self

public protocol FCLAuthDelegate {
    // Show loading while waiting for network response
    func showLoading()
    // Hide loading when API call is completed 
    func hideLoading()
}

extension FCLAuthDelegate {
    // Configure which place to show authentication webview
    // The default value is ASPresentationAnchor()
    func presentationAnchor() -> UIWindow {
        return ASPresentationAnchor()
    }
}
```
