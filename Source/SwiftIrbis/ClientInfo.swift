import Foundation

//=========================================================
// Information about connected client.

/**
 * Information about connected client
 * (not necessarily current client).
 */
class ClientInfo: CustomStringConvertible, CustomDebugStringConvertible {
    
    var number: String = "" // Just sequential number.
    var ipAddress: String = "" // Client IP address.
    var port: String = "" // Port number.
    var name: String = "" // User login.
    var id: String = "" // Client identifier (just unique number).
    var workstation: String = "" // Client software kind.
    var registered: String = "" // Registration moment.
    var acknowledged: String = "" // Last acknowledge moment.
    var lastCommand: String = "" // Last command issued.
    var commandNumber: String = "" // Last command number.
    
    func parse(_ lines: [String], _ shift: Int) {
        self.number = lines[shift + 0]
        self.ipAddress = lines[shift + 1]
        self.port = lines[shift + 2]
        self.name = lines[shift + 3]
        self.id = lines[shift + 4]
        self.workstation = lines[shift + 5]
        self.registered = lines[shift + 6]
        self.acknowledged = lines[shift + 7]
        self.lastCommand = lines[shift + 8]
        self.commandNumber = lines[shift + 9]
    } // func parse
    
    var description: String {
        return self.ipAddress
    } // var description
    
    var debugDescription: String {
        return "ClientInfo(ipAddress: \(ipAddress))"
    } // var debugDescription
    
} // class ClientInfo
