import Kitura
import LoggerAPI

// MARK: - CheckRequestMiddleware: RouterMiddleware

public class CheckRequestMiddleware: RouterMiddleware {

    // MARK: Properties

    let method: RouterMethod

    // MARK: Initializer

    public init(method: RouterMethod) {
        self.method = method
    }

    // MARK: RouterMiddleware

    public func handle(request: RouterRequest, response: RouterResponse, next: @escaping () -> Swift.Void) {
        do {
            if request.method == method {
                next()
            } else {
                Log.error("Request method \(request.method) doesn't match expectation")
                try response.status(.badRequest).end()
            }
        } catch {
            Log.error("Failed to send response")
        }
    }
}
