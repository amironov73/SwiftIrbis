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

let maxMfn = client.getMaxMfn(database: "IBIS")
print("Max MFN=\(maxMfn)")

_ = client.noOp()
print("NOP")

client.disconnect()
```