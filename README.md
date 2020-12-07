# AppleSignin

Sign in with Apple wrapper.


# Use

```swift

// check sign in with apple available
guard AppleSignin.shared.available() else {
    return
}
// request login with call back delegate
// should be implement AppleSigninProtocol
AppleSignin.shared.request(delegate: self)


// -------
// get result from AppleSigninProtocol
func appleSigninDidComplete(token: String, authCode: String, user: String) {
    // do login action
}

func appleSigninDidError(_ error: AppleSigninError) {
    // handler error
}
```
