//
//  Network.swift
//  VideoSync
//
//  Created by ton252 on 09.04.2024.
//

import Network

class Server {
    let port: NWEndpoint.Port = 3000
    var onReady: (() -> ())? = nil
    var listener: NWListener?
    var connections: [NWEndpoint: NWConnection] = [:]

    var ipAddress: String {
        return localIPAdress() ?? ""
    }

    var fullAddress: String {
        return "\(ipAddress):\(port)"
    }

    init() {
        startListening(onPort: port)
    }

    func startListening(onPort port: NWEndpoint.Port) {
        do {
            listener = try NWListener(using: .tcp, on: port)
        } catch {
            print("Unable to start listener: \(error.localizedDescription)")
            return
        }
        
        listener?.stateUpdateHandler = { state in
            print("Listener state: \(state)")
            if state == .ready {
                self.onReady?()
            }
        }
        
        listener?.newConnectionHandler = { newConnection in
            self.connections[newConnection.endpoint] = newConnection
            self.handleConnection(connection: newConnection)
        }
        
        listener?.start(queue: .main)
    }
    
    func handleConnection(connection: NWConnection) {
        connection.start(queue: .main)
        receiveMessage(connection: connection)
    }
    
    func receiveMessage(connection: NWConnection) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { (data, _, isComplete, error) in
            if let data = data, !data.isEmpty {
                let message = String(data: data, encoding: .utf8)
                print("Received message: \(message ?? "unknown")")
            }
            
            if isComplete || error != nil {
                self.connections.removeValue(forKey: connection.endpoint)
                connection.cancel()
                return
            }
            
            self.receiveMessage(connection: connection)
        }
    }

    // Function to send a message to a specific client connection
    private func sendMessage(_ message: String, to connection: NWConnection) {
        guard let data = message.data(using: .utf8) else { return }
        
        connection.send(content: data, completion: .contentProcessed({ error in
            if let error = error {
                print("Failed to send message: \(error.localizedDescription)")
                return
            }
            print("Message sent to client")
        }))
    }
}

func localIPAdress() -> String? {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
    if getifaddrs(&ifaddr) == 0 {
        var ptr = ifaddr
        while ptr != nil {
            let flags = Int32(ptr!.pointee.ifa_flags)
            if let addr = ptr?.pointee.ifa_addr {
                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                    if addr.pointee.sa_family == UInt8(AF_INET) || addr.pointee.sa_family == UInt8(AF_INET6) {
                        // Convert interface address to a human readable string:
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        let addrSize = addr.pointee.sa_family == AF_INET ? MemoryLayout<sockaddr_in>.size : MemoryLayout<sockaddr_in6>.size
                        if getnameinfo(addr, socklen_t(addrSize), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            if let addressString = String(validatingUTF8: hostname) {
                                address = addressString
                                break
                            }
                        }
                    }
                }
            }
            ptr = ptr?.pointee.ifa_next
        }
        freeifaddrs(ifaddr)
    }
    return address
}
