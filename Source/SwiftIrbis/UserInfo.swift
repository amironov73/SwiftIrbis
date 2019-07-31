import Foundation

//=========================================================
// Information about registered user

/**
 * Information about registered user of the server
 * (according to client_m.mnu).
 */
class UserInfo: CustomStringConvertible, CustomDebugStringConvertible {
    
    var number:        String = "" // Just sequential number.
    var name:          String = "" // User login.
    var password:      String = "" // User password.
    var cataloger:     String = "" // Have access to Cataloger?
    var reader:        String = "" // Have access to Reader?
    var circulation:   String = "" // Have access to Circulation?
    var acquisitions:  String = "" // Have access to Acquisitions?
    var provision:     String = "" // Have access to Provision?
    var administrator: String = "" // Have access to Administrator?

    private func formatPair(_ prefix: String, _ value: String,
                            _ defaultValue: String) -> String {
        precondition(!prefix.isEmpty)
        precondition(!defaultValue.isEmpty)
        if sameString(value, defaultValue) {
            return ""
        }
        return "\(prefix)=\(value);"
    } // func formatPair

    /**
     * Encode to the text representation.
     */
    func encode() -> String {
        return self.name + "\n" +
                self.password + "\n" +
                formatPair("C", self.cataloger,     "irbisc.ini") + 
                formatPair("R", self.reader,        "irbisr.ini") + 
                formatPair("B", self.circulation,   "irbisb.ini") + 
                formatPair("M", self.acquisitions,  "irbism.ini") + 
                formatPair("K", self.provision,     "irbisk.ini") + 
                formatPair("A", self.administrator, "irbisa.ini"); 
    } // func encode

    /**
     * Parse the server response.
     */
    static func parse(_ lines: [String]) -> [UserInfo] {
        var result = [UserInfo]()
        let userCount = Int(parseInt32(lines[0]))
        let linesPerUser = Int(parseInt32(lines[1]))
        if userCount == 0 || linesPerUser == 0 {
            return result
        }
        result.reserveCapacity(userCount)
        var shift = 2
        for _ in 0..<userCount {
            if shift + 8 >= lines.count || lines[shift].isEmpty {
                break
            }
            let user = UserInfo()
            user.number        = lines[shift + 0]
            user.name          = lines[shift + 1]
            user.password      = lines[shift + 2]
            user.cataloger     = lines[shift + 3]
            user.reader        = lines[shift + 4]
            user.circulation   = lines[shift + 5]
            user.acquisitions  = lines[shift + 6]
            user.provision     = lines[shift + 7]
            user.administrator = lines[shift + 8]
            result.append(user)
            shift += (linesPerUser + 1)
        }
        return result
    } // func parse

    var description: String {
        return self.name
    } // var description

    var debugDescription: String {
        return self.name
    } // var debugDescription

} // class UserInfo
