import Foundation

/// Wrapper for BSD client socket.
public class ClassicSocket {

    /// Host name or IP-address.
    public var host: String

    /// Host port number.
    public var port: UInt16

    /// Socket handle.
    private var handle: Int32

    /// Whether the socket was closed?
    private(set) public var closed: Bool

    /// Initializer
    ///
    /// - Parameters:
    ///    - host: host name or IP-address.
    ///    - port: port number.
    public init(host: String, port: UInt16) {
        self.closed = false

        self.host = host
        self.port = port
        self.handle = socket(AF_INET, SOCK_STREAM, 0)

        var addr: sockaddr_in = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_addr.s_addr = inet_addr(self.host)
        addr.sin_port = self.port
        //Darwin.connect(self.handle, &addr)

    } // init

    deinit {
        self.close()
    } // deinit

    /// Close the socket.
    public func close() {
        if !self.closed {
            Darwin.close(self.handle)
            self.closed = true
        }
    } // func close

    /// Read the data.
    public func recv() -> Data {
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 2048)
        while true {
            let read = Darwin.recv(self.handle, &buffer, buffer.capacity, 0)
            if read <= 0 {
                break
            }
            result.append(contentsOf: buffer[0..<read])
        } // while
        return result
    } // func recv

    /// Write the data.
    public func send(data: [UInt8]) {
        Darwin.send(self.handle, data, data.count, 0)
    } // func write

} // class ClassicSocket
