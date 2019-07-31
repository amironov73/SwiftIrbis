import Foundation

//=========================================================
// Server statistics

/**
 * IRBIS64 server working statistics.
 */
class ServerStat: CustomStringConvertible, CustomDebugStringConvertible {

    var runningClients: [ClientInfo] = [] // Array of running clients.
    var clientCount: Int32 = 0 // Actual client count.
    var totalCommandCount: Int32 = 0 // Total command count.

    func parse(_ lines: [String]) {
        self.totalCommandCount = parseInt32(lines[0])
        self.clientCount = parseInt32(lines[1])
        let linesPerClient = Int(parseInt32(lines[2]))
        var shift = 3
        for _ in 1...self.clientCount {
            let client = ClientInfo()
            client.parse(lines, shift)
            self.runningClients.append(client)
            shift += (linesPerClient + 1)
        }
    } // func parse

    var description: String {
        return "\(clientCount) \(totalCommandCount) \(runningClients)"
    } // var description

    var debugDescription: String {
        return "ServerStat(runningClients: \(runningClients), clientCount: \(clientCount), totalCommandCount: \(totalCommandCount))"
    } // var debugDescription

} // class ServerStat
