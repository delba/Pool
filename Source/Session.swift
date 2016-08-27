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
    
    private let peer: MCPeerID
    private let session: MCSession
    private let browser: MCNearbyServiceBrowser
    private let advertiser: MCNearbyServiceAdvertiser
    
    internal var peers: [MCPeerID] {
        return session.connectedPeers.filter({ $0 != peer })
    }
    
    internal init(name: String) {
        peer = MCPeerID(displayName: UIDevice.currentDevice().name)
        session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .Required)
        browser = MCNearbyServiceBrowser(peer: peer, serviceType: name)
        advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: name)
        
        super.init()
        
        session.delegate = self
        browser.delegate = self
        advertiser.delegate = self
        
        browser.startBrowsingForPeers()
        advertiser.startAdvertisingPeer()
    }
    
    deinit {
        browser.stopBrowsingForPeers()
        advertiser.stopAdvertisingPeer()
    }
    
    internal func sendRequest(key: Key, toPeers peers: [MCPeerID]) {
        let message: Message = .Request(key)
        sendMessage(message, toPeers: peers)
    }
    
    internal func sendResponse(key: Key, value: Value?, toPeers peers: [MCPeerID]) {
        let message: Message = .Response(key, value)
        sendMessage(message, toPeers: peers)
    }
    
    internal func sendInsert(keys: [Key], toPeers peers: [MCPeerID]) {
        let message: Message = .Insert(keys)
        sendMessage(message, toPeers: peers)
    }
    
    internal func sendDelete(keys: [Key], toPeers peers: [MCPeerID]) {
        let message: Message = .Delete(keys)
        sendMessage(message, toPeers: peers)
    }
    
    private func sendMessage(message: Message, toPeers peers: [MCPeerID]) {
        let data = message.toData()
        try! session.sendData(data, toPeers: peers, withMode: .Reliable)
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension Session: MCNearbyServiceAdvertiserDelegate {
    func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: (Bool, MCSession) -> Void) {
        invitationHandler(true, session)
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension Session: MCNearbyServiceBrowserDelegate {
    func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, toSession: session, withContext: nil, timeout: 10)
    }
    
    func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        delegate?.session(self, peerDidDisconnect: peerID)
    }
}

// MARK: - MCSessionDelegate

extension Session: MCSessionDelegate {
    func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
        switch state {
        case .Connected:    delegate?.session(self, peerDidConnect: peerID)
        case .NotConnected: delegate?.session(self, peerDidDisconnect: peerID)
        default: break
        }
    }
    
    func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
        guard let message = Message(data: data) else { return }
        
        switch message {
        case let .Request(key):   delegate?.session(self, didReceiveRequestForKey: key, fromPeer: peerID)
        case let .Response(k, v): delegate?.session(self, didReceiveResponseWithKey: k, andValue: v, fromPeer: peerID)
        case let .Insert(keys):   delegate?.session(self, didReceiveInsertForKeys: keys, fromPeer: peerID)
        case let .Delete(keys):   delegate?.session(self, didReceiveDeleteForKeys: keys, fromPeer: peerID)
        }
    }
    
    func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {}
    func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {}
}