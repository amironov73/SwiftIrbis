/*
 * ManagedClient ported to Swift 5.
 */

import Foundation

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

class ClientSocket {
    func talkToServer(query: ClientQuery) -> ServerResponse {
        return ServerResponse(connection: query.connection)
    }
} // class ClientSocket

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
