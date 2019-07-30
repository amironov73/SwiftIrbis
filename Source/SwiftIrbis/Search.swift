import Foundation

//=========================================================
// Search parameters

class SearchParameters: CustomStringConvertible, CustomDebugStringConvertible {

    var database: String = "" // Database name.
    var firstRecord: Int32 = 1 // First record number.
    var format: String = "" // Format specification.
    var maxMfn: Int32 = 0 // Maximal MFN.
    var minMfn: Int32 = 0 // Minimal MFN.
    var numberOfRecords: Int32 = 0 // Number of records required. 0 = all.
    var expression: String = "" // Search expression.
    var sequential: String = "" // Sequential search expression.
    var filter: String = "" // Additional filter

    func toString() -> String {
        return self.expression
    } // func toString

    var description: String {
        return self.toString()
    } // var description

    var debugDescription: String {
        return self.toString()
    } // var debugDescription

} // class SearchParameters

//=========================================================
// Found record information

/**
 * Information about found record.
 * Used in search method.
 */
class FoundLine: CustomStringConvertible, CustomDebugStringConvertible {

    var mfn: Int32 = 0 // Record MFN.
    var text: String = "" // Description (optional).

    func parse(_ text: String) {
        let parts = split2(text, separator: "#")
        self.mfn = parseInt32(parts[0])
        self.text = safeGet(parts, 1)
    } // func parse

    static func parseDescriptions(_ lines: [String]) -> [String] {
        var result = [String]()
        result.reserveCapacity(lines.count)
        for line in lines {
            if !line.isEmpty {
                let parts = split2(line, separator: "#")
                let description = safeGet(parts, 1)
                if !description.isEmpty {
                    result.append(description)
                }
            } // if
        } // for
        return result
    } // func parseDescriptions

    static func parseFull(_ lines: [String]) -> [FoundLine] {
        var result = [FoundLine]()
        result.reserveCapacity(lines.count)
        for line in lines {
            if !line.isEmpty {
                let parts = split2(line, separator: "#")
                let item = FoundLine()
                item.mfn = parseInt32(parts[0])
                item.text = safeGet(parts, 1)
                result.append(item)
            } // if
        } // for
        return result
    } // func parseFull

    static func parseMfn(_ lines: [String]) -> [Int32] {
        var result = [Int32]()
        result.reserveCapacity(lines.count)
        for line in lines {
            if !line.isEmpty {
                let parts = split2(line, separator: "#")
                let mfn = parseInt32(parts[0])
                if mfn != 0 {
                    result.append(mfn)
                }
            } // if
        } // for
        return result
    } // func parseMfn

    var description: String {
        return "\(mfn)#\(text))"
    } // var description

    var debugDescription: String {
        return "FoundLine(mfn: \(mfn), text: \(text))"
    } // var debugDescription

} // class FoundLine

//=========================================================
// Search query builder

/**
 * Search query builder.
 */
class Search: CustomStringConvertible, CustomDebugStringConvertible {

    private var _buffer: String

    init() {
        _buffer = ""
    }

    static func all() -> Search {
        let result = Search()
        result._buffer = "I=$"
        return result
    } // func all

    func and(_ items: String...) -> Search {
        _buffer = "(" + _buffer
        for item in items {
            _buffer = _buffer + " * " + wrapIfNeeded(item)
        }
        _buffer = _buffer + ")"
        return self
    } // func and

    func and(_ items: Search...) -> Search {
        _buffer = "(" + _buffer
        for item in items {
            _buffer = _buffer + " * " + wrapIfNeeded(item)
        }
        _buffer = _buffer + ")"
        return self
    } // func and

    static func equals(prefix: String, _ values: [String]) -> Search {
        let result = Search()
        var text = result.wrapIfNeeded(prefix + values[0])
        if values.count > 1 {
            text = "(" + text
            for i in 1..<values.count {
                text = text + " + " + result.wrapIfNeeded(values[i])
            }
            text = text + ")"
        }
        result._buffer = text
        return result
    } // func equals

    func needWrap(_ text: String) -> Bool {
        if text.isEmpty {
            return true
        }

        let c = text.first!
        if c == "\"" || c == "(" {
            return false
        }

        if text.contains(" ") ||
            text.contains("+") ||
            text.contains("*") ||
            text.contains("^") ||
            text.contains("#") ||
            text.contains("(") ||
            text.contains(")") ||
            text.contains("\"")  {
            return true
        }
        
        return false
    } // func needWrap

    func not(_ text: String) -> Search {
        _buffer = "(" + _buffer + " ^ " + wrapIfNeeded(text) + ")"
        return self
    } // func not

    func not(_ search: Search) -> Search {
        return not(search.toString())
    } // func not

    func or(_ items: String...) -> Search {
        _buffer = "(" + _buffer
        for item in items {
            _buffer = _buffer + " + " + wrapIfNeeded(item)
        }
        _buffer = _buffer + ")"
        return self
    } // func or

    func or(_ items: Search...) -> Search {
        _buffer = "(" + _buffer
        for item in items {
            _buffer = _buffer + " + " + wrapIfNeeded(item)
        }
        _buffer = _buffer + ")"
        return self
    } // func or

    func sameField(_ items: String...) -> Search {
        _buffer = "(" + _buffer
        for item in items {
            _buffer = _buffer + " (G) " + wrapIfNeeded(item)
        }
        _buffer = _buffer + ")"
        return self
    } // func sameField

    func sameField(_ items: Search...) -> Search {
        _buffer = "(" + _buffer
        for item in items {
            _buffer = _buffer + " (G) " + wrapIfNeeded(item)
        }
        _buffer = _buffer + ")"
        return self
    } // func sameField

    func sameRepeat(_ items: String...) -> Search {
        _buffer = "(" + _buffer
        for item in items {
            _buffer = _buffer + " (F) " + wrapIfNeeded(item)
        }
        _buffer = _buffer + ")"
        return self
    } // func sameRepeat

    func sameRepeat(_ items: Search...) -> Search {
        _buffer = "(" + _buffer
        for item in items {
            _buffer = _buffer + " (F) " + wrapIfNeeded(item)
        }
        _buffer = _buffer + ")"
        return self
    } // func sameRepeat

    func wrapIfNeeded(_ text: String) -> String {
        if (needWrap(text)) {
            return "\"" + text + "\""
        }
        return text
    } // func wrapIfNeeded

    func wrapIfNeeded(_ search: Search) -> String {
        let text = search.toString()
        if needWrap(text) {
            return "\"" + text + "\""
        }
        return text
    } // func wrapIfNeeded

    func toString() -> String {
        return _buffer
    } // func toString

    var description: String {
        return self.toString()
    } // var description

    var debugDescription: String {
        return self.toString()
    } // var debugDescription

} // class Search

// Search by keyword
func keyword(_ values: String...) -> Search {
    return Search.equals(prefix: "K=", values)
}

// Search by individual author
func author(_ values: String...) -> Search {
    return Search.equals(prefix: "A=", values)
}

// Search by collective author
func collective(_ values: String...) -> Search {
    return Search.equals(prefix: "M=", values)
}

// Search by title
func title(_ values: String...) -> Search {
    return Search.equals(prefix: "T=", values)
}

// Search by number
func number(_ values: String...) -> Search {
    return Search.equals(prefix: "IN=", values)
}

// Search by publisher
func publisher(_ values: String...) -> Search {
    return Search.equals(prefix: "O=", values)
}

/// Search by publishing place
func place(_ values: String...) -> Search {
    return Search.equals(prefix: "MI=", values)
}

// Search by subject
func subject(_ values: String...) -> Search {
    return Search.equals(prefix: "S=", values)
}

// Search by language
func language(_ values: String...) -> Search {
    return Search.equals(prefix: "J=", values)
}

// Search by year
func year(_ values: String...) -> Search {
    return Search.equals(prefix: "G=", values)
}

// Search by magazine
func magazine(_ values: String...) -> Search {
    return Search.equals(prefix: "TJ=", values)
}

// Search by document kind
func documentKind(_ values: String...) -> Search {
    return Search.equals(prefix: "V=", values)
}

// Search by UDC
func udc(_ values: String...) -> Search {
    return Search.equals(prefix: "U=", values)
}

// Search by BBK
func bbk(_ values: String...) -> Search {
    return Search.equals(prefix: "BBK=", values)
}

// Search by section of knowledge
func rzn(_ values: String...) -> Search {
    return Search.equals(prefix: "RZN=", values)
}

// Search by storage place
func mhr(_ values: String...) -> Search {
    return Search.equals(prefix: "MHR=", values)
}

