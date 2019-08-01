import Foundation

//=========================================================
// Constants

// Record status

public let LOGICALLY_DELETED  = 1  // Logically deleted record
public let PHYSICALLY_DELETED = 2  // Physically deleted record
public let ABSENT             = 4  // Record is absent
public let NON_ACTUALIZED     = 8  // Record is not actualized
public let LAST_VERSION       = 32 // Last version of the record
public let LOCKED_RECORD      = 64 // The record is locked

// Common formats

public let ALL_FORMAT       = "&uf('+0')" // Full data by all the fields
public let BRIEF_FORMAT     = "@brief"    // Short bibliographical description
public let IBIS_FORMAT      = "@ibisw_h"  // Old IBIS format
public let INFO_FORMAT      = "@info_w"   // Informational format
public let OPTIMIZED_FORMAT = "@"         // Optimized format

// Common search prefixes

public let KEYWORD_PREFIX    = "K="  // Keywords
public let AUTHOR_PREFIX     = "A="  // Individual author, editor, compiler
public let COLLECTIVE_PREFIX = "M="  // Collective author or event
public let TITLE_PREFIX      = "T="  // Title
public let INVENTORY_PREFIX  = "IN=" // Inventory number, barcode or RFID tag
public let INDEX_PREFIX      = "I="  // Document index

// Logical operators for search
let LOGIC_OR                = 0 // OR only
let LOGIC_OR_AND            = 1 // OR or AND
let LOGIC_OR_AND_NOT        = 2 // OR, AND or NOT (default)
let LOGIC_OR_AND_NOT_FIELD  = 3 // OR, AND, NOT, AND in field
let LOGIC_OR_AND_NOT_PHRASE = 4 // OR, AND, NOT, AND in field, AND in phrase

// Workstation codes

public let ADMINISTRATOR = "A"
public let CATALOGER     = "C"
public let ACQUISITIONS  = "M"
public let READER        = "R"
public let CIRCULATION   = "B"
public let BOOKLAND      = "B"
public let PROVISION     = "K"

// Commands for global correction

let ADD_FIELD        = "ADD"    // Add field
let DELETE_FIELD     = "DEL"    // Delete field
let REPLACE_FIELD    = "REP"    // Replace field
let CHANGE_FIELD     = "CHA"    // Change field value
let CHANGE_WITH_CASE = "CHAC"   // Change field value with case sensitivity
let DELETE_RECORD    = "DELR"   // Delete record
let UNDELETE_RECORD  = "UNDELR" // Recover (undelete) record
let CORRECT_RECORD   = "CORREC" // Correct record
let CREATE_RECORD    = "NEWMFN" // Create new record
let EMPTY_RECORD     = "EMPTY"  // Empty the record
let UNDO_RECORD      = "UNDOR"  // Revert the record to previous version
let GBL_END          = "END"    // Closing operator bracket
let GBL_IF           = "IF"     // Conditional statement start
let GBL_FI           = "FI"     // Conditional statement end
let GBL_ALL          = "ALL"    // All
let GBL_REPEAT       = "REPEAT" // Repeat operator
let GBL_UNTIL        = "UNTIL"  // Until condition
let PUTLOG           = "PUTLOG" // Save logs to file

// Line delimiters

public let IRBIS_DELIMITER = "\u{1F}\u{1E}" // IRBIS line delimiter
public let SHORT_DELIMITER = "\u{1E}"       // Short version of line delimiter
public let SHORT_DELIMITER_CHAR: Character = "\u{1E}"
public let ALT_DELIMITER   = "\u{1F}"       // Alternative version of line delimiter
public let ALT_DELIMITER_CHAR: Character = "\u{1F}"
public let UNIX_DELIMITER  = "\n"           // Standard UNIX line delimiter
