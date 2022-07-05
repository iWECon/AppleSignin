import AuthenticationServices

func DebugLog(_ value: String) {
    assert({ print("[Apple-Sign]: \(value)"); return true; }())
}


public enum AppleSigninError: Swift.Error {
    case canceled
    case failed(error: Error)
}

public protocol AppleSigninProtocol: NSObjectProtocol {
    
    func appleSigninComplete(token: String, authCode: String, user: String)
    
    func appleSigninFailure(_ error: AppleSigninError)
}

/// Sign in with Apple
/// step1: use available() to check service available status
/// step2: if available, then use request() start login
public class AppleSignin: NSObject {
    
    public typealias Complete = (_ token: String, _ authCode: String, _ user: String) -> Void
    public typealias Failure = (_ error: AppleSigninError) -> Void
    
    override init() {
        super.init()
    }
    
    public weak var delegate: AppleSigninProtocol?
    
    public static let shared = AppleSignin()
    
    private var completeCallback: Complete?
    private var failureCallback: Failure?
}

public extension AppleSignin {
    
    func available() -> Bool {
        #if os(iOS)
        guard #available(iOS 13.0, *) else {
            return false
        }
        #elseif os(macOS)
        guard #available(macOS 10.15, *) else {
            return false
        }
        #endif
        return true
    }
    
    func request(delegate: AppleSigninProtocol? = nil) {
        #if os(iOS)
        guard #available(iOS 13.0, *) else {
            return
        }
        #elseif os(macOS)
        guard #available(macOS 10.15, *) else {
            return
        }
        #endif
        self.delegate = delegate
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func request(complete: Complete?, failure: Failure?) {
        self.completeCallback = complete
        self.failureCallback = failure
        
        request(delegate: nil)
    }
    
    func prepareForReuse() {
        failureCallback = nil
        completeCallback = nil
        delegate = nil
    }
}

@available(iOS 13.0, macOS 10.15, *)
extension AppleSignin: ASAuthorizationControllerPresentationContextProviding {
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
    
}

@available(iOS 13.0, macOS 10.15, *)
extension AppleSignin: ASAuthorizationControllerDelegate {
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
        
        guard let identityToken = credential.identityToken else { return }
        
        guard let token = String(data: identityToken, encoding: .utf8) else { return }
        
        let tokenInfo = token.components(separatedBy: ".")
        guard tokenInfo.count >= 2 else {
            DebugLog("the identity decode failed.")
            return
        }
        let payload = tokenInfo[1]
        
        guard let payloadPart = decodeJWTPart(payload) else { return }
        guard let payloadUser = payloadPart["sub"] as? String, payloadUser == credential.user else {
            DebugLog("the PLAYLOAD.sub and CREDENTIAL.user do not match")
            return
        }
        
        // _ = authCode
        guard let authorizationCode = credential.authorizationCode, let authCode = String(data: authorizationCode, encoding: .utf8) else {
            DebugLog("auth code data decode to string failed.")
            return
        }
        
        if let didCompleteBlock = completeCallback {
            didCompleteBlock(token, authCode, payloadUser)
        } else {
            delegate?.appleSigninComplete(token: token, authCode: authCode, user: payloadUser)
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        let authorizationError = ASAuthorizationError(_nsError: error as NSError)
        
        switch authorizationError.code {
        case .canceled:
            if let didErrorBlock = failureCallback {
                didErrorBlock(.canceled)
            } else {
                delegate?.appleSigninFailure(.canceled)
            }
        default:
            if let didErrorBlock = failureCallback {
                didErrorBlock(.failed(error: error))
            } else {
                delegate?.appleSigninFailure(.failed(error: error))
            }
        }
    }
}

extension AppleSignin {
    
    private func base64UrlDecode(_ value: String) -> Data? {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
        let requiredLength = 4 * ceil(length / 4.0)
        let paddingLength = requiredLength - length
        if paddingLength > 0 {
            let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
            base64 += padding
        }
        return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
    }
    
    private func decodeJWTPart(_ value: String) -> [String: Any]? {
        guard let bodyData = base64UrlDecode(value) else {
            DebugLog("invalid base64 url")
            return nil
        }
        guard let json = try? JSONSerialization.jsonObject(with: bodyData, options: []), let payload = json as? [String: Any] else {
            DebugLog("invalid json")
            return nil
        }
        return payload
    }
    
}
