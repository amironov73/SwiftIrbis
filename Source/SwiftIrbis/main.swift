/*
 * ManagedClient ported to Swift 5.
 */

import Foundation

let client = Connection()
client.host = "192.168.7.36"
client.username = "librarian"
client.password = "secret"

let state = client.connect()
if case .failure(let error) = state {
    print("Can't connect! Error: \(error)")
    exit(1)
}

print("Server version=\(client.serverVersion)")
print("Interval=\(client.interval)")

let ini = client.ini
let dbnnamecat = ini.getValue(sectionName: "Main", keyName: "DBNNAMECAT", defaultValue: "???")
print("DBNNAMECAT=\(dbnnamecat)")

let version = client.getServerVersion()
print("Licence: \(version.organization)")
print("Max clients=\(version.maxClients)")

let processes = client.listProcesses()
print("Processes: \(processes)")

let serverStat = client.getServerStat()
print("Server stat: \(serverStat)")

let users = client.getUserList()
print("Users: \(users)")

let maxMfn = client.getMaxMfn(database: "IBIS")
print("Max MFN=\(maxMfn)")

let formatted = client.formatRecord("@brief", mfn: 1)
print("Formatted: \(formatted)")

let record = client.readRecord(1)!
print("Record: \(record)", terminator: "")

let files = client.listFiles("3.IBIS.brief.*", "3.IBIS.a*.pft")
print("Files: \(files)")

let foundMfn = client.search(expression: "K=бетон$")
print("Found MFN: \(foundMfn)")

let foundRecords = client.searchRead("K=бетон$", limit: 3)
print("Found records: \(foundRecords)")

let searchCount = client.searchCount("K=бетон$")
print("Search count=\(searchCount)")

_ = client.noOp()
print("NOP")

_ = client.disconnect()

print("THAT'S ALL FOLKS!")
