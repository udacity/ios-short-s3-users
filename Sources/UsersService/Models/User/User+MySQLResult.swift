import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (User)

public extension MySQLResultProtocol {

    public func toUsers(pageSize: Int = 10) -> [User] {

        var usersDictionary = [String:User]()

        while case let row? = self.nextResult() {

            // Scan over rows with user.id
            if let id = row["id"] as? String {

                // Create new user entry if DNE
                if usersDictionary[id] == nil {
                    usersDictionary[id] = User()
                }

                usersDictionary[id]?.id = id
                usersDictionary[id]?.name = row["name"] as? String
                usersDictionary[id]?.location = row["location"] as? String
                usersDictionary[id]?.photoURL = row["photo_url"] as? String

                if let activityID = row["activity_id"] as? Int {
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

                if let createdAtString = row["created_at"] as? String,
                   let createdAt = dateFormatter.date(from: createdAtString) {
                       usersDictionary[id]?.createdAt = createdAt
                }

                if let updatedAtString = row["updated_at"] as? String,
                   let updatedAt = dateFormatter.date(from: updatedAtString) {
                       usersDictionary[id]?.updatedAt = updatedAt
                }
            } else {
                Log.error("user.id not found in \(row)")
            }

            // Return collection limited by page size if specified
            if pageSize > 0 && usersDictionary.count == Int(pageSize) {
                break
            }
        }

        return Array(usersDictionary.values)
    }
}
