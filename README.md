# SwiftIrbis

ManagedClient ported to Swift 5

### Build status

[![Build status](https://api.travis-ci.org/amironov73/SwiftIrbis.svg)](https://travis-ci.org/amironov73/SwiftIrbis/)

Now supports:

* Xcode 10.3 (AppCode 2019.2)
* Swift 5.0
* OS X 10.14

Sample code

```swift
let client = Connection()
client.host = "localhost"
client.username = "librarian"
client.password = "secret"

if !client.connect() {
    print("Can't connect!")
    exit(1)
}

print("Server version=\(client.serverVersion)")
print("Interval=\(client.interval)")

let version = client.getServerVersion()
print("Licence: \(version.organization)")
print("Max clients=\(version.maxClients)")

let processes = client.listProcesses()
print("Processes: \(processes)")

let serverStat = client.getServerStat()
print("Server stat: \(serverStat)")

let maxMfn = client.getMaxMfn(database: "IBIS")
print("Max MFN=\(maxMfn)")

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

client.disconnect()
```