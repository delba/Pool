//
// Session.swift
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

internal class Session: NSObject {
    internal var delegate: SessionDelegate?
    
    fileprivate let peer: MCPeerID
    fileprivate let session: MCSession
    fileprivate let browser: MCNearbyServiceBrowser
    fileprivate let advertiser: MCNearbyServiceAdvertiser
    
    internal var peers: [MCPeerID] {
        return session.connectedPeers.filter({ $0 != peer })
    }
    
    internal init(name: String) {
        peer = MCPeerID(displayName: UIDevice.current.name)
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: name)
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: name)
        
        super.init()
        
        session.delegate = self
        advertiser.delegate = self
        browser.delegate = self

        browser.startBrowsingForPeers()
        advertiser.startAdvertisingPeer()
    }
    
    deinit {
        browser.stopBrowsingForPeers()
        advertiser.stopAdvertisingPeer()
    }
    
    internal func sendRequest(_ key: Key, toPeers peers: [MCPeerID]) {
        let message: Message = .request(key)
        sendMessage(message, toPeers: peers)
    }
    
    internal func sendResponse(_ key: Key, value: Value?, toPeers peers: [MCPeerID]) {
        let message: Message = .response(key, value)
        sendMessage(message, toPeers: peers)
    }
    
    internal func sendInsert(_ keys: [Key], toPeers peers: [MCPeerID]) {
        let message: Message = .insert(keys)
        sendMessage(message, toPeers: peers)
    }
    
    internal func sendDelete(_ keys: [Key], toPeers peers: [MCPeerID]) {
        let message: Message = .delete(keys)
        sendMessage(message, toPeers: peers)
    }
    
    fileprivate func sendMessage(_ message: Message, toPeers peers: [MCPeerID]) {
        let data = message.toData()
        try! session.send(data as Data, toPeers: peers, with: .reliable)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension Session: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension Session: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 10)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

// MARK: - MCSessionDelegate

extension Session: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case .connected:    delegate?.session(self, peerDidConnect: peerID)
        case .notConnected: delegate?.session(self, peerDidDisconnect: peerID)
        default: break
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = Message(data: data) else { return }
        
        switch message {
        case let .request(key):   delegate?.session(self, didReceiveRequestForKey: key, fromPeer: peerID)
        case let .response(k, v): delegate?.session(self, didReceiveResponseWithKey: k, andValue: v, fromPeer: peerID)
        case let .insert(keys):   delegate?.session(self, didReceiveInsertForKeys: keys, fromPeer: peerID)
        case let .delete(keys):   delegate?.session(self, didReceiveDeleteForKeys: keys, fromPeer: peerID)
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
}
