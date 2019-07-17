# SwiftIrbis

ManagedClient ported to Swift 5

Now supports:

* Xcode 10.2
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

let maxMfn = client.getMaxMfn(database: "IBIS")
print("Max MFN=\(maxMfn)")

client.noOp()
print("NOP")

client.disconnect()
```