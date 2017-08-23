import Kitura
import LoggerAPI
import HeliumLogger
import Foundation
import UsersService
import MySQL

// Disable stdout buffering (so log will appear)
setbuf(stdout, nil)

// Init logger
HeliumLogger.use(.info)

// Create connection string (use env variables, if exists)
let env = ProcessInfo.processInfo.environment
var connectionString = MySQLConnectionString(host: env["MYSQL_HOST"] ?? "127.0.0.1")
connectionString.port = Int(env["MYSQL_PORT"] ?? "3306") ?? 3306
connectionString.user = env["MYSQL_USER"] ?? "root"
connectionString.password = env["MYSQL_PASSWORD"] ?? "password"
connectionString.database = env["MYSQL_DATABASE"] ?? "game_night"

// Create connection pool
let pool = MySQLConnectionPool(connectionString: connectionString, poolSize: 10, defaultCharset: "utf8mb4")

// Create data accessor (uses pool to get connections and access data!)
let dataAccessor = UserMySQLDataAccessor(pool: pool)

// Create AccountKit client
let accountKitClient = AccountKitClient(
    session: URLSession(configuration: URLSessionConfiguration.default),
    appID: env["FACEBOOK_APP_ID"] ?? "FACEBOOK_APP_ID",
    appSecret: env["ACCOUNT_KIT_APP_SECRET"] ?? "ACCOUNT_KIT_APP_SECRET"
)

// Create JWT composer
let jwtComposer = JWTComposer(privateKey: env["PRIVATE_KEY"] ?? "", publicKey: env["PUBLIC_KEY"] ?? "")

// Create handlers
let handlers = Handlers(dataAccessor: dataAccessor, accountKitClient: accountKitClient, jwtComposer: jwtComposer)

// Create router
let router = Router()

// Setup paths
router.all("/*", middleware: BodyParser())
router.all("/*", middleware: AllRemoteOriginMiddleware())
router.all("/*", middleware: LoggerMiddleware())
router.options("/*", handler: handlers.getOptions)

// GET
router.get("/*", middleware: CheckRequestMiddleware(method: .get))
router.get("/profile", handler: handlers.getProfile)
router.get("/logout", handler: handlers.logout)

// POST
router.post("/*", middleware: CheckRequestMiddleware(method: .post))
router.post("/login", handler: handlers.login)

// PUT
router.put("/*", middleware: CheckRequestMiddleware(method: .put))
router.put("/profile", handler: handlers.updateProfile)
router.put("/favorites", handler: handlers.updateFavorites)

// Add an HTTP server and connect it to the router
Kitura.addHTTPServer(onPort: 8080, with: router)

// Start the Kitura runloop (this call never returns)
Kitura.run()
