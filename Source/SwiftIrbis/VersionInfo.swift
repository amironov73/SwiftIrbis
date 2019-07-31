import Foundation

//=========================================================
// Version info

/**
 * Information about the IRBIS64 server version
 */
class VersionInfo {
    
    var organization: String = "";
    var version: String = "";
    var maxClients: Int32 = 0;
    var connectedClients: Int32 = 0;
    
    func parse(_ lines: [String]) {
        if (lines.count == 3) {
            self.version = lines[0]
            self.connectedClients = parseInt32(lines[1])
            self.maxClients = parseInt32(lines[2])
        } else {
            self.organization = lines[0]
            self.version = lines[1]
            self.connectedClients = parseInt32(lines[2])
            self.maxClients = parseInt32(lines[3])
        }
    } // func parse
    
} // class VersionInfo
