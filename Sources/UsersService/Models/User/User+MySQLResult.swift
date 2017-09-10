import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (User)

public extension MySQLResultProtocol {

    public func toUsers(pageSize: Int = 10) -> [User] {

        // Track unique users with a dictionary
        // Because of JOIN-based queries, user data can appear on multiple rows
        var usersDictionary = [String:User]()
        var row: MySQLRow? = nil
        var lastRowID: String? = nil

        // Get first row and track id
        row = self.nextResult()
        guard row != nil else {
            return Array(usersDictionary.values)
        }
        lastRowID = row!["id"] as? String

        while true {

            // Get row data
            let id = row!["id"] as! String

            // Create new user entry if DNE
            if usersDictionary[id] == nil {
                usersDictionary[id] = User()
            }

            usersDictionary[id]?.id = id
            usersDictionary[id]?.name = row!["name"] as? String
            usersDictionary[id]?.location = row!["location"] as? String
            usersDictionary[id]?.photoURL = row!["photo_url"] as? String

            if let activityID = row!["activity_id"] as? Int {
                // Create new activities array if DNE
                if usersDictionary[id]?.favoriteActivities == nil {
                    usersDictionary[id]?.favoriteActivities = [Int]()
                }
                // Append non-duplicate activities
                if usersDictionary[id]?.favoriteActivities?.contains(activityID) == false {
                    usersDictionary[id]?.favoriteActivities?.append(activityID)
                }
            }

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            if let createdAtString = row!["created_at"] as? String,
               let createdAt = dateFormatter.date(from: createdAtString) {
                   usersDictionary[id]?.createdAt = createdAt
            }

            if let updatedAtString = row!["updated_at"] as? String,
               let updatedAt = dateFormatter.date(from: updatedAtString) {
                   usersDictionary[id]?.updatedAt = updatedAt
            }

            // Get next row
            row = self.nextResult()
            guard row != nil else {
                break
            }

            // Return collection if the next row is a completely new record AND the page limit has been reached...
            let nextRowID = row!["id"] as? String
            if nextRowID != lastRowID && pageSize > 0 && usersDictionary.count == Int(pageSize) {
                break
            }

            // Track row id
            lastRowID = nextRowID
        }

        return Array(usersDictionary.values)
    }
}
