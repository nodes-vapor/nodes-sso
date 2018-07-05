import Crypto
import Vapor

public struct AuthenticatedUser {
    public let email: String
    public let name: String
    public let imageUrl: String
}

public protocol NodesSSOAuthenticatable {
    static func authenticated(_ user: AuthenticatedUser, req: Request) -> Future<Response>
}

internal final class NodesSSOController<U: NodesSSOAuthenticatable> {
    internal func auth(_ req: Request) throws -> Response {
        let config: NodesSSOConfig = try req.make()
        let url = config.redirectURL + "?redirect_url=" + config.projectURL + config.callbackPath
        return req.redirect(to: url)
    }

    internal func callback(_ req: Request) throws -> Future<Response> {
        let config: NodesSSOConfig = try req.make()

        return try req
            .content
            .decode(Callback.self)
            .try { callback in
                let salt = config.salt.replacingOccurrences(of: "#email", with: callback.email)
                let expected = try SHA256.hash(salt).hexEncodedString()

                guard callback.token == expected else {
                    throw Abort(.unauthorized)
                }
            }
            .flatMap(to: Response.self) { callback in
                let user = AuthenticatedUser(
                    email: callback.email,
                    name: callback.name,
                    imageUrl: callback.image
                )
                return U.authenticated(user, req: req)
            }
    }
}

private extension NodesSSOController {
    struct Callback: Codable {
        let token: String
        let email: String
        let name: String
        let image: String
    }
}