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
