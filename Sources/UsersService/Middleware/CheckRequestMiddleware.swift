import Kitura
import LoggerAPI
import SwiftyJSON

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
                Log.error("request method \(request.method) doesn't match expectation")
                try response.send(json: JSON(["message": "request method \(request.method) doesn't match \(method)"]))
                            .status(.badRequest).end()
            }
        } catch {
            Log.error("failed to send response")
        }
    }
}
