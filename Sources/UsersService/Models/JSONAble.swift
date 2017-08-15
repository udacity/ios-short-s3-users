import Foundation
import SwiftyJSON

// MARK: - JSONAble

public protocol JSONAble {
    func toJSON() -> JSON
}

// MARK: - Array (Element: JSONAble)

public extension Array where Element: JSONAble {
    public func toJSON() -> JSON {
        var json = [JSON]()

        for element in self {
            json.append(element.toJSON())
        }

        return JSON(json)
    }
}
