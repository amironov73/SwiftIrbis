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

    func addFormat(_ text: String) {
        // TODO implement
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
        var inputStream: InputStream!
        var outputStream: OutputStream!
        Stream.getStreamsToHost(withName: connection.host, port: Int(connection.port), inputStream: &inputStream, outputStream: &outputStream)
        inputStream.open()
        outputStream.open()

        var outputPacket = query.encode()
        outputPacket.withUnsafeBytes { (u8Ptr) -> Int in
            outputStream.write(u8Ptr, maxLength: outputPacket.count)
        }

        let bufferSize = 32 * 1024
        var inputBuffer = Array<UInt8>(repeating: 0, count: bufferSize)
        let bytesRead = inputStream.read(&inputBuffer, maxLength: bufferSize)

        inputStream!.close()
        outputStream!.close()

        var buffer = Data()
        buffer.append(contentsOf: inputBuffer)
        let result = ServerResponse(buffer)
        result.connection = query.connection

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
        return []
    } // func readRemainingAnsiLines
    
    func readRemainingAnsiText() -> String {
        return ""
    } // func readRemainingAnsiText
    
    func readRemainingUtfLines() -> [String] {
        return []
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
    var port: Int16 = 6666
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
        let response = self.execute(query: query)
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
        let response = self.execute(query: query)
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
        _ = self.execute(query: query)
        
        self.connected = false
        return true
    } // func disconnect
    
    func execute(query: ClientQuery) -> ServerResponse {
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
        
        let query = ClientQuery(self, command: "N")
        return self.execute(query: query).ok
    } // func noOp
    
} // class Connection
