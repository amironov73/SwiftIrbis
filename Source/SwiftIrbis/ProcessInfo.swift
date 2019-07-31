import Foundation

//=========================================================
// Process info

/**
 * Information about server process.
 */
class ProcessInfo: CustomStringConvertible, CustomDebugStringConvertible {
    
    var number: String = "" // Just sequential number.
    var ipAddress: String = "" // Client IP address.
    var name: String = "" // User name.
    var clientId: String = "" // Client identifier.
    var workstation: String = "" // Workstation kind.
    var started: String = "" // Started at.
    var lastCommand: String = "" // Last executed command.
    var commandNumber: String = "" // Command number.
    var processId: String = "" // Process identifier.
    var state: String = "" // Process state.
    
    static func parse(_ lines: [String]) -> [ProcessInfo] {
        var result = [ProcessInfo]()
        if lines.isEmpty {
            return result
        }
        
        let processCount = Int(parseInt32(lines[0]))
        let linesPerProcess = Int(parseInt32(lines[1]))
        if processCount == 0 || linesPerProcess == 0 {
            return result
        }
        
        result.reserveCapacity(processCount)
        var shift = 2
        for _ in 1...processCount {
            let process = ProcessInfo()
            process.number = lines[shift + 0]
            process.ipAddress = lines[shift + 1]
            process.name = lines[shift + 2]
            process.clientId = lines[shift + 3]
            process.workstation = lines[shift + 4]
            process.started = lines[shift + 5]
            process.lastCommand = lines[shift + 6]
            process.commandNumber = lines[shift + 7]
            process.processId = lines[shift + 8]
            process.state = lines[shift + 9]
            result.append(process)
            shift += (linesPerProcess + 1)
        } // for
        
        return result
    } // func parse
    
    var description: String {
        return "\(number) \(ipAddress) \(name)"
    } // var description
    
    var debugDescription: String {
        return "ProcessInfo(number: \(number), ipAddress: \(ipAddress), name: \(name))"
    } // var debugDescription
    
} // class ProcessInfo
