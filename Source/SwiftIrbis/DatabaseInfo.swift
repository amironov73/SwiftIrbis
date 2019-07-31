import Foundation

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
