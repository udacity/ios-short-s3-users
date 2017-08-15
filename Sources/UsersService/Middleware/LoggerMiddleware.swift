import Kitura
import LoggerAPI

// MARK: - LoggerMiddleware: RouterMiddleware

public class LoggerMiddleware: RouterMiddleware {

    // MARK: Initializer

    public init() {}

    // MARK: RouterMiddleware

    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Swift.Void) {
        Log.info("\(request.hostname) requested \(request.urlURL.absoluteString) -X \(request.method)")
        Log.verbose("url parameters: \(request.parameters)")
        Log.verbose("query parameters: \(request.queryParameters)")
        Log.verbose("body parameters: \(String(describing: request.body))")
        next()
    }
}
