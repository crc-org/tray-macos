//
//  DaemonCommander.swift
//  CodeReady Containers
//
//  Created by Anjan Nath on 21/11/19.
//  Copyright © 2019 Red Hat. All rights reserved.
//

import Foundation
import AsyncHTTPClient
import NIOHTTP1

let httpClient = HTTPClient(eventLoopGroupProvider: .createNew)

class DaemonCommander {
    let socketPath: String
    static let bufferSize = 1024

    init(sockPath: String) {
        self.socketPath = sockPath
    }

    public func sendCommand(_ verb: HTTPMethod, _ path: String, _ command: Data?) throws -> Data {
        let socketPathBasedURL = URL(
            httpURLWithSocketPath: self.socketPath,
            uri: path
        )
        var request = try HTTPClient.Request(url: socketPathBasedURL!, method: verb)
        if let body = command {
            request.body = .data(body)
        }

        let sem = DispatchSemaphore(value: 0)
        var resultData: Data?
        var error: Data?

        httpClient.execute(request: request).whenComplete { result in
            switch result {
            case .failure(let err):
                error = Data(err.localizedDescription.utf8)
            case .success(let response):
                if response.status == .ok {
                    response.body?.withUnsafeReadableBytes {
                        resultData = Data($0)
                    }
                } else {
                    response.body?.withUnsafeReadableBytes {
                        error = Data($0)
                    }
                }
            }

            sem.signal()
        }

        sem.wait()
        if let data = resultData {
            return data
        }
        if let data = error {
            throw DaemonError.internalServerError(message: String(decoding: data, as: UTF8.self))
        }
        throw DaemonError.io
    }
}

let userHomePath: URL = FileManager.default.homeDirectoryForCurrentUser
let socketPath: URL = userHomePath.appendingPathComponent(".crc").appendingPathComponent("crc-http.sock")

func SendCommandToDaemon<T>(_ verb: HTTPMethod, _ path: String, _ payload: T) throws -> Data where T: Encodable {
    let req = try JSONEncoder().encode(payload)
    let daemonConnection = DaemonCommander(sockPath: socketPath.path)
    return try daemonConnection.sendCommand(verb, path, req)
}

func SendCommandToDaemon(_ verb: HTTPMethod, _ path: String) throws -> Data {
    let daemonConnection = DaemonCommander(sockPath: socketPath.path)
    return try daemonConnection.sendCommand(verb, path, nil)
}

func SendCommandToDaemon(command: ConfigsetRequest) throws -> Data {
    let req = try JSONEncoder().encode(command.args)
    return try sendToDaemonAndReadResponse(HTTPMethod.POST, "/api/config/set", req)
}

func SendCommandToDaemon(command: ConfigunsetRequest) throws -> Data {
    let req = try JSONEncoder().encode(command.args)
    return try sendToDaemonAndReadResponse(HTTPMethod.POST, "/api/config/unset", req)
}

func SendCommandToDaemon(command: ConfigGetRequest) throws -> Data {
    let req = try JSONEncoder().encode(command.args)
    let daemonConnection = DaemonCommander(sockPath: socketPath.path)
    return try daemonConnection.sendCommand(HTTPMethod.GET, "/api/config/get", req)
}

func sendToDaemonAndReadResponse(_ verb: HTTPMethod, _ path: String, _ payload: Data) throws -> Data {
    let daemonConnection = DaemonCommander(sockPath: socketPath.path)
    let reply = try daemonConnection.sendCommand(verb, path, payload)
    if reply.count > 0 {
        return reply
    }
    throw DaemonError.badResponse
}
