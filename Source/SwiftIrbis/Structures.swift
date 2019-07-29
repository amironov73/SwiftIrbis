import Foundation

//=========================================================
// File specification

/**
 * System path constants.
 */
enum IrbisPath : Int {
    case System = 0
    case Data = 1
    case Master = 2
    case Inverted = 3
    case Parameter = 10
    case Fulltext = 11
} // enum IrbisPath

/**
 * File specification.
 */
class FileSpecification {

    var path: Int
    var database: String
    var filename: String
    var content: String
    var binary: Bool
    
    init(path: Int, database: String, filename: String) {
        self.path = path
        self.database = database
        self.filename = filename
        self.content = ""
        self.binary = false
    } // init
    
    init(path: Int, filename: String) {
        self.path = path
        self.database = ""
        self.filename = filename
        self.content = ""
        self.binary = false
    } // init
    
    static func parse(text: String) -> FileSpecification {
        let parts = text.split(separator: " ", maxSplits: 3)
        let path = Int(parts[0])
        return FileSpecification(path: path!, database: String(parts[1]), filename: String(parts[2]))
    } // method parse
    
    func toString() -> String {
        return String(path) + "." + database + "." + filename
    } // method toString
    
} // class FileSpecification

//=========================================================
// Database info

class DatabaseInfo {

    var name: String
    var descriptionText: String
    var maxMfn: Int32
    var logicallyDeletedRecords: [Int32]
    var physicallyDeletedRecords: [Int32]
    var nonActualizedRecords: [Int32]
    var lockedRecords: [Int32]
    var databaseLocked: Bool
    var readOnly: Bool
    
    init() {
        self.name = ""
        self.descriptionText = ""
        self.maxMfn = 0
        self.logicallyDeletedRecords = []
        self.physicallyDeletedRecords = []
        self.nonActualizedRecords = []
        self.lockedRecords = []
        self.databaseLocked = false
        self.readOnly = false
    } // init
    
    func parseLine(line: String) -> [Int32] {
        var result: [Int32] = []
        let parts = line.split(separator: SHORT_DELIMITER_CHAR)
        for item in parts {
            if !item.isEmpty {
                let mfn = parseInt32(item)
                result.append(mfn)
            }
        }
        return result
    } // func parseLine
    
    func parse(lines: [String]) {
        self.logicallyDeletedRecords = parseLine(line: lines[0])
        self.physicallyDeletedRecords = parseLine(line: lines[1])
        self.nonActualizedRecords = parseLine(line: lines[2])
        self.lockedRecords = parseLine(line: lines[3])
        self.maxMfn = parseInt32(lines[4])
        self.databaseLocked = parseInt32(lines[5]) != 0
    } // func parse
    
    static func parseMenu(menu: MenuFile) -> [DatabaseInfo] {
        var result: [DatabaseInfo] = []
        for entry in menu.entries {
            var entryName = entry.code
            if entryName.isEmpty {
                break
            }
            let description = entry.comment
            var readOnly = false
            if (entryName.first! == "-") {
                entryName = subStr(entryName, 1, entryName.count - 1)
                readOnly = true
            }
            let db = DatabaseInfo()
            db.name = entryName
            db.descriptionText = description
            db.readOnly = readOnly
            result.append(db)
        }
        return result
    } // func parseMenu

    var description: String {
        return name
    } // var description

    var debugDescription: String {
        return "DatabaseInfo(name: \(name))"
    } // var debugDescription

} // class DatabaseInfo

//=========================================================
// Process info

/**
 * Information about server process.
 */
class ProcessInfo: CustomStringConvertible, CustomDebugStringConvertible {

    var number: String = "" // Just sequential number.
    var ipAddress: String = "" // Client IP address.
    var name: String = "" // User name.
    var clientId: String = "" // Client identifier.
    var workstation: String = "" // Workstation kind.
    var started: String = "" // Started at.
    var lastCommand: String = "" // Last executed command.
    var commandNumber: String = "" // Command number.
    var processId: String = "" // Process identifier.
    var state: String = "" // Process state.

    static func parse(_ lines: [String]) -> [ProcessInfo] {
        var result = [ProcessInfo]()
        if lines.isEmpty {
            return result
        }

        let processCount = Int(parseInt32(lines[0]))
        let linesPerProcess = Int(parseInt32(lines[1]))
        if processCount == 0 || linesPerProcess == 0 {
            return result
        }

        result.reserveCapacity(processCount)
        var shift = 2
        for _ in 1...processCount {
            let process = ProcessInfo()
            process.number = lines[shift + 0]
            process.ipAddress = lines[shift + 1]
            process.name = lines[shift + 2]
            process.clientId = lines[shift + 3]
            process.workstation = lines[shift + 4]
            process.started = lines[shift + 5]
            process.lastCommand = lines[shift + 6]
            process.commandNumber = lines[shift + 7]
            process.processId = lines[shift + 8]
            process.state = lines[shift + 9]
            result.append(process)
            shift += (linesPerProcess + 1)
        } // for

        return result
    } // func parse

    var description: String {
        return "\(number) \(ipAddress) \(name)"
    } // var description

    var debugDescription: String {
        return "ProcessInfo(number: \(number), ipAddress: \(ipAddress), name: \(name))"
    } // var debugDescription

} // class ProcessInfo

//=========================================================
// Version info

/**
 * Information about the IRBIS64 server version
 */
class VersionInfo {

    var organization: String = "";
    var version: String = "";
    var maxClients: Int32 = 0;
    var connectedClients: Int32 = 0;

    func parse(_ lines: [String]) {
        if (lines.count == 3) {
            self.version = lines[0]
            self.connectedClients = parseInt32(lines[1])
            self.maxClients = parseInt32(lines[2])
        } else {
            self.organization = lines[0]
            self.version = lines[1]
            self.connectedClients = parseInt32(lines[2])
            self.maxClients = parseInt32(lines[3])
        }
    } // func parse

} // class VersionInfo

//=========================================================
// Server statistics

/**
 * Information about connected client
 * (not necessarily current client).
 */
class ClientInfo: CustomStringConvertible, CustomDebugStringConvertible {

    var number: String = "" // Just sequential number.
    var ipAddress: String = "" // Client IP address.
    var port: String = "" // Port number.
    var name: String = "" // User login.
    var id: String = "" // Client identifier (just unique number).
    var workstation: String = "" // Client software kind.
    var registered: String = "" // Registration moment.
    var acknowledged: String = "" // Last acknowledge moment.
    var lastCommand: String = "" // Last command issued.
    var commandNumber: String = "" // Last command number.

    func parse(_ lines: [String], _ shift: Int) {
        self.number = lines[shift + 0]
        self.ipAddress = lines[shift + 1]
        self.port = lines[shift + 2]
        self.name = lines[shift + 3]
        self.id = lines[shift + 4]
        self.workstation = lines[shift + 5]
        self.registered = lines[shift + 6]
        self.acknowledged = lines[shift + 7]
        self.lastCommand = lines[shift + 8]
        self.commandNumber = lines[shift + 9]
    } // func parse

    var description: String {
        return self.ipAddress
    } // var description

    var debugDescription: String {
        return "ClientInfo(ipAddress: \(ipAddress))"
    } // var debugDescription

} // class ClientInfo

/**
 * IRBIS64 server working statistics.
 */
class ServerStat: CustomStringConvertible, CustomDebugStringConvertible {

    var runningClients: [ClientInfo] = [] // Array of running clients.
    var clientCount: Int32 = 0 // Actual client count.
    var totalCommandCount: Int32 = 0 // Total command count.

    func parse(_ lines: [String]) {
        self.totalCommandCount = parseInt32(lines[0])
        self.clientCount = parseInt32(lines[1])
        let linesPerClient = Int(parseInt32(lines[2]))
        var shift = 3
        for _ in 1...self.clientCount {
            let client = ClientInfo()
            client.parse(lines, shift)
            self.runningClients.append(client)
            shift += (linesPerClient + 1)
        }
    } // func parse

    var description: String {
        return "\(clientCount) \(totalCommandCount) \(runningClients)"
    } // var description

    var debugDescription: String {
        return "ServerStat(runningClients: \(runningClients), clientCount: \(clientCount), totalCommandCount: \(totalCommandCount))"
    } // var debugDescription

} // class ServerStat


