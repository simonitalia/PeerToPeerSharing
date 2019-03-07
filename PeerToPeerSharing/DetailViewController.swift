//
//  DetailViewController.swift
//  PeerToPeerSharing
//
//  Created by Simon Italia on 3/4/19.
//  Copyright © 2019 SDI Group Inc. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class DetailViewController: UITableViewController {
    
    //Property to receive data from Main / Collection ViewController 
    var mcPeerIDS = [MCPeerID]()    
    var displayNames = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if mcPeerIDS.count == 0 {
            title = "No Peers Connected"
            
        } else {
            title = "Peers Connected"
        }
    }

    // MARK: - Table view data source
    //Configure DetailVC tableView rows
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {

        return mcPeerIDS.count
    }
    
    //Construct cell data object & populate rows with cell.textLabel object/s
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ConnectedPeers", for: indexPath)
        
        for mcPeerID in mcPeerIDS {
            let displayName = mcPeerID.displayName
            displayNames.append(displayName)
        }
            
        cell.textLabel?.text = displayNames[indexPath.row]
        
        return cell
    }
    
}
