import Foundation

//=========================================================
// Client socket

public class ClientSocket {
    
    public func talkToServer(query: ClientQuery) -> ServerResponse {
        let connection = query.connection
        let client = TcpClient(host: connection.host, port: connection.port)
        client.connect()
        let outputData = query.encode()
        let outputPacket = Array(outputData)
        client.send(packet: outputPacket)
        let inputPacket = client.receive()
        client.close()
        let result = ServerResponse(inputPacket)
        return result
    } // func talkToServer
    
} // class ClientSocket
