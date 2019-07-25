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

class DatabaseInfo: CustomStringConvertible, CustomDebugStringConvertible {
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
    }
    
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
    }
    
    func parse(lines: [String]) {
        self.logicallyDeletedRecords = parseLine(line: lines[0])
        self.physicallyDeletedRecords = parseLine(line: lines[1])
        self.nonActualizedRecords = parseLine(line: lines[2])
        self.lockedRecords = parseLine(line: lines[3])
        self.maxMfn = parseInt32(lines[4])
        self.databaseLocked = parseInt32(lines[5]) != 0
    }
    
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
    }

    var description: String {
        return name
    }
    var debugDescription: String {
        return "DatabaseInfo(name: \(name))"
    }
}

