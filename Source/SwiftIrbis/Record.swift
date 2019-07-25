import Foundation

//=========================================================
// Subfield

/**
 * MARC record subfield.
 */
class SubField {
    var code: Character
    var value: String
    
    init() {
        self.code = "\0"
        self.value = ""
    }
    
    init(code: Character, value: String) {
        self.code = code
        self.value = value
    }
    
} // class SubField

//=========================================================
// Record field

class RecordField {
    var tag: Int
    var value: String
    var subfields: [SubField]
    
    init() {
        self.tag = 0
        self.value = ""
        self.subfields = []
    }
    
    init(tag: Int, value: String) {
        self.tag = tag
        self.value = value
        self.subfields = []
    }
    
    func add(code: Character, value: String) -> RecordField {
        let subfield = SubField(code: code, value: value)
        self.subfields.append(subfield)
        return self
    }
    
    func addNonEmpty(code: Character, value: String) -> RecordField {
        if !value.isEmpty {
            let subfield = SubField(code: code, value: value)
            self.subfields.append(subfield)
        }
        return self
    }
    
    func clear() -> RecordField {
        self.subfields.removeAll()
        return self
    }
    
} // class RecordField

//=========================================================
// MARC record

class MarcRecord {
    var database: String = ""
    var mfn: Int = 0
    var status: Int = 0
    var version: Int = 0
    var fields: [RecordField] = []
    
    func addField(tag: Int, value: String) -> MarcRecord {
        let field = RecordField(tag: tag, value: value)
        self.fields.append(field)
        return self;
    }
    
    func clear() -> MarcRecord {
        self.fields.removeAll()
        return self
    }
    
} // class MarcRecord
