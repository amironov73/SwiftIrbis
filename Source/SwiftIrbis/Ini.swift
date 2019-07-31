import Foundation

//=========================================================
// INI-file

/**
 * Line of INI-file. Consist of a key and value.
 */
public class IniLine {

    /// Key string.
    public var key: String
    
    /// Value string.
    var value: String
    
    init(key: String, value: String) {
        self.key = key
        self.value = value
    } // init

    var description: String {
        return "\(key)=\(value)"
    } // var description

    var debugDescription: String {
        return "IniLine(key: \(key), value: \(value))"
    } // var debugDescription
} // class IniLine

/**
 * Section of INI-file. Consist of lines (see IniLine).
 */
public class IniSection {

    var name: String // Name of the section.
    var lines: [IniLine] // Lines.
    
    init(name: String) {
        self.name = name
        self.lines = []
    } // init

    /**
     * Find INI-line with specified key.
     */
    func find(_ key: String) -> IniLine? {
        for line in self.lines {
            if sameString(line.key, key) {
                return line
            }
        } // for
        return nil
    } // func find

    /**
     * Get value for specified key.
     * If no entry found, default value used.
     */
    func getValue(_ key: String, defaultValue: String = "") -> String {
        let found = self.find(key)
        if let line = found {
            return line.value
        }
        return defaultValue
    } // func getValue

    /**
     * Remove line with specified key.
     */
    func remove(_ key: String) {
        // TODO implement
    } // func remove

    /**
     * Set the value for specified key.
     */
    func setValue(_ key: String, _ value: String) {
        if value.isEmpty {
            self.remove(key)
        } else {
            let item = self.find(key)
            if let line = item {
                line.value = value
            } else {
                let line = IniLine(key: key, value: value)
                self.lines.append(line)
            }
        } // else
    } // func setValue

    var description: String {
        var result = ""
        if !self.name.isEmpty {
            result = "[\(self.name)]\n"
        }
        for line in self.lines {
            result.append("\(line.key)=\(line.value)\n")
        }
        return result
    } // var description

    var debugDescription: String {
        return self.description
    } // var debugDescription

} // class IniSection

/**
 * INI-file. Consist of sections (see IniSection).
 */
public class IniFile {

    /// Array of sections.
    public var sections: [IniSection] = []

    /**
     * Clear the INI-file.
     */
    func clear() {
        self.sections.removeAll()
    } // func clear

    /**
     * Find section with specified name.
     */
    func findSection(_ name: String) -> IniSection? {
        for section in self.sections {
            if sameString(section.name, name) {
                return section
            }
        } // for
        return nil
    } // func findSection

    /**
     * Get section with specified name.
     * Create the section if it doesn't exist.
     */
    func getOrCreateSection(_ name: String) -> IniSection {
        var result = self.findSection(name)
        if result == nil {
            result = IniSection(name: name)
            self.sections.append(result!)
        }
        return result!
    } // func getOrCreateSection

    /**
     * Get the value from the specified section and line.
     */
    func getValue(sectionName: String, keyName: String, defaultValue: String="") -> String {
        let found = self.findSection(sectionName)
        if let section = found {
            return section.getValue(keyName, defaultValue: defaultValue)
        }
        return defaultValue
    } // func getValue

    /**
     * Parse the text representation of the INI-file.
     */
    func parse(_ lines: [String]) {
        var section: IniSection? = nil
        for line in lines {
            let trimmed = trim(line)
            if trimmed.isEmpty {
                continue
            }

            if trimmed.first! == "[" {
                let name = subStr(trimmed, 1, trimmed.count - 2)
                section = getOrCreateSection(name)
            } else {
                if section != nil {
                    let parts = split2(trimmed, separator: "=")
                    if parts.count != 2 {
                        continue
                    }
                    let key = trim(parts[0])
                    if key.isEmpty {
                        continue
                    }
                    let value = trim(parts[1])
                    let item = IniLine(key: key, value: value)
                    section!.lines.append(item)
                } // if
            } // else
        } // for
    } // func parse

    /**
     * Set the value for specified key in specified section.
     */
    func setValue(sectionName: String, keyName: String, value: String) {
        let section = self.getOrCreateSection(sectionName)
        section.setValue(keyName, value)
    } // func setValue

    var description: String {
        var result = ""
        var first = true
        for section in self.sections {
            if !first {
                result.append("\n")
            }
            result.append(section.description)
            first = false
        }
        return result
    } // var description

    var debugDescription: String {
        return self.description
    } // var debugDescription

} // class IniFile
