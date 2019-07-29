import Foundation

class TcpClient {
    var host: String
    var port: UInt16
    
    private var inputStream: InputStream!
    private var outputStream: OutputStream!
    
    init(host: String, port: UInt16) {
        self.host = host
        self.port = port
        self.inputStream = nil
        self.outputStream = nil
    }
    
    func connect() {
        Stream.getStreamsToHost(withName: self.host, port: Int(self.port), inputStream: &inputStream, outputStream: &outputStream)
        self.inputStream.open()
        self.outputStream.open()
    }
    
    func close() {
        self.inputStream.close()
        self.outputStream.close()
    }
    
    func send(packet: [UInt8]) {
        self.outputStream.write(packet, maxLength: packet.count)
    }
    
    func receive() -> Data {
        var result = Data()
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        while(true) {
            let bytesRead = inputStream.read(&buffer, maxLength: bufferSize)
            if bytesRead <= 0 {
                break;
            }
            result.append(contentsOf: buffer[0..<bytesRead])
        }
        return result
    }
}
