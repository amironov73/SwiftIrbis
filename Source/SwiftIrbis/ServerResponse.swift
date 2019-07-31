import Foundation

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
    
    func checkReturnCode(allowed: Int32...) -> Bool {
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
        if self.eof() {
            return ""
        }
        let chunk = self.buffer[self.offset...]
        return fromUtf(chunk)
    } // func readRemainingUtfText
    
    func readUtf() -> String? {
        let line = getLine()
        guard let text = line else {
            return nil
        }
        return fromUtf(text)
    } // func readUtf
    
} // class ServerResponse
