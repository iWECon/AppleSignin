# AppleSignin

Sign in with Apple wrapper.


# Use

Check sign in with apple available status
```swift
// check sign in with apple available
guard AppleSignin.shared.available() else {
    return
}
```

Request sign
```swift

// rquest login with block and handler result
// the block priority more than delegate 
AppleSignin.shared.request(didComplete: DidComplete?, didError: DidError?)

// or request login with call back delegate
// should be implement AppleSigninProtocol
AppleSignin.shared.request(delegate: self)
```

Get the result from delegate
```swift
// get result from AppleSigninProtocol
func appleSigninDidComplete(token: String, authCode: String, user: String) {
// do login action
}
func appleSigninDidError(_ error: AppleSigninError) {
// handler error
}
```
