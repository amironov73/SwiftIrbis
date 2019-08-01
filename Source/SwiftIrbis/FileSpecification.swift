import Foundation

//=========================================================
// File specification

/// File specification.
public class FileSpecification {
    
    /// Path.
    public var path: Int
    
    /// Database name.
    public var database: String
    
    /// File name.
    public var filename: String
    
    /// File content.
    public var content: String?
    
    /// Binary file?
    public var binary: Bool
    
    /// Mandatory file?
    public var mandatory: Bool
    
    /// Initializer
    ///
    /// - Parameters:
    ///   - path: path.
    ///   - database: database name.
    ///   - filename: file name.
    public init(path: Int, database: String, filename: String) {
        self.path = path
        self.database = database
        self.filename = filename
        self.content = nil
        self.binary = false
        self.mandatory = false
    } // init
    
    /// Initializer.
    ///
    /// - Parameters:
    ///   - path: path.
    ///   - filename: file name.
    public init(path: Int, filename: String) {
        self.path = path
        self.database = ""
        self.filename = filename
        self.content = nil
        self.binary = false
        self.mandatory = false
    } // init
    
    public var description: String {
        return "\(self.path).\(self.database).\(self.filename)"
    } // var description
    
    /// Shortcut.
    ///
    /// - Parameters:
    ///   - database: database name.
    ///   - filename: file name.
    /// - Returns: specification.
    public static func master(_ database: String, _ filename: String) -> FileSpecification {
        return FileSpecification(path: 1, filename: filename)
    } // func master
    
    /// Parse the specification.
    ///
    /// - Parameter text: text to parse.
    /// - Returns: specification.
    public static func parse(text: String) -> FileSpecification {
        let parts = text.split(separator: ".", maxSplits: 2, omittingEmptySubsequences: false)
        let path = Int(parts[0])
        // TODO full parse
        return FileSpecification(path: path!, database: String(parts[1]), filename: String(parts[2]))
    } // method parse
    
    /// Convert the specification to text.
    ///
    /// - Returns: text representation of the specification.
    public func toString() -> String {
        var result = self.filename
        if self.binary {
            result = "@" + result
        } else if self.content != nil {
            result = "&" + result
        }
        
        result = "\(self.path).\(self.database).\(result)"
        
        if self.content != nil {
            result = "\(result)&\(self.content!)"
        }
        
        return result
    } // method toString
    
} // class FileSpecification
