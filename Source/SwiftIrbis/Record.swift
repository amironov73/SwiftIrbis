import Foundation

//=========================================================
// Subfield

/**
 * MARC record subfield.
 */
public class SubField: CustomStringConvertible {
    
    /// One-symbol code of the subfield.
    public var code: Character
    
    /// String value of the subfield.
    public var value: String
    
    public init() {
        self.code = "\0"
        self.value = ""
    } // init
    
    public init(code: Character, value: String) {
        self.code = code
        self.value = value
    } // init

    /**
     * Decode the subfield from protocol representation.
     */
    func decode(_ text: String) {
        self.code = text.first!
        self.value = subStr(text, 1)
    } // func decode

    public var description: String {
        return "^\(code)\(value))"
    } // var description

} // class SubField

//=========================================================
// Record field

/**
 * Field consist of a value and subfields.
 */
public class RecordField {
    
    public var tag: Int32 // Numerical tag of the field.
    public var value: String // String value of the field.
    public var subfields: [SubField] // Subfields.
    
    public init() {
        self.tag = 0
        self.value = ""
        self.subfields = []
    } // init
    
    public init(tag: Int32, value: String = "") {
        self.tag = tag
        self.value = value
        self.subfields = []
    } // init
    
    func add(code: Character, value: String) -> RecordField {
        let subfield = SubField(code: code, value: value)
        self.subfields.append(subfield)
        return self
    } // func add
    
    func addNonEmpty(code: Character, value: String) -> RecordField {
        if !value.isEmpty {
            let subfield = SubField(code: code, value: value)
            self.subfields.append(subfield)
        }
        return self
    } // func addNonEmpty
    
    func clear() -> RecordField {
        self.value = ""
        self.subfields.removeAll()
        return self
    } // func clear

    func decodeBody(text: String) {
        let all = text.split(separator: "^")
        var shift = 0
        if text.first! != "^" {
            self.value = String(all[0])
            shift = 1
        }
        for one in all[shift..<all.count] {
            if !one.isEmpty {
                let subfield = SubField()
                subfield.decode(String(one))
                self.subfields.append(subfield)
            }
        }
    } // func decodeBody

    func decode(_ text: String) {
        let parts = split2(text, separator: "#")
        self.tag = parseInt32(parts[0])
        self.decodeBody(text: String(parts[1]))
    } // func decode

    func encode() -> String {
        var result = "\(tag)#\(value)"
        for subfield in subfields {
            result += "\(subfield.code)^\(subfield.value)"
        }
        return result
    } // func encode

} // class RecordField

//=========================================================
// MARC record

public class MarcRecord {
    
    public var database: String = ""
    public var mfn: Int32 = 0
    public var status: Int32 = 0
    public var version: Int32 = 0
    public var fields: [RecordField] = []
    
    func append(tag: Int32, value: String) -> MarcRecord {
        let field = RecordField(tag: tag, value: value)
        self.fields.append(field)
        return self;
    } // func append

    func appendNonEmpty(tag: Int32, value: String) -> MarcRecord {
        if !value.isEmpty {
            return self.append(tag: tag, value: value)
        }
        return self
    } // func appendNonEmpty
    
    func clear() -> MarcRecord {
        self.fields.removeAll()
        return self
    } // func clear

    func decode(_ lines: [String]) {
        let firstLine = split2(lines[0], separator: "#")
        self.mfn = parseInt32(firstLine[0])
        self.status = parseInt32(safeGet(firstLine, 1))
        let secondLine = split2(lines[1], separator: "#")
        self.version = parseInt32(safeGet(secondLine, 1))
        for i in  2..<lines.count {
            let line = lines[i]
            if !line.isEmpty {
                let field = RecordField()
                field.decode(line)
                self.fields.append(field)
            }
        } // for
    } // func decode

    public var deleted: Bool {
        return (self.status & 3) != 0
    } // var deleted

    public var description: String {
        return encode(delimiter: "\n")
    } // var description

    func encode(delimiter: String = IRBIS_DELIMITER) -> String {
        var result = ""
        result += "\(mfn)#\(status)\(delimiter)"
        result += "0#\(version)\(delimiter)"
        for field in self.fields {
            result += field.encode()
            result += delimiter
        }
        return result
    } // func encode

} // class MarcRecord
