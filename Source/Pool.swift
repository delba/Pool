//
// Pool.swift
//
// Copyright (c) 2016 Damien (http://delba.io)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import MultipeerConnectivity

internal typealias Key = String
internal typealias Value = AnyObject

public class Pool {
    public let name: String
    
    private let session: Session
    
    private var local: [Key: Value] = [:]
    private var manifest: [Key: MCPeerID] = [:]
    private var callbacks: [Key: (Value? -> Void)] = [:]
    
    public init(name: String) {
        self.name = name
        session = Session(name: name)
        session.delegate = self
    }
    
    public func objectForKey(key: String, completion: (AnyObject? -> Void)) {
        if let object = local[key] {
            completion(object)
            return
        }
        
        guard let peer = manifest[key] else {
            completion(nil)
            return
        }
        
        callbacks[key] = completion
        
        session.sendRequest(key, toPeers: [peer])
    }
    
    public func setObject(object: AnyObject, forKey key: String) {
        if local[key] == nil {
            session.sendInsert([key], toPeers: session.peers)
        }
        
        local[key] = object
    }
    
    public func removeObjectForKey(key: String) {
        if local[key] != nil {
            session.sendDelete([key], toPeers: session.peers)
        }
        
        local[key] = nil
    }
    
    public func removeAllObjects() {
        session.sendDelete(Array(local.keys), toPeers: session.peers)
        
        local.removeAll()
        manifest.removeAll()
        callbacks.removeAll()
    }
}

// MARK: - SessionDelegate

extension Pool: SessionDelegate {
    func session(session: Session, peerDidConnect peer: MCPeerID) {
        session.sendInsert(Array(local.keys), toPeers: [peer])
    }
    
    func session(session: Session, peerDidDisconnect peer: MCPeerID) {
        for (key, value) in manifest where peer == value {
            manifest[key] = nil
        }
    }
    
    func session(session: Session, didReceiveRequestForKey key: Key, fromPeer peer: MCPeerID) {
        session.sendResponse(key, value: local[key], toPeers: [peer])
    }
    
    func session(session: Session, didReceiveResponseWithKey key: Key, andValue value: Value?, fromPeer peer: MCPeerID) {
        callbacks[key]?(value)
        callbacks[key] = nil
        local[key] = value
    }
    
    func session(session: Session, didReceiveInsertForKeys keys: [Key], fromPeer peer: MCPeerID) {
        keys.forEach { manifest[$0] = peer }
    }
    
    func session(session: Session, didReceiveDeleteForKeys keys: [Key], fromPeer peer: MCPeerID) {
        keys.forEach { manifest[$0] = nil }
    }
}