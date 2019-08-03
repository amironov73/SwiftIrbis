import Foundation

/// Wrapper for POSIX FILE
public class ClassicFile {
    
    private var fp: UnsafeMutablePointer<FILE>
    private(set) public var fileName: String
    private var closed: Bool
    
    /// Initializer.
    ///
    /// - Parameters:
    ///   - fileName: name of the file.
    ///   - mode: desired access mode.
    /// - Throws: I/O error.
    public init(fileName: String, mode: String) throws {
        self.fileName = fileName
        self.fp = fopen(fileName, mode)
        self.closed = false
    } // init

    deinit {
        self.close()
    } // deinit

    /// Close the file.
    public func close() {
        if !self.closed {
            fclose(self.fp)
            self.closed = true
        }
    } //  func close
    
    /// Current read/write position.
    public var position: Int {
        get {
            return ftell(self.fp)
        }
        set(newValue) {
            fseek(self.fp, newValue, SEEK_SET)
        }
    } // var position

    /// Read array of bytes.
    ///
    /// - Parameter count: byte count to read.
    /// - Returns: read
    public func read(count: Int) -> Data {
        precondition(count > 0)

        var buffer = [UInt8](repeating: 0, count: count)
        let read = Darwin.fread(&buffer, 1, count, self.fp)
        let result = Data(buffer[0..<read])
        return result
    } // func read
    
    /// Read text line using ANSI encoding.
    ///
    /// - Returns: text read.
    public func readAnsiLine() -> String? {
        return fromAnsi(self.readLine())
    } // func readAnsiLine
    
    /// Read line from the file.
    ///
    /// - Returns: raw string data (no encoding implied).
    public func readLine() -> Data {
        var result = Data()
        var char: UInt8 = 0
        while true {
            let read = fread(&char, 1, 1, self.fp)
            if read != 1 {
                break;
            }
            if char == 10 {
                break
            }
            if char == 13 {
                continue // skip cr
            }
            result.append(char)
        } // while
        return result
    } // func readLine
    
    /// Read text line using UTF-8 encoding.
    ///
    /// - Returns: text read.
    public func readUtfLine() -> String? {
        return fromUtf(self.readLine())
    } // func readUtfLine
    
    /// File size, bytes.
    public var size: Int {
        let currentOffset = self.position
        fseek(self.fp, 0, SEEK_END)
        let result = ftell(self.fp)
        fseek(self.fp, currentOffset, SEEK_SET)
        return result
    } // var size
    
    /// Write data to the file.
    ///
    /// - Parameter data: array of bytes to write.
    /// - Throws: I/O error.
    public func write(data: [UInt8]) throws {
        let count = data.count
        let written = fwrite(data, 1, count, self.fp)
        if written != count {
            // TODO throw
        }
    } // func write
    
    public func writeLine() {
        // TODO implement
    } // func write
    
} // class ClassicFile
