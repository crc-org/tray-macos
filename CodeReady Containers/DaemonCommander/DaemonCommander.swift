//
//  DaemonCommander.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 21/11/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//

import Socket

class DaemonCommander {
    var daemonSocket: Socket? = nil
    var socketPath: String
    static var bufferSize = 1024
    
    init(sockPath: String) {
        self.socketPath = sockPath
    }
    
    deinit {
        self.daemonSocket?.close()
    }
    // connect sets up the socket and connects to the daemon sokcet
    public func connectToDaemon() {
        do {
            // Create an Unix socket...
            try self.daemonSocket = Socket.create(family: .unix, type: .stream, proto: .unix)
            guard let socket = self.daemonSocket else {
                print("Unable to unwrap socket...")
                return
            }
            self.daemonSocket = socket
            try socket.connect(to: self.socketPath)
        } catch let error {
            guard error is Socket.Error else {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    public func sendCommand(command: Data) {
        do {
            try self.daemonSocket?.write(from: command)
        } catch let error {
            guard error is Socket.Error else {
                print(error.localizedDescription)
                return
            }
        }
    }
    
    public func readResponse() -> Data {
        do {
            var readData = Data(capacity: DaemonCommander.bufferSize)
            let bytesRead = try self.daemonSocket?.read(into: &readData)
            if bytesRead! > 1 {
                return readData
            }
        } catch let error {
            guard error is Socket.Error else {
                print(error.localizedDescription)
                return "Failed".data(using: .utf8)!
            }
        }
        return "Failed".data(using: .utf8)!
    }
}

let userHomePath: URL = FileManager.default.homeDirectoryForCurrentUser
let socketPath: URL = userHomePath.appendingPathComponent(".crc").appendingPathComponent("crc.sock")

func SendCommandToDaemon(command: Request) -> Data? {
    do {
        let req = try JSONEncoder().encode(command)
        print(req)
        let daemonConnection = DaemonCommander(sockPath: socketPath.path)
        print(socketPath.path)
        daemonConnection.connectToDaemon()
        daemonConnection.sendCommand(command: req)
        let reply = daemonConnection.readResponse()
        return reply
    } catch let error {
        print(error.localizedDescription)
    }
    return "Failed".data(using: .utf8)
}
