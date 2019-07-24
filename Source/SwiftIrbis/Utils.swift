import Foundation

func parseInt32(_ text: String) -> Int32 {
    var result: Int32 = 0
    for c in text {
        result = result * 10 + Int32(c.asciiValue!) - 48
    }
    return result;
}

func parseInt32(_ substring: String.SubSequence) -> Int32 {
    var result: Int32 = 0
    for c in substring {
        result = result * 10 + Int32(c.asciiValue!) - 48
    }
    return result;
}

func toAnsi(_ text: String) -> Data {
    return text.data(using: .windowsCP1251)!
}

func toUtf(_ text: String) -> Data {
    return text.data(using: .utf8)!
}

func fromAnsi(_ bytes: Data) -> String {
    return String(data: bytes, encoding: .windowsCP1251)!
}

func fromUtf(_ bytes: Data) -> String {
    return String(data: bytes, encoding: .utf8)!
}

func subStr(_ text: String, _ start: Int, _ length: Int) -> String {
    let offset1 = text.index(text.startIndex, offsetBy: start)
    let offset2 = text.index(offset1, offsetBy: length)
    let result = text[offset1..<offset2]
    return String(result)
}

func subSub(_ text: String, _ start: Int, _ length: Int) -> Substring {
    let offset1 = text.index(text.startIndex, offsetBy: start)
    let offset2 = text.index(offset1, offsetBy: length)
    let result = text[offset1..<offset2]
    return result
}
