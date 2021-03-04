//
//  DaemonCommander.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 21/11/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//

import Socket
import Foundation

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
    public func sendCommand(command: Data) -> Data {
        do {
            // Create an Unix socket...
            try self.daemonSocket = Socket.create(family: .unix, type: .stream, proto: .unix)
            guard let socket = self.daemonSocket else {
                print("Unable to unwrap socket...")
                return "Failed".data(using: .utf8)!
            }
            self.daemonSocket = socket
            try socket.connect(to: self.socketPath)
        } catch let error {
            guard error is Socket.Error else {
                print(error.localizedDescription)
                return "Failed".data(using: .utf8)!
            }
        }

        do {
            try self.daemonSocket?.write(from: command)
        } catch let error {
            guard error is Socket.Error else {
                print(error.localizedDescription)
                return "Failed".data(using: .utf8)!
            }
        }

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
        print(String(data: req, encoding: .utf8)!)
        let daemonConnection = DaemonCommander(sockPath: socketPath.path)
        print(socketPath.path)
        let reply = daemonConnection.sendCommand(command: req)
        return reply
    } catch let error {
        print(error.localizedDescription)
    }
    return "Failed".data(using: .utf8)
}

struct ConfigsetRequest: Encodable {
    var command: String
    var args: configset
}

struct ConfigunsetRequest: Encodable {
    var command: String
    var args: configunset
}

struct configset: Encodable {
    var properties: CrcConfigs?
}

struct configunset: Encodable {
    var properties: [String]
}

func SendCommandToDaemon(command: ConfigsetRequest) -> Data? {
    do {
        let req = try JSONEncoder().encode(command)
        let res = sendToDaemonAndReadResponse(payload: req)
        if res?.count ?? -1 > 0 {
            return res
        }
    }
    catch let jsonErr {
        print(jsonErr)
    }
    return "Failed".data(using: .utf8)
}

func SendCommandToDaemon(command: ConfigunsetRequest) -> Data? {
    do {
        let req = try JSONEncoder().encode(command)
        let res = sendToDaemonAndReadResponse(payload: req)
        if res?.count ?? -1 > 0 {
            return res
        }
    }
    catch let jsonErr {
        print(jsonErr)
    }
    return "Failed".data(using: .utf8)
}

func SendCommandToDaemon(command: ConfigGetRequest) -> Data? {
    do {
        let req = try JSONEncoder().encode(command)
        let daemonConnection = DaemonCommander(sockPath: socketPath.path)
        return daemonConnection.sendCommand(command: req)
    } catch let error {
        print(error.localizedDescription)
    }
    return "Failed".data(using: .utf8)
}

func sendToDaemonAndReadResponse(payload: Data) -> Data? {
    let daemonConnection = DaemonCommander(sockPath: socketPath.path)
    print(socketPath.path)
    let reply = daemonConnection.sendCommand(command: payload)
    if reply.count > 0 {
        return reply
    }
    return "Failed".data(using: .utf8)
}
