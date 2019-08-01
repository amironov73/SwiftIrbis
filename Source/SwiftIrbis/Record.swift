import Foundation

//=========================================================
// Subfield

/// MARC record subfield.
/// Consist of one-symbol code and text value.
public class SubField {
    
    /// One-symbol code of the subfield.
    public var code: Character
    
    /// String value of the subfield.
    public var value: String
    
    /// Default initializer.
    public init() {
        self.code = "\0"
        self.value = ""
    } // init
    
    /// Initializer.
    ///
    /// - Parameters:
    ///   - code: subfield code.
    ///   - value: subfield value (may be empty).
    public init(code: Character, value: String) {
        self.code = code
        self.value = value
    } // init

    /// Deep clone of the subfield.
    ///
    /// - Returns: cloned subfield.
    public func clone() -> SubField {
        return SubField(code: self.code, value: self.value)
    } // func clone
    
    /// Decode the subfield from protocol representation.
    ///
    /// - Parameter text: text line to decode (must be non-empty).
    public func decode(_ text: String) {
        precondition(!text.isEmpty)
        
        self.code = text.first!
        self.value = subStr(text, 1)
    } // func decode

    public var description: String {
        return "^\(code)\(value))"
    } // var description
    
    /// Verify the subfield.
    ///
    /// - Returns: sign of successs.
    public func verify() -> Bool {
        return self.code != "\0" && !self.value.isEmpty
    } // func verify

} // class SubField

//=========================================================
// Record field

/// MARC record field consist of tag, value and array of subfields.
public class RecordField {
    
    /// Numerical tag of the field.
    public var tag: Int32
    
    /// Text value of the field before first separator.
    /// May be empty.
    public var value: String
    
    /// Array of subfields. May be empty.
    public var subfields: [SubField]
    
    /// Default initializer.
    public init() {
        self.tag = 0
        self.value = ""
        self.subfields = []
    } // init
    
    /// Initializer.
    ///
    /// - Parameters:
    ///   - tag: field tag
    ///   - value: field text value (optional).
    public init(tag: Int32, value: String = "") {
        self.tag = tag
        self.value = value
        self.subfields = []
    } // init
    
    /// Append subfield with specified code and value to the field.
    ///
    /// - Parameters:
    ///   - code: subfield code.
    ///   - value: subfield value.
    /// - Returns: field itself allowing call chaining.
    public func append(code: Character, value: String) -> RecordField {
        let subfield = SubField(code: code, value: value)
        self.subfields.append(subfield)
        return self
    } // func append
    
    /// Append subfield with specified code and value
    /// only when value is non-empty.
    ///
    /// - Parameters:
    ///   - code: subfield code.
    ///   - value: subfield value.
    /// - Returns: field itself allowing call chaining.
    public func appendNonEmpty(code: Character, value: String) -> RecordField {
        if !value.isEmpty {
            let subfield = SubField(code: code, value: value)
            self.subfields.append(subfield)
        }
        return self
    } // func appendNonEmpty
    
    /// Clear the field (remove the value and all the subfields).
    ///
    /// - Returns: field itself.
    public func clear() -> RecordField {
        self.value = ""
        self.subfields.removeAll()
        return self
    } // func clear

    /// Deep clone of the field.
    ///
    /// - Returns: clone of the field.
    public func clone() -> RecordField {
        let result = RecordField(tag: self.tag, value: self.value)
        for subfield in self.subfields {
            result.subfields.append(subfield.clone())
        }
        return result
    } // func clone
    
    /// Decode body of the field from protocol representation.
    ///
    /// - Parameter text: text line with the field body (must be non-empty).
    public func decodeBody(_ text: String) {
        precondition(!text.isEmpty)
        
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

    /// Decode the field freom protocol representation
    ///
    /// - Parameter text: text line with the field (must be non-empty).
    public func decode(_ text: String) {
        precondition(!text.isEmpty)
        
        let parts = split2(text, separator: "#")
        self.tag = parseInt32(parts[0])
        self.decodeBody(parts[1])
    } // func decode
    
    public var description: String {
        return self.encode()
    } // var description

    public func encode() -> String {
        var result = "\(tag)#\(value)"
        for subfield in subfields {
            result += "\(subfield.code)^\(subfield.value)"
        }
        return result
    } // func encode
    
    /// Get array of embedded fields.
    ///
    /// - Returns: array of embedded fields.
    public func getEmbeddedFields() -> [RecordField] {
        var result = [RecordField]()
        var found: RecordField? = nil
        for subfield in self.subfields {
            if subfield.code == "1" {
                if let field = found {
                    if field.verify() {
                        result.append(field)
                    }
                    found = nil
                }
                let subfieldValue = subfield.value
                if subfieldValue.isEmpty {
                    continue
                }
                let tag = parseInt32(subStr(subfieldValue, 0, 3))
                found = RecordField(tag: tag)
                if tag < 10 {
                    found!.value = subStr(subfieldValue, 3)
                }
            } else {
                found?.subfields.append(subfield)
            }
        } // for
        
        if let field = found {
            if field.verify() {
                result.append(field)
            }
        } // if
        
        return result
    } // func getEmbeddedFields
    
    /// Get first occurrence of subfield with given code.
    ///
    /// - Parameter withCode: code to search for.
    /// - Returns: found subfield or `nil`.
    public func getFirstSubField(withCode code: Character) -> SubField? {
        for subfield in self.subfields {
            if sameChar(subfield.code, code) {
                return subfield
            }
        } // for
        
        return nil
    } // func getFirstSubField
    
    /// Get value of first subfield with given code.
    ///
    /// - Parameter withCode: code to search for.
    /// - Returns: value of found subfield or empty string.
    public func getFirstSubFieldValude(withCode code: Character) -> String {
        return self.getFirstSubField(withCode: code)?.value ?? ""
    } // func getFirstSubFieldValue
    
    /// Computes value for "^*".
    ///
    /// - Returns: computed value or empty string.
    public func getValueOrFirstSubField() -> String {
        var result = self.value
        if result.isEmpty {
            result = self.subfields.first?.value ?? ""
        }
        return result
    } // func getValueOrFirstSubField
    
    /// Do we have any subfield with given code?
    ///
    /// - Parameter withCode: code to search for.
    /// - Returns: `true` if we have the subfield.
    public func haveSubField(withCode codeToSearch: Character) -> Bool {
        for subfield in self.subfields {
            if sameChar(subfield.code, codeToSearch) {
                return true
            }
        } // for
        
        return false
    } // func haveSubField
    
    /// Remove subfield at given position.
    ///
    /// - Parameter position: position of the subfield to remove.
    /// - Returns: field itself allowing call chaining.
    public func removeAt(position: Int) -> RecordField {
        self.subfields.remove(at: position)
        return self
    } // func removeAt
    
    /// Remove all subfield with specified code.
    ///
    /// - Parameter withCode: subfield code to search for.
    /// - Returns: field itself allowing call chaining.
    public func removeSubField(withCode codeToSearch: Character) -> RecordField {
        var index = 0
        while index < self.subfields.count {
            if sameChar(self.subfields[index].code, codeToSearch) {
                _ = self.removeAt(position: index)
            } else {
                index += 1
            }
        } // while
        
        return self
    } // func removeSubField
    
    /// Replace value for subfields with specified code.
    ///
    /// - Parameters:
    ///   - code: code to search for.
    ///   - oldValue: old subfield value.
    ///   - newValue: new subfield value.
    /// - Returns: field itself allowing call chaining.
    public func replaceSubField(code: Character, oldValue: String, newValue: String) -> RecordField {
        for subfield in self.subfields {
            if sameChar(subfield.code, code) && sameString(subfield.value, oldValue) {
                subfield.value = newValue
            }
        } // for
        
        return self
    } // func replaceSubField
    
    /// Unconditionally set the value of first occurrence of subfield with given code.
    ///
    /// - Parameters:
    ///   - code: subfield code to search for.
    ///   - newValue: new value for the subfield.
    /// - Returns: field itself allowing call chaining.
    public func setSubField(code: Character, newValue: String) -> RecordField {
        if newValue.isEmpty {
            return self.removeSubField(withCode: code)
        }
        
        var found = self.getFirstSubField(withCode: code)
        if found == nil {
            found = SubField(code: code, value: value)
            self.subfields.append(found!)
        } // if
        found!.value = newValue
        
        return self
    } // func setSubField
    
    /// Verify the field.
    ///
    /// - Returns: `true` if the field is OK.
    public func verify() -> Bool {
        var result = self.tag != 0 && (!self.value.isEmpty || !self.subfields.isEmpty)
        if result && !self.subfields.isEmpty {
            for subfield in self.subfields {
                result = subfield.verify()
                if !result {
                    break
                }
            }
        } // if
        return result
    } // func verify
    
} // class RecordField

//=========================================================
// MARC record

/// MARC record consist of fields.
public class MarcRecord {
    
    /// Database name. Empty for just-created records.
    public var database: String = ""
    
    /// Masterfile number. Zero for just-created records.
    public var mfn: Int32 = 0
    
    /// Status of the record.
    /// See LOGICALLY_DELETED and other constants.
    /// Zero for just-created records.
    public var status: Int32 = 0
    
    /// Version number of the record.
    /// Zero for just created records, one for first-saved records.
    public var version: Int32 = 0
    
    /// Array of fields.
    public var fields: [RecordField] = []
    
    /// Append the field with given tag and value.
    ///
    /// - Parameters:
    ///   - tag: field tag.
    ///   - value: field value before first separator (may be empty).
    /// - Returns: record itself allowing call chaining.
    public func append(tag: Int32, value: String) -> MarcRecord {
        let field = RecordField(tag: tag, value: value)
        self.fields.append(field)
        return self;
    } // func append

    /// Apped the field only if the value is non-empty.
    ///
    /// - Parameters:
    ///   - tag: field tag.
    ///   - value: field value before first separator (may be empty).
    /// - Returns: record itself allowing call chaining.
    public func appendNonEmpty(tag: Int32, value: String) -> MarcRecord {
        if !value.isEmpty {
            return self.append(tag: tag, value: value)
        }
        return self
    } // func appendNonEmpty
    
    /// Clear the record by removing all the fields.
    ///
    /// - Returns: record itself allowing call chaining.
    public func clear() -> MarcRecord {
        self.fields.removeAll()
        return self
    } // func clear
    
    /// Create deep clone of the record.
    ///
    /// - Returns: clone of the record.
    public func clone() -> MarcRecord {
        let result = MarcRecord()
        result.database = self.database
        result.mfn = self.mfn
        result.version = self.version
        result.status = self.status
        result.fields.reserveCapacity(self.fields.count)
        for field in self.fields {
            result.fields.append(field.clone())
        }
        return result
    } // func clone

    /// Decode the record from the protocol representation.
    ///
    /// - Parameter lines: text lines to decode (must be non-empty array).
    public func decode(_ lines: [String]) {
        precondition(lines.count > 1)
        
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

    /// Determine whether the record is marked as deleted.
    public var deleted: Bool {
        return (self.status & 3) != 0
    } // var deleted

    public var description: String {
        return encode(delimiter: "\n")
    } // var description

    /// Encode the record to the protocol representation.
    ///
    /// - Parameter delimiter: <#delimiter description#>
    /// - Returns: <#return value description#>
    public func encode(delimiter: String = IRBIS_DELIMITER) -> String {
        var result = ""
        result += "\(mfn)#\(status)\(delimiter)"
        result += "0#\(version)\(delimiter)"
        for field in self.fields {
            result += field.encode()
            result += delimiter
        }
        return result
    } // func encode
    
    /// Get value of the field with given tag (or subfield if the code is given).
    ///
    /// - Parameters:
    ///   - tag: field tag.
    ///   - code: subfield code (optional).
    /// - Returns: value of the field or empty string if nothing was found.
    public func fm(_ tag: Int32, code: Character = "\0") -> String {
        for field in self.fields {
            if field.tag == tag {
                if code != "\0" {
                    for subfield in field.subfields {
                        if sameChar(subfield.code, code) {
                            if !subfield.value.isEmpty {
                                return subfield.value
                            }
                        }
                    }
                } else {
                    if !field.value.isEmpty {
                        return field.value
                    }
                }
            } // if
        } // for
        
        return ""
    } // func fm
    
    /// Get array of values of fields with given tag (or subfield values if the code is given).
    ///
    /// - Parameters:
    ///   - tag: field tag.
    ///   - code: subfield code (optional).
    /// - Returns: array of values.
    public func fma(_ tag: Int32, code: Character = "\0") -> [String] {
        var result = [String]()
        for field in self.fields {
            if field.tag == tag {
                if code != "\0" {
                    for subfield in field.subfields {
                        if sameChar(subfield.code, code) {
                            if !subfield.value.isEmpty {
                                result.append(subfield.value)
                            }
                        }
                    }
                } else {
                    if !field.value.isEmpty {
                        result.append(field.value)
                    }
                }
            } // if
        } // for
        
        return result
    } // func fma
    
    /// Get field by tag and occurrence number.
    ///
    /// - Parameters:
    ///   - withTag: field tag to search.
    ///   - occurrence: occurrence number.
    /// - Returns: found field or `nil`.
    public func getField(withTag tagToSearch: Int32, occurrence: Int=0) -> RecordField? {
        var index = occurrence
        for field in self.fields {
            if field.tag == tagToSearch {
                if index == 0 {
                    return field
                }
                index -= 1
            }
        } // for
        
        return nil
    } // func getField
    
    /// Get array of fields with given tag.
    ///
    /// - Parameter withTag: field tag to search.
    /// - Returns: array of found fields.
    public func getFields(withTag tagToSearch: Int32) -> [RecordField] {
        var result = [RecordField]()
        for field in self.fields {
            if field.tag == tagToSearch {
                result.append(field)
            }
        } // for
        return result
    } // func getFields
    
    /// Do we have any field with specified tag?
    ///
    /// - Parameter withTag: `true` if we have the field.
    public func haveField(withTag tagToSearch: Int32) -> Bool {
        for field in self.fields {
            if field.tag == tagToSearch {
                return true
            }
        } // for
        
        return false
    } // func haveField
    
    /// Do we have any subfield with specified tag and code?
    ///
    /// - Parameters:
    ///   - withTag: field tag to search for.
    ///   - andCode: subfield code to search for.
    /// - Returns: `true` if we have the subfield.
    public func haveSubField(withTag tagToSearch: Int32, andCode codeToSearch: Character) -> Bool {
        for field in self.fields {
            if field.tag == tagToSearch {
                for subfield in field.subfields {
                    if sameChar(subfield.code, codeToSearch) {
                        return true
                    }
                } // for
            } // if
        } // for
        
        return false
    } // func haveSubField
    
    /// Insert the field at specified index.
    ///
    /// - Parameters:
    ///   - at: at the index.
    ///   - field: field to insert.
    /// - Returns: record itself allowing call chaining.
    public func insertAt(at index: Int, field: RecordField) -> MarcRecord {
        self.fields.insert(field, at: index)
        return self
    } // func insertAt
    
    /// Remove field at specified index.
    ///
    /// - Parameter at: at the index.
    /// - Returns: record itself allowing call chaining.
    public func removeAt(at index: Int) -> MarcRecord {
        self.fields.remove(at: index)
        return self
    } // func removeAt
    
    /// Remove all fields with specified tag.
    ///
    /// - Parameter withTag: field tag to search for.
    /// - Returns: record itself allowing call chaining.
    public func removeField(withTag tagToSearch: Int32) -> MarcRecord {
        var index = 0
        while index < fields.count {
            if fields[index].tag == tagToSearch {
                _ = self.removeAt(at: index)
            } else {
                index += 1
            }
        } // while
        return self
    } // func removeField
    
    /// Reset the record state, unbind it from the database.
    /// Fields remains untouched.
    ///
    /// - Returns: record itself allowing call chaining.
    public func reset() -> MarcRecord {
        self.mfn = 0
        self.status = 0
        self.version = 0
        self.database = ""
        return self
    } // func reset
    
    /// Set value of first occurrence of the field.
    ///
    /// - Parameters:
    ///   - withTag: field tag to search.
    ///   - newValue: new value for the field.
    /// - Returns: record itself allowing call chaining.
    public func setField(withTag tagToSearch: Int32, newValue: String?) -> MarcRecord {
        if let text = newValue {
            var field = self.getField(withTag: tagToSearch)
            if field == nil {
                field = RecordField(tag: tagToSearch, value: text)
                self.fields.append(field!)
            }
            field!.value = newValue!
        } else {
            _ = self.removeField(withTag: tagToSearch)
        }
        return self
    } // func setField
    
    /// Set value of first occurrence of the subfield.
    ///
    /// - Parameters:
    ///   - withTag: field tag to search.
    ///   - andCode: subfield code to search.
    ///   - newValue: new value for the subfield.
    /// - Returns: record itself allowing call chaining.
    public func setSubField(withTag tagToSearch: Int32, andCode codeToSearch: Character, newValue: String?) -> MarcRecord {
        var field = getField(withTag: tagToSearch)
        if field == nil {
            field = RecordField(tag: tagToSearch)
            self.fields.append(field!)
        }
        _ = field!.setSubField(code: codeToSearch, newValue: newValue!)
        return self
    } // func setSubField
    
    /// Verify all the fields of the record.
    ///
    /// - Returns: `true` if record is OK.
    public func verify() -> Bool {
        if self.fields.isEmpty {
            return false
        }
        
        for field in self.fields {
            if !field.verify() {
                return false
            }
        } // for
        
        return true
    } // func verify

} // class MarcRecord

//=========================================================
// Half-parsed record

/// Half-parsed record. Consist of fields.
public class RawRecord {
    
    /// Database name.
    public var database: String = ""
    
    /// Masterfile number of the record.
    public var mfn: Int32 = 0
    
    /// Version number of the record.
    public var version: Int32 = 0
    
    /// Status of the record.
    public var status: Int32 = 0
    
    /// Array of fields.
    public var fields: [String] = []
    
    /// Append the field to the record.
    ///
    /// - Parameters:
    ///   - tag: field tag number.
    ///   - value: field value (must be non-empty).
    /// - Returns: record itself allowing call chaining.
    public func append(tag: Int32, value: String) -> RawRecord {
        precondition(!value.isEmpty)
        
        let text = "\(tag)#\(value)"
        self.fields.append(text)
        
        return self
    } // func append
    
    
    /// Creates deep clone of the record.
    ///
    /// - Returns: clone of the record.
    public func clone() -> RawRecord {
        let result = RawRecord()
        result.database = self.database
        result.mfn = self.mfn
        result.version = self.version
        result.status = self.version
        result.fields = self.fields
        return result
    } // func clone
    
    /// Decode the record from text representation.
    ///
    /// - Parameter lines: text lines to decode.
    /// - Returns: sign of success.
    public func decode(_ lines: [String]) -> Bool {
        precondition(lines.count > 2)
        let firstLine = split2(lines[0], separator: "#")
        self.mfn = parseInt32(firstLine[0])
        self.status = parseInt32(safeGet(firstLine, 1))
        let secondLine = split2(lines[1], separator: "#")
        self.version = parseInt32(safeGet(secondLine, 1))
        self.fields = Array(lines[2...])
        return true
    } // func decode
    
    /// Determines whether the record is marked as deleted.
    public var deleted: Bool {
        return (self.status & 3) != 0
    } // var deleted
    
    public var description: String {
        return self.encode(separator: "\n")
    } // var description
    
    /// Encode the record to text representation.
    ///
    /// - Parameter separator: line separator.
    /// - Returns: encoded record.
    public func encode(separator: String = IRBIS_DELIMITER) -> String {
        var result = "\(self.mfn)#\(self.status)\(separator)"
        result.append("0#\(self.version)\(separator)")
        for field in self.fields {
            result.append("\(field)\(separator)")
        }
        return result
    } // func encode
    
    /// Insert the field at specified position.
    ///
    /// - Parameters:
    ///   - position: position.
    ///   - field: field.
    /// - Returns: record itself allowing call chaining.
    public func insertAt(position: Int, field: String) -> RawRecord {
        self.fields.insert(field, at: position)
        return self
    } // func insertAt
    
    /// Remove the field at specified position.
    ///
    /// - Parameter position: position.
    /// - Returns: record itself allowing call chaining.
    public func removeAt(position: Int) -> RawRecord {
        self.fields.remove(at: position)
        return self
    } // func removeAt
    
    /// Reset the record state, unbind it from database.
    /// Fields remains untouched.
    ///
    /// - Returns: record itself allowing call chaining.
    public func reset() -> RawRecord {
        self.database = ""
        self.mfn = 0
        self.status = 0
        self.version = 0
        return self
    } // func reset
    
    /// Convert to MarcRecord.
    ///
    /// - Returns: converted record.
    public func toMarcRecord() -> MarcRecord {
        let result = MarcRecord()
        result.database = self.database
        result.mfn = self.mfn
        result.status = self.status
        result.version = self.version
        result.fields.reserveCapacity(self.fields.count)
        for line in self.fields {
            let field = RecordField()
            field.decode(line)
            result.fields.append(field)
        }
        return result
    } // func toMarcRecord
    
} // class RawRecord
