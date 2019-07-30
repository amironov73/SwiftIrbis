import Foundation

func dataToArray(_ data: Data) -> [UInt8] {
    var result = [UInt8](repeating: 0, count: data.count)
    data.withUnsafeBytes { ptr in
        for i in 0..<data.count {
            result[i] = ptr[i]
        }
    }
    return result
} // func dataToArray

func fromAnsi(_ bytes: Data) -> String {
    return String(data: bytes, encoding: .windowsCP1251)!
} // func fromAnsi

func fromUtf(_ bytes: Data) -> String {
    return String(data: bytes, encoding: .utf8)!
} // func fromUtf

func irbisToLines(_ text: String) -> [String] {
    return text.components(separatedBy: IRBIS_DELIMITER)
} // func irbisToLines

func irbisToUnix(_ text: String) -> String {
    return text.replacingOccurrences(of: IRBIS_DELIMITER, with: UNIX_DELIMITER)
} // func irbisToUnix

func parseInt32(_ text: String) -> Int32 {
    var result: Int32 = 0
    for c in text {
        result = result * 10 + Int32(c.asciiValue!) - 48
    }
    return result;
} // func parseInt32

func parseInt32(_ substring: String.SubSequence) -> Int32 {
    var result: Int32 = 0
    for c in substring {
        result = result * 10 + Int32(c.asciiValue!) - 48
    }
    return result;
} // func parseInt32

func pickOne(_ lines: String...) -> String {
    for line in lines {
        if !line.isEmpty {
            return line
        }
    }
    // TODO throw
    return ""
} // func pickOne

func prepareFormat(format: String) -> String {
    // TODO implement
    return format
} // func prepareFormat

func removeComments(format: String) -> String {
    // TODO implement
    return format
} // func removeComments

func safeGet(_ lines: [String], _ index: Int) -> String {
    if index >= lines.count {
        return ""
    }
    return lines[index]
} // func safeGet

func sameChar(_ a: Character, _ b: Character) -> Bool {
    return a.uppercased() == b.uppercased()
} // func sameChar

func sameString(_ a: String, _ b: String) -> Bool {
    return a.caseInsensitiveCompare(b) == .orderedSame
} // func sameString

func split2(_ text: String, separator: Character) -> [String] {
    var result = [String]()
    let parts = text.split(separator: separator, maxSplits: 1)
    result.append(String(parts[0]))
    if parts.count != 1 {
        result.append(String(parts[1]))
    }
    return result
} // func split2

func splitN(_ text: String, _ delimiter: String, limit: Int) -> [String] {
    var result = [String]()
    var chunk = text
    while (limit > 1) {
        // TODO implement
    }
    return result
} // func splitN

func subStr(_ text: String, _ start: Int, _ length: Int) -> String {
    let offset1 = text.index(text.startIndex, offsetBy: start)
    let offset2 = text.index(offset1, offsetBy: length)
    let result = text[offset1..<offset2]
    return String(result)
} // func subStr

func subStr(_ text: String, _ start: Int) -> String {
    let length = text.count - start
    let offset1 = text.index(text.startIndex, offsetBy: start)
    let offset2 = text.index(offset1, offsetBy: length)
    let result = text[offset1..<offset2]
    return String(result)
} // func subStr

func subSub(_ text: String, _ start: Int, _ length: Int) -> Substring {
    let offset1 = text.index(text.startIndex, offsetBy: start)
    let offset2 = text.index(offset1, offsetBy: length)
    let result = text[offset1..<offset2]
    return result
} // func subSub

func toAnsi(_ text: String) -> Data {
    return text.data(using: .windowsCP1251)!
} // func toAnsi

func toUtf(_ text: String) -> Data {
    return text.data(using: .utf8)!
} // func toUtf

func trim(_ text: String) -> String {
    return text.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
} // func trim
