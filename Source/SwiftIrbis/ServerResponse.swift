import Foundation

//=========================================================
// Server response

/// Server response decoder.
public class ServerResponse {
    
    /// Command code.
    private(set) public var command: String = ""
    
    /// Unique client identifier.
    private(set) public var clientId: Int32 = 0
    
    /// Query sequential number.
    private(set) public var queryId: Int32 = 0
    
    /// Return code (not always fetched).
    private(set) public var returnCode: Int32 = 0
    
    /// Answer size, bytes.
    private(set) public var answerSize: Int32 = 0
    
    /// Server version (fetched only at connect time).
    private(set) public var serverVersion: String = ""
    
    /// Auto-ACK interval, minutes.
    private(set) public var interval: Int32 = 0
    
    /// Sign of success. Updated automatically.
    private(set) public var ok: Bool = false
    
    private var connection: Connection?
    private var buffer: Data
    private var offset: Int
    
    /// Initializer.
    ///
    /// - Parameter buffer: server response raw data.
    public init(_ rawData: Data) {
        self.buffer = rawData
        self.ok = !rawData.isEmpty
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
    
    /// End of data reached?
    ///
    /// - Returns: sign of data end.
    public func eof() -> Bool {
        return self.offset >= self.buffer.count
    } // func eof
    
    /// Check return code against some allowed codes.
    ///
    /// - Parameter allowed: allowed codes.
    /// - Returns: all OK?
    public func checkReturnCode(allowed: Int32...) -> Bool {
        if self.getReturnCode() < 0 {
            if allowed.contains(self.returnCode) {
                return true
            }
            return false // TODO check for allowed codes
        }
        return true
    } // func checkReturnCode
    
    func findPreamble(preamble: Data) -> Data? {
        return nil // TODO implement
    } // func getPreamble
    
    /// Read one line of text as raw data (no encoding assumed).
    ///
    /// - Returns: data was read or `nil`.
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
    
    /// Read one line of text as signed 32-bit integer.
    ///
    /// - Returns: return code.
    func getReturnCode() -> Int32 {
        assert(!self.eof())
        
        self.returnCode = readInteger()
        self.connection?.lastError = self.returnCode
        
        return self.returnCode
    } // func getReturnCode
    
    /// Read one text line in ANSI encoding.
    ///
    /// - Returns: text line or `nil`.
    public func readAnsi() -> String? {
        let line = getLine()
        guard let text = line else {
            return nil
        }
        return fromAnsi(text)
    } // func readAnsi
    
    /// Read one text line as signed 32-bit integer number.
    ///
    /// - Returns: number was read or 0.
    public func readInteger() -> Int32 {
        let line = readAnsi()
        guard let text = line else {
            return 0
        }
        return parseInt32(text)
    } // func readInteger
    
    /// Read remaining text lines in ANSI encoding.
    ///
    /// - Returns: text was read.
    public func readRemainingAnsiLines() -> [String] {
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
    
    /// Read remaining text as one big chunk in ANSI encoding.
    ///
    /// - Returns: text was read.
    public func readRemainingAnsiText() -> String {
        if self.eof() {
            return ""
        }
        
        let chunk = self.buffer[self.offset...]
        return fromAnsi(chunk)
    } // func readRemainingAnsiText
    
    /// Read remaining text lines in UTF-8 encoding.
    ///
    /// - Returns: text was read.
    public func readRemainingUtfLines() -> [String] {
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
    
    /// Read remaining text as one big chunk in UTF-8 encoding.
    ///
    /// - Returns: text was read.
    public func readRemainingUtfText() -> String {
        if self.eof() {
            return ""
        }
        let chunk = self.buffer[self.offset...]
        return fromUtf(chunk)
    } // func readRemainingUtfText
    
    /// Read one text line in UTF-8 encoding.
    ///
    /// - Returns: text line or `nil`.
    public func readUtf() -> String? {
        let line = getLine()
        guard let text = line else {
            return nil
        }
        return fromUtf(text)
    } // func readUtf
    
} // class ServerResponse
