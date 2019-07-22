import Foundation

class Search {

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

