import Foundation

//=========================================================
// Server connection

public class Connection {
    
    /// Host name or IP-address. Default value is "127.0.0.1".
    public var host: String = "127.0.0.1"
    
    /// Port number. Default value is 6666.
    public var port: UInt16 = 6666
    
    /// User login. Default is blank.
    public var username: String = ""
    
    /// User password. Default is blank.
    public var password: String = ""
    
    /// Current database name. Default is "IBIS".
    public var database: String = "IBIS"
    
    /// Workstation code. Default is "C" (cataloger).
    public var workstation: String = CATALOGER
    
    /// Unique client identifier. Generated automatically.
    internal(set) public var clientId: Int32 = 0
    
    /// Sequential query number. Updated automatically.
    internal(set) public var queryId: Int32 = 0
    
    /// Connection state. Updated automatically.
    internal(set) public var connected: Bool = false
    
    /// Last error code. Updated automatically.
    internal(set) public var lastError: Int32 = 0
    
    /// Server version. Fetched automatically at connection time.
    internal(set) public var serverVersion: String = ""
    
    /// Suggested auto-ACK interval, minutes.
    /// Fetched automatically at connection time.
    internal(set) public var interval: Int32 = 0
    
    /// Transport socket.
    public var socket: ClientSocket = ClientSocket()
    
    /// INI-file. Fetched automatically at connection time.
    private(set) public var ini: IniFile = IniFile()

    /// Actualize all non-actualized records in the database.
    ///
    /// - Parameter database: database name (must be non-empty).
    /// - Returns: sign of success.
    func actualizeDatabase(database: String) -> Bool {
        precondition(!database.isEmpty)
        
        return actualizeRecord(database: database, mfn: 0)
    } // func actualizeDatabase

    /// Actualize the record with given MFN.
    ///
    /// - Parameters:
    ///   - database: database name (must be non-empty).
    ///   - mfn: MFN of record to actualize.
    /// - Returns: sign of success.
    public func actualizeRecord(database: String, mfn: Int32) -> Bool {
        precondition(!database.isEmpty)
        precondition(mfn >= 0)
        
        if !self.connected {
            return false
        }
        
        let query = ClientQuery(self, command: "F")
        query.addAnsi(database).newLine()
        query.add(mfn).newLine()
        let response = self.execute(query)
        
        return response.ok && response.checkReturnCode()
    } // func actualizeRecord

    /// Establish the server connection.
    ///
    /// If already connected, does nothing.
    ///
    /// - Returns: sign of success (see lastError for error code).
    public func connect() -> Bool {
        precondition(!self.host.isEmpty)
        precondition(!self.username.isEmpty)
        precondition(!self.password.isEmpty)
        precondition(!self.workstation.isEmpty)
        
        if self.connected {
            return true
        }

        self.lastError = 0
        self.clientId = Int32.random(in: 100_000...999_999)
        self.queryId = 1
        let query = ClientQuery(self, command: "A")
        query.addAnsi(self.username).newLine()
        _ = query.addAnsi(self.password)
        let response = self.execute(query)
        if !response.ok {
            return false
        }
        
        _ = response.getReturnCode()
        if response.returnCode == -3337 {
            return self.connect()
        }
        
        if response.returnCode < 0 {
            self.lastError = response.returnCode
            return false
        }
        
        self.connected = true
        self.serverVersion = response.serverVersion
        self.interval = response.readInteger()
        
        let lines = response.readRemainingAnsiLines()
        self.ini.parse(lines)
        
        return true
    } // func connect

    /// Create the server database.
    ///
    /// - Parameters:
    ///   - database: database name (must be non-empty).
    ///   - description: free-formed description of the database.
    ///   - readerAccess: readers can access the database.
    /// - Returns: sign of success.
    public func createDatabase(database: String, description: String,
                        readerAccess: Bool=true) -> Bool {
        precondition(!database.isEmpty)
        precondition(!description.isEmpty)

        if !self.connected {
            return false
        }

        let query = ClientQuery(self, command: "T")
        query.addAnsi(database).newLine()
        query.addAnsi(description).newLine()
        query.add(readerAccess ? 1 : 0).newLine()
        let response = self.execute(query)
        
        return response.ok && response.checkReturnCode()
    } // func createDatabase

    /// Create the dictionary for the database.
    ///
    /// - Parameter database: name of the database, empty = current database.
    /// - Returns: <#return value description#>sign of success.
    public func createDictionary(database: String = "") -> Bool {
        if !self.connected {
            return false
        }

        let db = pickOne(database, self.database)
        let query = ClientQuery(self, command: "Z")
        query.addAnsi(db).newLine()
        let response = self.execute(query)
        
        return response.ok && response.checkReturnCode()
    } // func createDictionary

    /// Delete the database on the server.
    ///
    /// - Parameter database: database name (must be non-empty).
    /// - Returns: sign of success.
    public func deleteDatabase(database: String) -> Bool {
        precondition(!database.isEmpty)

        if !self.connected {
            return false
        }

        let query = ClientQuery(self, command: "W")
        query.addAnsi(database).newLine()
        let response = self.execute(query)
        
        return response.ok && response.checkReturnCode()
    } // func deleteDatabase

    /// Delete specified file on the server.
    ///
    /// - Parameter fileName: name of the file (must be non-empty)
    public func deleteFile(fileName: String) {
        precondition(!fileName.isEmpty)

        _ = formatRecord("&uf('+9K\(fileName)')", mfn: 1)
    } // func deleteFile


    /// Disconnect from the server.
    ///
    /// It's OK to disconnect twice or more times.
    /// The method does nothing when the client wasn't connected yet.
    ///
    /// - Returns: sign of success.
    public func disconnect() -> Bool {
        if !self.connected {
            return true
        }
        
        let query = ClientQuery(self, command: "B")
        _ = query.addAnsi(self.username)
        _ = self.execute(query)
        
        self.connected = false
        return true
    } // func disconnect
    
    func execute(_ query: ClientQuery) -> ServerResponse {
        self.lastError = 0
        self.queryId += 1
        
        return self.socket.talkToServer(query: query)
    } // func execute

    func executeAsync(_ query: ClientQuery) -> ServerResponse {
        // TODO implement
        return self.execute(query)
    } // func executeAsync

    /// Format the record by MFN on the server.
    ///
    /// - Parameters:
    ///   - format: format to use.
    ///   - mfn: MFN of the record.
    /// - Returns: result of formatting.
    public func formatRecord(_ format: String, mfn: Int32) -> String {
        if !self.connected || mfn < 1 || format.isEmpty {
            return ""
        }

        let query = ClientQuery(self, command: "G")
        query.addAnsi(self.database).newLine()
        if (!query.addFormat(format)) {
            return ""
        }

        query.add(1).newLine()
        query.add(mfn).newLine()
        let response = self.execute(query)
        if !response.ok || !response.checkReturnCode() {
            return ""
        }

        var result = response.readRemainingUtfText()
        result = trim(result)
        return result
    } // func formatRecord
    
    func getMaxMfn(database: String = "") -> Int32 {
        if !self.connected {
            return 0
        }

        let db = pickOne(database, self.database)
        let query = ClientQuery(self, command: "O")
        _ = query.addAnsi(db)
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

    /**
     Get the user list from the server.
     */
    func getUserList() -> [UserInfo] {
        var result = [UserInfo]()
        if !self.connected {
            return result
        }

        let query = ClientQuery(self, command: "+9")
        let response = self.execute(query)
        if !response.ok || !response.checkReturnCode() {
            return result
        }
        let lines = response.readRemainingAnsiLines()
        result = UserInfo.parse(lines)
        return result
    } // func getUserList

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

    /// Read record
    ///
    /// - Parameters:
    ///   - mfn: <#mfn description#>
    ///   - version: <#version description#>
    /// - Returns: <#return value description#>
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
