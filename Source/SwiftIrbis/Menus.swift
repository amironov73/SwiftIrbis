import Foundation

//=========================================================
// Menus

class MenuEntry {
    var code: String
    var comment: String
    
    init(code: String, comment: String) {
        self.code = code
        self.comment = comment
    } // init
    
} // class MenuEntry

class MenuFile {
    var entries: [MenuEntry] = []
    
    func append(code: String, comment: String) -> MenuFile {
        let entry = MenuEntry(code: code, comment: comment)
        self.entries.append(entry)
        return self
    } // func append
    
    func clear() -> MenuFile {
        self.entries = []
        return self
    } // func clear
    
} // class MenuFile

