import AuthenticationServices

func DebugLog(_ value: String) {
    #if DEBUG
    print("[AppleSign]: \(value)")
    #endif
}


public enum AppleSigninError: Swift.Error {
    case canceled
    case failed(error: Error)
}

public protocol AppleSigninProtocol: NSObjectProtocol {
    
    func appleSigninDidComplete(token: String, authCode: String, user: String)
    
    func appleSigninDidError(_ error: AppleSigninError)
}

/// Sign in with Apple
/// step1: use available() to check service available status
/// step2: if available, then use request() start login
public class AppleSignin: NSObject {
    override init() {
        super.init()
    }
    
    public weak var delegate: AppleSigninProtocol?
    
    public static let shared = AppleSignin()
}

public extension AppleSignin {
    
    func available() -> Bool {
        guard #available(iOS 13.0, *) else {
            return false
        }
        return true
    }
    
    func request(delegate: AppleSigninProtocol?) {
        guard #available(iOS 13.0, *) else {
            return
        }
        self.delegate = delegate
        
        let request = ASAuthorizationAppleIDProvider().createRequest()
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
}
@available(iOS 13.0, *)
extension AppleSignin: ASAuthorizationControllerPresentationContextProviding {
    
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        ASPresentationAnchor()
    }
    
}

@available(iOS 13.0, *)
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
        
        delegate?.appleSigninDidComplete(token: token, authCode: authCode, user: payloadUser)
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        
        let authorizationError = ASAuthorizationError(_nsError: error as NSError)
        
        switch authorizationError.code {
        case .canceled:
            delegate?.appleSigninDidError(.canceled)
        default:
            delegate?.appleSigninDidError(.failed(error: error))
        }
        
//        switch authorizationError.code {
//        case .canceled:
//            break
//        case .failed, .invalidResponse, .notHandled, .unknown:
//            //Toast("认证失败，请重试", style: .alert).show()
//        default: // never call default
//            //Toast("AppleLogin erorr code: \(error.code)", style: .fatal).show()
//        }
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
