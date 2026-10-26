//
//  AgentBridge.swift
//  dayflow-cli
//
//  Client side of the write channel. Reads go straight to SQLite; writes go
//  to the running app over a Unix domain socket, because the app owns the
//  category store (an in-memory array persisted to preferences wholesale) and
//  its UI must refresh when data changes underneath it.
//
//  Protocol: one JSON request line in, one JSON response line out, then the
//  connection closes. {"protocol_version":1,"operation":...,"arguments":{...}}
//  → {"ok":true,"data":{...}} or {"ok":false,"error":{"code","message"}}.
//
//  Tests inject DAYFLOW_SOCK and DAYFLOW_EDITS_ENABLED so CI never talks to a
//  live Dayflow.app.
//

import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

public enum AgentBridge {
  public static let protocolVersion = AgentBridgeProtocol.version

  public static let editsEnabledEnvironmentKey = "DAYFLOW_EDITS_ENABLED"
  public static let socketPathEnvironmentKey = "DAYFLOW_SOCK"

  public static var socketPath: String {
    if let override = ProcessInfo.processInfo.environment[socketPathEnvironmentKey],
      !override.isEmpty
    {
      return override
    }
    let appSupport = FileManager.default.urls(
      for: .applicationSupportDirectory, in: .userDomainMask)[0]
    return appSupport.appendingPathComponent("Dayflow/agent.sock").path
  }

  public static var editsEnabled: Bool {
    if let env = ProcessInfo.processInfo.environment[editsEnabledEnvironmentKey] {
      let normalized = env.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
      return normalized == "1" || normalized == "true" || normalized == "yes"
    }
    return UserDefaults(suiteName: "teleportlabs.com.Dayflow")?
      .bool(forKey: "agentEditsEnabled") ?? false
  }

  public static var appIsListening: Bool {
    FileManager.default.fileExists(atPath: socketPath)
  }

  public struct BridgeError: Error, Equatable {
    public let code: String
    public let message: String

    public init(code: String, message: String) {
      self.code = code
      self.message = message
    }
  }

  /// Send one operation to the app and return its `data` payload.
  public static func send(operation: String, arguments: [String: Any]) throws -> [String: Any] {
    #if os(Linux)
    let fd = socket(AF_UNIX, Int32(SOCK_STREAM.rawValue), 0)
    #else
    let fd = socket(AF_UNIX, SOCK_STREAM, 0)
    #endif
    guard fd >= 0 else {
      throw BridgeError(code: "socket_error", message: "Could not create a socket.")
    }
    defer { close(fd) }

    var address = sockaddr_un()
    address.sun_family = sa_family_t(AF_UNIX)
    let path = socketPath
    guard path.utf8.count < MemoryLayout.size(ofValue: address.sun_path) else {
      throw BridgeError(code: "socket_error", message: "Socket path too long.")
    }
    withUnsafeMutableBytes(of: &address.sun_path) { buffer in
      path.utf8CString.withUnsafeBytes { source in
        buffer.copyBytes(from: source.prefix(buffer.count))
      }
    }

    let connectResult = withUnsafePointer(to: &address) { pointer in
      pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
        connect(fd, $0, socklen_t(MemoryLayout<sockaddr_un>.size))
      }
    }
    guard connectResult == 0 else {
      throw BridgeError(
        code: "app_not_running",
        message: "Dayflow isn't running. Reads work offline; edits need the app open.")
    }

    let payload = try AgentBridgeProtocol.encodeRequest(
      operation: operation, arguments: arguments)
    payload.withUnsafeBytes { buffer in
      _ = write(fd, buffer.baseAddress, buffer.count)
    }

    var response = Data()
    var byte: UInt8 = 0
    while read(fd, &byte, 1) == 1 {
      if byte == 0x0A { break }
      response.append(byte)
      if response.count > 1_048_576 {
        throw BridgeError(code: "protocol_error", message: "Response too large.")
      }
    }

    return try AgentBridgeProtocol.decodeResponse(response)
  }
}
