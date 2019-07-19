/*
 * ManagedClient ported to Swift 5.
 */

import Foundation

//=========================================================
// Constants

// Record status

let LOGICALLY_DELETED  = 1  // Logically deleted record
let PHYSICALLY_DELETED = 2  // Physically deleted record
let ABSENT             = 4  // Record is absent
let NON_ACTUALIZED     = 8  // Record is not actualized
let LAST_VERSION       = 32 // Last version of the record
let LOCKED_RECORD      = 64 // The record is locked

// Common formats

let ALL_FORMAT       = "&uf('+0')" // Full data by all the fields
let BRIEF_FORMAT     = "@brief"    // Short bibliographical description
let IBIS_FORMAT      = "@ibisw_h"  // Old IBIS format
let INFO_FORMAT      = "@info_w"   // Informational format
let OPTIMIZED_FORMAT = "@"         // Optimized format

// Common search prefixes

let KEYWORD_PREFIX    = "K="  // Keywords
let AUTHOR_PREFIX     = "A="  // Individual author, editor, compiler
let COLLECTIVE_PREFIX = "M="  // Collective author or event
let TITLE_PREFIX      = "T="  // Title
let INVENTORY_PREFIX  = "IN=" // Inventory number, barcode or RFID tag
let INDEX_PREFIX      = "I="  // Document index

// Logical operators for search
let LOGIC_OR                = 0 // OR only
let LOGIC_OR_AND            = 1 // OR or AND
let LOGIC_OR_AND_NOT        = 2 // OR, AND or NOT (default)
let LOGIC_OR_AND_NOT_FIELD  = 3 // OR, AND, NOT, AND in field
let LOGIC_OR_AND_NOT_PHRASE = 4 // OR, AND, NOT, AND in field, AND in phrase

// Workstation codes

let ADMINISTRATOR = "A"
let CATALOGER     = "C"
let ACQUISITIONS  = "M"
let READER        = "R"
let CIRCULATION   = "B"
let BOOKLAND      = "B"
let PROVISION     = "K"

// Commands for global correction

let ADD_FIELD        = "ADD"    // Add field
let DELETE_FIELD     = "DEL"    // Delete field
let REPLACE_FIELD    = "REP"    // Replace field
let CHANGE_FIELD     = "CHA"    // Change field value
let CHANGE_WITH_CASE = "CHAC"   // Change field value with case sensitivity
let DELETE_RECORD    = "DELR"   // Delete record
let UNDELETE_RECORD  = "UNDELR" // Recover (undelete) record
let CORRECT_RECORD   = "CORREC" // Correct record
let CREATE_RECORD    = "NEWMFN" // Create new record
let EMPTY_RECORD     = "EMPTY"  // Empty the record
let UNDO_RECORD      = "UNDOR"  // Revert the record to previous version
let GBL_END          = "END"    // Closing operator bracket
let GBL_IF           = "IF"     // Conditional statement start
let GBL_FI           = "FI"     // Conditional statement end
let GBL_ALL          = "ALL"    // All
let GBL_REPEAT       = "REPEAT" // Repeat operator
let GBL_UNTIL        = "UNTIL"  // Until condition
let PUTLOG           = "PUTLOG" // Save logs to file

// Line delimiters

let IRBIS_DELIMITER = "\u{1F}\u{1E}" // IRBIS line delimiter
let SHORT_DELIMITER = "\u{1E}"       // Short version of line delimiter
let ALT_DELIMITER   = "\u{1F}"       // Alternative version of line delimiter
let UNIX_DELIMITER  = "\n"           // Standard UNIX line delimiter

//=========================================================
// Subfield

/**
 * MARC record subfield.
 */
class SubField {
    var code: Character
    var value: String

    init() {
        self.code = "\0"
        self.value = ""
    }

    init(code: Character, value: String) {
        self.code = code
        self.value = value
    }

} // class SubField

//=========================================================
// Record field

class RecordField {
    var tag: Int
    var value: String
    var subfields: [SubField]

    init() {
        self.tag = 0
        self.value = ""
        self.subfields = []
    }

    init(tag: Int, value: String) {
        self.tag = tag
        self.value = value
        self.subfields = []
    }

    func add(code: Character, value: String) -> RecordField {
        let subfield = SubField(code: code, value: value)
        self.subfields.append(subfield)
        return self
    }

    func addNonEmpty(code: Character, value: String) -> RecordField {
        if !value.isEmpty {
            let subfield = SubField(code: code, value: value)
            self.subfields.append(subfield)
        }
        return self
    }

    func clear() -> RecordField {
        self.subfields.removeAll()
        return self
    }

} // class RecordField

//=========================================================
// MARC record

class MarcRecord {
    var database: String = ""
    var mfn: Int = 0
    var status: Int = 0
    var version: Int = 0
    var fields: [RecordField] = []

    func addField(tag: Int, value: String) -> MarcRecord {
        let field = RecordField(tag: tag, value: value)
        self.fields.append(field)
        return self;
    }

    func clear() -> MarcRecord {
        self.fields.removeAll()
        return self
    }

} // class MarcRecord

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
// Menus

class MenuEntry {
    var code: String
    var comment: String

    init(code: String, comment: String) {
        self.code = code
        self.comment = comment
    }
} // class MenuEntry

class MenuFile {
    var entries: [MenuEntry] = []

    func append(code: String, comment: String) -> MenuFile {
        let entry = MenuEntry(code: code, comment: comment)
        self.entries.append(entry)
        return self
    }

    func clear() -> MenuFile {
        self.entries = []
        return self
    }

} // class MenuFile

//=========================================================
// INI-file

class IniLine {
    var key: String
    var value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
} // class IniLine

class IniSection {
    var name: String
    var lines: [IniLine]

    init(name: String) {
        self.name = name
        self.lines = []
    }
} // class IniSection

class IniFile {
    var sections: [IniSection]

    init() {
        self.sections = []
    }
} // class IniFile

//=========================================================
// TRE-file

class TreeNode {
    var children: [TreeNode]
    var value: String
    var level: Int

    init(value: String) {
        self.value = value
        self.children = []
        self.level = 0
    }
} // class TreeNode

class TreeFile {
    var roots: [TreeNode]

    init() {
        roots = []
    }
} // class TreeFile

//=========================================================
// Client query

class ClientQuery {
    var connection: Connection
    var command: String

    init(connection: Connection, command: String) {
        self.connection = connection
        self.command = command
    }

    func add(number: Int) -> ClientQuery {
        return self
    }

    func addAnsi(text: String) -> ClientQuery {
        return self
    }

    func addUtf(text: String) -> ClientQuery {
        return self
    }

    func newLine() {
        // return self
    }

} // class ClientQuery

//=========================================================
// Client socket

class ClientSocket {
    func talkToServer(query: ClientQuery) -> ServerResponse {
        return ServerResponse(connection: query.connection)
    }
} // class ClientSocket

//=========================================================
// Server response

class ServerResponse {
    var command: String = ""
    var clientId: Int = 0
    var queryId: Int = 0
    var returnCode: Int = 0
    var answerSize: Int = 0
    var serverVersion: String = ""
    var interval: Int = 0
    var ok: Bool = false

    var connection: Connection

    init(connection: Connection) {
        self.connection = connection
    }

    func checkReturnCode() -> Bool {
        return false
    }

    func getReturnCode() -> Int {
        return 0
    }

    func readAnsi() -> String {
        return ""
    }

    func readInteger() -> Int {
        return 0
    }

    func readRemainingAnsiLines() -> [String] {
        return []
    }

    func readRemainingAnsiText() -> String {
        return ""
    }

    func readRemainingUtfLines() -> [String] {
        return []
    }

    func readRemainingUtfText() -> String {
        return ""
    }

    func readUtf() -> String {
        return ""
    }

} // class ServerResponse

//=========================================================
// Server connection

class Connection {
    var host: String = "127.0.0.1"
    var port: Int = 6666
    var username: String = ""
    var password: String = ""
    var database: String = "IBIS"
    var workstation: Character = "C"
    var clientId: Int = 0
    var queryId: Int = 0
    var connected: Bool = false
    var lastError: Int = 0
    var serverVersion: String = ""
    var interval: Int = 0
    var socket: ClientSocket = ClientSocket()

    func actualizeDatabase(database: String) -> Bool {
        return actualizeRecord(database: database, mfn: 0)
    } // func actualizeDatabase

    func actualizeRecord(database: String, mfn: Int) -> Bool {
        if !self.connected {
            return false
        }

        let query = ClientQuery(connection: self, command: "F")
        query.addAnsi(text: database).newLine()
        query.add(number: mfn).newLine()
        let response = self.execute(query: query)
        return response.ok && response.checkReturnCode()
    } // func actualizeRecord

    func connect() -> Bool {
        if self.connected {
            return true
        }

        self.clientId = Int.random(in: 100_000...999_999)
        self.queryId = 1
        let query = ClientQuery(connection: self, command: "A")
        query.addAnsi(text: self.username).newLine()
        query.addAnsi(text: self.password)
        let response = self.execute(query: query)
        if !response.ok {
            return false
        }

        response.getReturnCode()
        if response.returnCode == -3337 {
            // TODO
        }

        if response.returnCode < 0 {
            return false
        }

        self.connected = true
        self.serverVersion = response.serverVersion
        self.interval = response.interval

        // TODO

        return false
    } // func connect

    func disconnect() -> Bool {
        if !self.connected {
            return true
        }

        let query = ClientQuery(connection: self, command: "B")
        query.addAnsi(text: self.username)
        self.execute(query: query)

        self.connected = false
        return true
    } // func disconnect

    func execute(query: ClientQuery) -> ServerResponse {
        self.lastError = 0
        self.queryId += 1

        return self.socket.talkToServer(query: query)
    } // func execute

    func getMaxMfn(database: String) -> Int {
        if !self.connected {
            return 0
        }

        let query = ClientQuery(connection: self, command: "O")
        query.addAnsi(text: database)
        let response = self.execute(query: query)
        if !response.ok || !response.checkReturnCode() {
            return 0
        }

        return response.returnCode
    } // func getMaxMfn

    func noOp() -> Bool {
        if !self.connected {
            return false
        }

        let query = ClientQuery(connection: self, command: "N")
        return self.execute(query: query).ok
    } // func noOp

} // class Connection

let client = Connection()
client.host = "localhost"
client.username = "librarian"
client.password = "secret"

if !client.connect() {
    print("Can't connect!")
    exit(1)
}

print("Server version=\(client.serverVersion)")
print("Interval=\(client.interval)")

let maxMfn = client.getMaxMfn(database: "IBIS")
print("Max MFN=\(maxMfn)")

client.noOp()
print("NOP")

client.disconnect()

print("THAT'S ALL FOLKS!")
