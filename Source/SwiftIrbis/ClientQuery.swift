import Foundation

//=========================================================
// Client query

/// Client query.
public class ClientQuery {
    
    /// Connection to use.
    var connection: Connection
    
    /// Command code.
    var command: String
    
    /// Internal buffer.
    private var buffer: Data
    
    /// Initializer.
    ///
    /// - Parameters:
    ///   - connection: connection to use.
    ///   - command: command code.
    public init(_ connection: Connection, command: String) {
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
    } // init

    /// Append integer number to the query.
    ///
    /// - Parameter number: integer value to add.
    /// - Returns: query itself allowing to chain calls.
    public func add(_ number: Int32) -> ClientQuery {
        return self.addAnsi(String(number))
    } // func add

    /// Append ANSI-encoded text chunk to the query.
    ///
    /// - Parameter text: chunk to append.
    /// - Returns: query itself allowing to chain calls.
    public func addAnsi(_ text: String) -> ClientQuery {
        if !text.isEmpty {
            self.buffer.append(toAnsi(text))
        }
        return self
    } // func addAnsi
    
    /// Append format specification to the query.
    ///
    /// - Parameter text: format to append.
    /// - Returns: query itself allowing to chain calls.
    public func addFormat(_ text: String) -> Bool {
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
    
    /// Append UTF8-encoded text chunk to the query.
    ///
    /// - Parameter text: chunk to append.
    /// - Returns: query itself allowing to chain calls.
    public func addUtf(_ text: String) -> ClientQuery {
        if !text.isEmpty {
            self.buffer.append(toUtf(text))
        }
        return self
    } // func addUtf
    
    /// Encode the query.
    ///
    /// - Returns: encoded query data.
    func encode() -> Data {
        let prefix = "\(buffer.count)\n"
        self.buffer.insert(contentsOf: toAnsi(prefix), at: 0)
        let result = self.buffer
        return result
    } // func encode
    
    /// Append new line symbol to the query.
    public func newLine() {
        self.buffer.append(UInt8(10))
    } // func newLine
    
} // class ClientQuery
