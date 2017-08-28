import MySQL
import LoggerAPI
import Foundation

// MARK: - MySQLResultProtocol (User)

public extension MySQLResultProtocol {

    public func toUsers() -> [User] {

        var users = [User]()

        while case let row? = self.nextResult() {

            var user = User()

            user.id = row["id"] as? String
            user.name = row["name"] as? String
            user.location = row["location"] as? String
            user.photoURL = row["photo_url"] as? String

            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

            if let createdAtString = row["created_at"] as? String,
               let createdAt = dateFormatter.date(from: createdAtString) {
                   user.createdAt = createdAt
            }

            if let updatedAtString = row["updated_at"] as? String,
               let updatedAt = dateFormatter.date(from: updatedAtString) {
                   user.updatedAt = updatedAt
            }

            users.append(user)
        }

        return users
    }
}
