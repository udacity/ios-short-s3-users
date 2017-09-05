import Foundation
import SwiftyJSON
import LoggerAPI

// MARK: - User

public struct User {
    public var id: String?
    public var name: String?
    public var location: String?
    public var photoURL: String?
    public var favoriteActivities: [Int]?
    public var createdAt: Date?
    public var updatedAt: Date?
}

// MARK: - User: JSONAble

extension User: JSONAble {
    public func toJSON() -> JSON {
        var dict = [String: Any]()
        let nilValue: Any? = nil

        dict["id"] = id != nil ? id : nilValue
        dict["name"] = name != nil ? name : nilValue
        dict["location"] = location != nil ? location : nilValue
        dict["photo_url"] = photoURL != nil ? photoURL : nilValue
        dict["favorite_activities"] = favoriteActivities != nil ? favoriteActivities : nilValue

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        dict["created_at"] = createdAt != nil ? dateFormatter.string(from: createdAt!) : nilValue
        dict["updated_at"] = updatedAt != nil ? dateFormatter.string(from: updatedAt!) : nilValue

        return JSON(dict)
    }
}

// MARK: - User (MySQLRow)

extension User {
    func toMySQLRow() -> ([String: Any]) {
        var data = [String: Any]()
        
        data["id"] = id
        data["name"] = name
        data["location"] = location
        data["photo_url"] = photoURL
        data["favorite_activities"] = favoriteActivities

        return data
    }
}

// MARK: - User (Validate)

extension User {
    public func validateParameters(_ parameters: [String]) -> [String] {
        var missingParameters = [String]()
        let mirror = Mirror(reflecting: self)

        for (name, value) in mirror.children {
            guard let name = name, parameters.contains(name) else { continue }
            if "\(value)" == "nil" {
                missingParameters.append("\(name)")
            }
        }

        return missingParameters
    }
}
