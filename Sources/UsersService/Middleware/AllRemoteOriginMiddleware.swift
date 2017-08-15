import Kitura

// MARK: - AllRemoteOriginMiddleware: RouterMiddleware

public class AllRemoteOriginMiddleware: RouterMiddleware {

    // MARK: Initializer

    public init() {}

    // MARK: RouterMiddleware
    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Swift.Void) {
        response.headers["Access-Control-Allow-Origin"] = "*"
        next()
    }
}
