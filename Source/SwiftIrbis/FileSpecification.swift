import Foundation

//=========================================================
// File specification



/**
 * File specification.
 */
class FileSpecification {
    
    var path: Int
    var database: String
    var filename: String
    var content: String
    var binary: Bool
    
    init(path: Int, database: String, filename: String) {
        self.path = path
        self.database = database
        self.filename = filename
        self.content = ""
        self.binary = false
    } // init
    
    init(path: Int, filename: String) {
        self.path = path
        self.database = ""
        self.filename = filename
        self.content = ""
        self.binary = false
    } // init
    
    static func parse(text: String) -> FileSpecification {
        let parts = text.split(separator: " ", maxSplits: 3)
        let path = Int(parts[0])
        return FileSpecification(path: path!, database: String(parts[1]), filename: String(parts[2]))
    } // method parse
    
    func toString() -> String {
        return String(path) + "." + database + "." + filename
    } // method toString
    
} // class FileSpecification
