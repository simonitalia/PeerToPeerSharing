//
//  Chat.swift
//  PeerToPeerSharing
//
//  Created by Simon Italia on 3/6/19.
//  Copyright © 2019 SDI Group Inc. All rights reserved.
//

import Foundation
import MultipeerConnectivity

class PeerManager {
    
    //MPC Properties
    var mcSession: MCSession!
    var mcPeerID: MCPeerID!
    
    //Chat properties
    var chatTranscript: String!
    
    //Initiliazer method
    init(mcSession: MCSession, mcPeerID: MCPeerID, chatTranscript: String) {
        self.mcSession = mcSession
        self.mcPeerID = mcPeerID
        self.chatTranscript = chatTranscript
    }

}

