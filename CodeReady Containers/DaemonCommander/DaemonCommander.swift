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
    let socketPath: String
    static let bufferSize = 1024
    
    init(sockPath: String) {
        self.socketPath = sockPath
    }
    
    public func sendCommand(command: Data) throws -> Data {
        do {
            let daemonSocket = try Socket.create(family: .unix, type: .stream, proto: .unix)
            defer {
                daemonSocket.close()
            }
            try daemonSocket.connect(to: self.socketPath)
            try daemonSocket.write(from: command)
            var readData = Data(capacity: DaemonCommander.bufferSize)
            let bytesRead = try daemonSocket.read(into: &readData)
            if bytesRead > 1 {
                return readData
            }
            throw DaemonError.badResponse
        } catch let error {
            guard error is Socket.Error else {
                print(error.localizedDescription)
                throw DaemonError.io
            }
            throw error
        }
    }
}

let userHomePath: URL = FileManager.default.homeDirectoryForCurrentUser
let socketPath: URL = userHomePath.appendingPathComponent(".crc").appendingPathComponent("crc.sock")

func SendCommandToDaemon(command: Request) -> Data? {
    do {
        let req = try JSONEncoder().encode(command)
        print(String(data: req, encoding: .utf8)!)
        let daemonConnection = DaemonCommander(sockPath: socketPath.path)
        return try daemonConnection.sendCommand(command: req)
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
        let res = try sendToDaemonAndReadResponse(payload: req)
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
        let res = try sendToDaemonAndReadResponse(payload: req)
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
        return try daemonConnection.sendCommand(command: req)
    } catch let error {
        print(error.localizedDescription)
    }
    return "Failed".data(using: .utf8)
}

func sendToDaemonAndReadResponse(payload: Data) throws -> Data? {
    let daemonConnection = DaemonCommander(sockPath: socketPath.path)
    let reply = try daemonConnection.sendCommand(command: payload)
    if reply.count > 0 {
        return reply
    }
    return "Failed".data(using: .utf8)
}
