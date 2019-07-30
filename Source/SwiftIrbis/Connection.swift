import Foundation

//=========================================================
// Client query

class ClientQuery {
    var connection: Connection
    var command: String
    private var buffer: Data
    
    init(_ connection: Connection, command: String) {
        self.connection = connection
        self.command = command
        self.buffer = Data()
        self.buffer.reserveCapacity(1024)
        
        self.addAnsi(command).newLine()
        self.addAnsi(connection.workstation).newLine()
        self.addAnsi(command).newLine()
        self.add(connection.clientId).newLine()
        self.add(connection.queryId).newLine()
        self.addAnsi(connection.password).newLine()
        self.addAnsi(connection.username).newLine()
        self.newLine()
        self.newLine()
        self.newLine()
        self.stop()
    } // init
    
    func add(_ number: Int32) -> ClientQuery {
        return self.addAnsi(String(number))
    } // func add
    
    func addAnsi(_ text: String) -> ClientQuery {
        self.buffer.append(toAnsi(text))
        return self
    } // func addAnsi

    /**
     * Add format specification.
     */
    func addFormat(_ text: String) -> Bool {
        let stripped = trim(text)

        if stripped.isEmpty {
            self.newLine()
            return false
        }

        let prepared = prepareFormat(format: text)
        if prepared.isEmpty {
            self.newLine()
            return false
        }

        if prepared.first! == "@" {
            _ = self.addAnsi(prepared)
        } else if prepared.first! == "!" {
            _ = self.addUtf(prepared)
        } else {
            _ = self.addUtf("!").addUtf(prepared)
        }
        self.newLine()
        return true
    } // func addFormat
    
    func addUtf(_ text: String) -> ClientQuery {
        self.buffer.append(toUtf(text))
        return self
    } // func addUtf

    func encode() -> Data {
        let prefix = "\(buffer.count)\n"
        self.buffer.insert(contentsOf: toAnsi(prefix), at: 0)
        let result = self.buffer
        return result
    } // func encode
    
    func newLine() {
        self.buffer.append(UInt8(10))
    } // func newLine
    
    func stop() {
        // Nothing to do here
    } // func stop
    
} // class ClientQuery

//=========================================================
// Client socket

class ClientSocket {

    func talkToServer(query: ClientQuery) -> ServerResponse {
        let connection = query.connection
        let client = TcpClient(host: connection.host, port: connection.port)
        client.connect()
        let outputData = query.encode()
        let outputPacket = Array(outputData)
        client.send(packet: outputPacket)
        let inputPacket = client.receive()
        client.close()
        let result = ServerResponse(inputPacket)
        return result
    } // func talkToServer

} // class ClientSocket

//=========================================================
// Server response

class ServerResponse {
    var command: String = ""
    var clientId: Int32 = 0
    var queryId: Int32 = 0
    var returnCode: Int32 = 0
    var answerSize: Int32 = 0
    var serverVersion: String = ""
    var interval: Int32 = 0
    var ok: Bool = false
    
    var connection: Connection?
    var buffer: Data
    var offset: Int
    
    init(_ buffer: Data) {
        self.buffer = buffer
        self.ok = !buffer.isEmpty
        self.offset = 0

        if (self.ok) {
            self.command = readAnsi() ?? ""
            self.clientId = readInteger()
            self.queryId = readInteger()
            self.answerSize = readInteger()
            self.serverVersion = readAnsi() ?? ""
            self.interval = readInteger()
            _ = readAnsi()
            _ = readAnsi()
            _ = readAnsi()
            _ = readAnsi()
        }
    } // init

    func eof() -> Bool {
        return self.offset >= self.buffer.count
    } // func eof

    func checkReturnCode() -> Bool {
        if getReturnCode() < 0 {
            return false // TODO check for allowed codes
        }
        return true
    } // func checkReturnCode

    func findPreamble(preamble: Data) -> Data? {
        return nil // TODO implement
    } // func getPreamble

    func getLine() -> Data? {
        if self.offset >= self.buffer.count {
            return nil
        }

        var result = Data()
        while self.offset < self.buffer.count {
            let symbol = self.buffer[self.offset]
            self.offset += 1
            if symbol == 13 {
                if self.buffer[offset] == 10 {
                    self.offset += 1
                }
                break
            }
            result.append(symbol)
        }
        return result
    } // func getLine

    func getReturnCode() -> Int32 {
        self.returnCode = readInteger()
        self.connection?.lastError = self.returnCode
        return self.returnCode
    } // func getReturnCode
    
    func readAnsi() -> String? {
        let line = getLine()
        guard let text = line else {
            return nil
        }
        return fromAnsi(text)
    } // func readAnsi
    
    func readInteger() -> Int32 {
        let line = readAnsi()
        guard let text = line else {
            return 0
        }
        return parseInt32(text)
    } // func readInteger
    
    func readRemainingAnsiLines() -> [String] {
        var result = [String]()
        while (true) {
            let text = self.readAnsi()
            if let line = text {
                result.append(line)
            } else {
                break
            }
        }
        return result
    } // func readRemainingAnsiLines
    
    func readRemainingAnsiText() -> String {
        return ""
    } // func readRemainingAnsiText
    
    func readRemainingUtfLines() -> [String] {
        var result = [String]()
        while (true) {
            let text = self.readUtf()
            if let line = text {
                result.append(line)
            } else {
                break
            }
        }
        return result
    } // func readRemainingUtfLines
    
    func readRemainingUtfText() -> String {
        return ""
    } // func readRemainingUtfText
    
    func readUtf() -> String? {
        let line = getLine()
        guard let text = line else {
            return nil
        }
        return fromUtf(text)
    } // func readUtf
    
} // class ServerResponse

//=========================================================
// Server connection

class Connection {
    var host: String = "127.0.0.1"
    var port: UInt16 = 6666
    var username: String = ""
    var password: String = ""
    var database: String = "IBIS"
    var workstation: String = "C"
    var clientId: Int32 = 0
    var queryId: Int32 = 0
    var connected: Bool = false
    var lastError: Int32 = 0
    var serverVersion: String = ""
    var interval: Int32 = 0
    var socket: ClientSocket = ClientSocket()
    
    func actualizeDatabase(database: String) -> Bool {
        return actualizeRecord(database: database, mfn: 0)
    } // func actualizeDatabase
    
    func actualizeRecord(database: String, mfn: Int32) -> Bool {
        if !self.connected {
            return false
        }
        
        let query = ClientQuery(self, command: "F")
        query.addAnsi(database).newLine()
        query.add(mfn).newLine()
        let response = self.execute(query)
        return response.ok && response.checkReturnCode()
    } // func actualizeRecord
    
    func connect() -> Bool {
        if self.connected {
            return true
        }
        
        self.clientId = Int32.random(in: 100_000...999_999)
        self.queryId = 1
        let query = ClientQuery(self, command: "A")
        query.addAnsi(self.username).newLine()
        query.addAnsi(self.password).stop()
        let response = self.execute(query)
        if !response.ok {
            return false
        }
        
        _ = response.getReturnCode()
        if response.returnCode == -3337 {
            // TODO
        }
        
        if response.returnCode < 0 {
            return false
        }
        
        self.connected = true
        self.serverVersion = response.serverVersion
        self.interval = response.readInteger()
        
        // TODO
        
        return true
    } // func connect
    
    func disconnect() -> Bool {
        if !self.connected {
            return true
        }
        
        let query = ClientQuery(self, command: "B")
        query.addAnsi(self.username).stop()
        _ = self.execute(query)
        
        self.connected = false
        return true
    } // func disconnect
    
    func execute(_ query: ClientQuery) -> ServerResponse {
        self.lastError = 0
        self.queryId += 1
        
        return self.socket.talkToServer(query: query)
    } // func execute
    
    func getMaxMfn(database: String) -> Int32 {
        if !self.connected {
            return 0
        }
        
        let query = ClientQuery(self, command: "O")
        query.addAnsi(database).stop()
        let response = self.execute(query)
        if !response.ok || !response.checkReturnCode() {
            return 0
        }
        
        return response.returnCode
    } // func getMaxMfn

    func getServerStat() -> ServerStat {
        let result = ServerStat()
        if self.connected {
            let query = ClientQuery(self, command: "+1")
            let response = self.execute(query)
            if response.ok && response.checkReturnCode() {
                let lines = response.readRemainingAnsiLines()
                result.parse(lines)
            }
        }
        return result
    } // func getServerStat

    func getServerVersion() -> VersionInfo {
        let result = VersionInfo()
        if self.connected {
            let query = ClientQuery(self, command: "1")
            let response = self.execute(query)
            if response.ok && response.checkReturnCode() {
                let lines = response.readRemainingAnsiLines()
                result.parse(lines)
            }
        }
        return result
    } // func getServerVersion

    func listFiles(_ specifications: String...) -> [String] {
        var result = [String]()
        if !self.connected || specifications.isEmpty {
            return result
        }

        let query = ClientQuery(self, command: "!")
        for item in specifications {
            if !item.isEmpty {
                query.addAnsi(item).newLine()
            }
        } // for
        let response = self.execute(query)
        if !response.ok {
            return result
        }
        let lines = response.readRemainingAnsiLines()
        for line in lines {
            let files = irbisToLines(line)
            for file in files {
                let lowercased = file.lowercased()
                if !file.isEmpty && !result.contains(lowercased) {
                    result.append(lowercased)
                }
            } // for
        } // for
        return result
    } // func listFiles

    /**
     * Get the server process list.
     */
    func listProcesses() -> [ProcessInfo] {
        var result = [ProcessInfo]()
        if self.connected {
            let query = ClientQuery(self, command: "+3")
            let response = self.execute(query)
            if response.ok && response.checkReturnCode() {
                let lines = response.readRemainingAnsiLines()
                result = ProcessInfo.parse(lines)
            }
        }
        return result
    } // func listProcesses

    /**
     * Empty operation. Confirms the client as alive.
     */
    func noOp() -> Bool {
        if !self.connected {
            return false
        }
        
        let query = ClientQuery(self, command: "N")
        return self.execute(query).ok
    } // func noOp

    /**
     * Parse the connection string.
     */
    func parseConnectionString(_ connectionString: String) {
        let items = connectionString.components(separatedBy: ";")
        for item in items {
            if item.isEmpty {
                continue
            }

            let parts = split2(item, separator: "=")
            if parts.count != 2 {
                continue
            }

            let name = parts[0].lowercased()
            let value = trim(parts[1])

            switch(name) {
            case "host", "server", "address":
                self.host = value;

            case "port":
                self.port = UInt16(parseInt32(value))

            case "user", "username", "name", "login":
                self.username = value

            case "pwd", "password":
                self.password = value

            case "db", "database", "catalog":
                self.database = value

            case "arm", "workstation":
                self.workstation = value

            default:
                // TODO throw
                print("Unknown key \(name)")
            }
        } // for
    } // func parseConnectionString

    func readRecord(_ mfn: Int32, version: Int32 = 0) -> MarcRecord? {
        if !connected {
            return nil
        }

        let query = ClientQuery(self, command: "C")
        query.addAnsi(self.database).newLine()
        query.add(mfn).newLine()
        query.add(version).newLine()
        let response = self.execute(query)
        if !response.ok || !response.checkReturnCode() {
            return nil
        }
        // TODO implement good codes -201, -600, -602, -603

        let result = MarcRecord()
        let lines = response.readRemainingUtfLines()
        result.decode(lines)
        result.database = self.database

        if version != 0 {
            // TODO unlock records
        }

        return result
    } // func readRecord

    /**
     * Read the text file from the server.
     */
    func readTextFile(fileName: String) -> String? {
        if !self.connected || fileName.isEmpty {
            return nil
        }

        let query = ClientQuery(self, command: "L")
        query.addAnsi(fileName).newLine()
        let response = self.execute(query)
        if !response.ok {
            return nil
        }

        let line = response.readAnsi()
        if let text = line {
            let result = irbisToUnix(text)
            return result
        }
        return nil
    } // func readTextFile

    /**
     * Read the text file from the server as the array of lines.
     */
    func readTextLines(fileName: String) -> [String] {
        if !self.connected || fileName.isEmpty {
            return []
        }

        let query = ClientQuery(self, command: "L")
        query.addAnsi(fileName).newLine()
        let response = self.execute(query)
        if !response.ok {
            return []
        }

        let line = response.readAnsi()
        if let text = line {
            let result = irbisToLines(text)
            return result
        }
        return []
    } // func readTextLines

    /**
     * Recreate dictionary for the database.
     */
    func reloadDictionary(database: String) -> Bool {
        if !self.connected {
            return false
        }

        let query = ClientQuery(self, command: "Y")
        query.addAnsi(database).newLine()
        return self.execute(query).ok
    } // func reloadDictionary

    /**
     * Recreate master file for the database.
     */
    func reloadMasterFile(database: String) -> Bool {
        if !self.connected {
            return false
        }

        let query = ClientQuery(self, command: "X")
        query.addAnsi(database).newLine()
        return self.execute(query).ok
    } // func reloadMasterFile

    /**
     * Restart the server without losing the connected clients.
     */
    func restartServer() -> Bool {
        if !self.connected {
            return false
        }

        let query = ClientQuery(self, command: "+8")
        return self.execute(query).ok
    }

    func requireTextFile(fileName: String) -> String {
        let result = self.readTextFile(fileName: fileName)!
        if result.isEmpty {
            // TODO throw
        }
        return result
    } // func requireTextFile

    /**
     * Simple search for records (no more than 32k records).
     */
    func search(expression: String) -> [Int32] {
        var result = [Int32]()
        if !self.connected || expression.isEmpty {
            return result
        }

        let query = ClientQuery(self, command: "K")
        query.addAnsi(self.database).newLine()
        query.addUtf(expression).newLine()
        query.add(0).newLine()
        query.add(1).newLine()
        let response = self.execute(query)
        if !response.ok || !response.checkReturnCode() {
            return result
        }

        _ = response.readInteger() // count of found records
        let lines = response.readRemainingUtfLines()
        result = FoundLine.parseMfn(lines)
        return result
    } // func search

    /**
     * Extended search for records (no more than 32k records).
     */
    func search(parameters: SearchParameters) -> [FoundLine] {
        var result = [FoundLine]()
        if !connected {
            return result
        }

        let db = pickOne(parameters.database, self.database)
        let query = ClientQuery(self, command: "K")
        query.addAnsi(db).newLine()
        query.addUtf(parameters.expression).newLine()
        query.add(parameters.numberOfRecords).newLine()
        query.add(parameters.firstRecord).newLine()
        _ = query.addFormat(parameters.format)
        query.add(parameters.minMfn).newLine()
        query.add(parameters.maxMfn).newLine()
        query.addAnsi(parameters.sequential).newLine()
        let response = self.execute(query)
        if !response.ok || !response.checkReturnCode() {
            return result
        }

        _ = response.readInteger() // count of found records
        let lines = response.readRemainingUtfLines()
        result = FoundLine.parseFull(lines)
        return result
    } // func search

    /**
     * Search all the records (even if more than 32k records).
     */
    func searchAll(expression: String) -> [Int32] {
        var result = [Int32]()
        if !self.connected || expression.isEmpty {
            return result
        }

        var firstRecord: Int32 = 1
        var totalCount: Int32 = 0
        while(true) {
            let query = ClientQuery(self, command: "K")
            query.addAnsi(self.database).newLine()
            query.addUtf(expression).newLine()
            query.add(0).newLine()
            query.add(firstRecord).newLine()
            let response = self.execute(query)
            if !response.ok || !response.checkReturnCode() {
                break
            }

            if (firstRecord == 1) {
                totalCount = response.readInteger()
                if totalCount == 0 {
                    break
                }
            } else {
                _ = response.readInteger()
            }

            let lines = response.readRemainingUtfLines()
            let found = FoundLine.parseMfn(lines)
            if found.isEmpty {
                break
            }

            result.append(contentsOf: found)
            firstRecord += Int32(found.count)
            if firstRecord >= totalCount {
                break
            }
        } // while

        return result
    } // func searchAll

    /**
     * Determine the number of records matching the search expression.
     */
    func searchCount(_ expression: String) -> Int32 {
        if !self.connected || expression.isEmpty {
            return 0
        }

        let query = ClientQuery(self, command: "K")
        query.addAnsi(self.database).newLine()
        query.addUtf(expression).newLine()
        query.add(0).newLine()
        query.add(0).newLine()
        let response = self.execute(query)
        if !response.ok || !response.checkReturnCode() {
            return 0
        }
        let result = response.readInteger()
        return result
    } // func searchCount

    /**
     * Search for records and read found ones.
     * No more than 32k records.
     */
    func searchRead(_ expression: String, limit: Int32 = 0) -> [MarcRecord] {
        var result = [MarcRecord]()
        if !self.connected || expression.isEmpty {
            return result
        }

        let parameters = SearchParameters()
        parameters.expression = expression
        parameters.format = ALL_FORMAT
        parameters.numberOfRecords = limit
        let found = self.search(parameters: parameters)
        if found.isEmpty {
            return result
        }

        for item in found {
            if item.text.isEmpty {
                continue
            }
            var lines = item.text.components(separatedBy: ALT_DELIMITER)
            lines = Array(lines[1...])
            if lines.isEmpty {
                continue
            }
            let record = MarcRecord()
            record.decode(lines)
            record.database = self.database
            result.append(record)
        } // for

        return result
    } // func searchRead

    func searchSingleRecord(_expression: String) -> MarcRecord? {
        // TODO implement
        return nil
    } // func searchSingleRecord

    func throwOnError() {
        if self.lastError < 0 {
            // TODO throw
        }
    } // func throwOnError

    func toConnectionString() -> String {
        return "host=\(host);port=\(port);username=\(username);password=\(password);database=\(database);arm=\(workstation)"
    } // func toConnectionString

    /**
     * Empty the database.
     */
    func truncateDatabase(database: String = "") -> Bool {
        if !self.connected {
            return false
        }

        let db = pickOne(database, self.database)
        let query = ClientQuery(self, command: "S")
        query.addAnsi(db).newLine()
        return self.execute(query).ok
    } // func truncateDatabase

    /**
     * Unlock the database.
     */
    func unlockDatabase(database: String = "") -> Bool {
        if !self.connected {
            return false
        }

        let db = pickOne(database, self.database)
        let query = ClientQuery(self, command: "U")
        query.addAnsi(db).newLine()
        return self.execute(query).ok
    } // func unlockDatabase

    /**
     * Unlock some records in the database.
     */
    func unlockRecords(database: String = "", _ mfnList: [Int32]) -> Bool {
        if !self.connected {
            return false
        }

        if mfnList.isEmpty {
            return true
        }

        let db = pickOne(database, self.database)
        let query = ClientQuery(self, command: "Q")
        query.addAnsi(db).newLine()
        for mfn in mfnList {
            query.add(mfn).newLine()
        }
        return self.execute(query).ok
    } // func unlockRecords

    /**
     * Update server INI file fro current user.
     */
    func updateIniFile(lines: [String]) -> Bool {
        if !self.connected {
            return false
        }

        if lines.isEmpty {
            return true
        }

        let query = ClientQuery(self, command: "8")
        for line in lines {
            query.addAnsi(line).newLine()
        }
        return self.execute(query).ok
    } // func updateIniFile
    
} // class Connection
