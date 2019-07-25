import Foundation

//=========================================================
// INI-file

class IniLine {
    var key: String
    var value: String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    }
} // class IniLine

class IniSection {
    var name: String
    var lines: [IniLine]
    
    init(name: String) {
        self.name = name
        self.lines = []
    }
} // class IniSection

class IniFile {
    var sections: [IniSection]
    
    init() {
        self.sections = []
    }
} // class IniFile
