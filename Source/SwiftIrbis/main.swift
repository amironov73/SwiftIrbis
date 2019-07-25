/*
 * ManagedClient ported to Swift 5.
 */

import Foundation

let client = Connection()
client.host = "192.168.7.17"
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

_ = client.noOp()
print("NOP")

_ = client.disconnect()

print("THAT'S ALL FOLKS!")
