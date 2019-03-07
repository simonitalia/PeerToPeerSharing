//
//  ViewController.swift
//  PeerToPeerSharing
//
//  Created by Simon Italia on 3/1/19.
//  Copyright © 2019 SDI Group Inc. All rights reserved.
//

import MultipeerConnectivity
import UIKit

class ViewController: UICollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    @IBOutlet weak var composeMessageButton: UIBarButtonItem!
    
    var images = [UIImage]()
    
    //Peer Manaher object for passing data between VCs
    var peerManager: PeerManager?
    
    //MPC properties
    var mcSession: MCSession!
    var mcPeerID: MCPeerID!
    var mcAdvertiserAssistant: MCAdvertiserAssistant!
    
    //ChatView property to receive ChatText transcript from ChatVC
    var messageReceived: String!
    var chatTranscript = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Nav bar items
        title = "Selfie Share"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(importPicture))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(showConnectionPrompt))
        
        mcPeerID = MCPeerID(displayName: UIDevice.current.name)
            //Shows the device name
        mcSession = MCSession(peer:
            mcPeerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        //Disable chat compose buttn if no peers connected
        if mcSession.connectedPeers.count == 0 {
          composeMessageButton.isEnabled = false
        }
        
    }
    
    //Set number of sections in collectionView
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return images.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageViewCell", for: indexPath)
        
        if let imageView = cell.viewWithTag(1000) as? UIImageView {
            imageView.image = images[indexPath.item]
            
        }
        
        return cell
        
    }
    
    //Create image picker ntroller coobject and display to user
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    //Enable user to select and add picture to app
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {return}
        
        dismiss(animated: true)
        
        images.insert(image, at: 0)
        collectionView?.reloadData()
        
        //Send image to peer/s (as a Data object)
        //1. Check if any peer/s exist to send data to
        if mcSession.connectedPeers.count > 0 {
            
            //2.Convert image to share to Data object
            if let imageData = image.pngData() {
                
                //3. Send data object to peer/s
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                            //.reliable = ensure data object is sent intact and guard against lost bits
                
                //4. Show error message in event of problem
                } catch {
                    let ac = UIAlertController(title: "Error sending data to peer/s", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction((UIAlertAction(title: "OK", style: .default)))
                    present(ac, animated: true)
                }
            }
        }
        
    }
    
    @objc func showConnectionPrompt() {
        
        let ac = UIAlertController(title: "Connect with others", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "Host a session", style: .default, handler: startHosting))
        ac.addAction(UIAlertAction(title: "Join a session", style: .default, handler: joinSession))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    //Mark: Alerts to prompt user to host session or join a session
    
    //Ensure alert takes in a UIAlrt object
    //Start a hosted session
    func startHosting(action: UIAlertAction) {
        mcAdvertiserAssistant = MCAdvertiserAssistant(serviceType: "my-peer2peer", discoveryInfo: nil, session: mcSession)
        mcAdvertiserAssistant.start()
    }
    
    //Ensure alert takes in a UIAlrt object
    //Join a hosted session
    func joinSession(action: UIAlertAction) {
        let mcBrowser = MCBrowserViewController(serviceType: "my-peer2peer", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    //MARK: Required MCSessionDelegate protocols
    
    //Following 3 not neeeded for our program. but must be decalred for protoocl conformance
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
    }
    
    //Diagnostic method to check connected state and to update VC button state
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        
        switch state {
        case MCSessionState.connected:
             print("Connected: \(peerID.displayName)")
             
             //Ensure interafce is updated by main thread
             DispatchQueue.main.async { [unowned self] in
                self.composeMessageButton.isEnabled = true
            }
            
        case MCSessionState.connecting:
            print("Connecting: \(peerID.displayName)")
            
        case MCSessionState.notConnected:
            print("Not Connected: \(peerID.displayName)")
            
            //Ensure interafce is updated by main thread
            DispatchQueue.main.async { [unowned self] in
                self.composeMessageButton.isEnabled = false
            }
        }
    }
    
    //Detect when data is received
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        //Update View with received Image Data received
        if let image = UIImage(data: data) {
            
            //Ensure interafce is updated by main thread
            DispatchQueue.main.async { [unowned self] in
                self.images.insert(image, at: 0)
                self.collectionView?.reloadData()
            }
        }
        
        //Update chatView property with received message text data
        let messageReceived = NSString(data: data as Data, encoding: String.Encoding.utf8.rawValue)! as String

            self.messageReceived = messageReceived
            print("Message received: \(messageReceived)")
        
            //Update ChatTextTranscript with messageReceived
            let updateChatTranscript = (chatTranscript + "\n" + messageReceived)
            chatTranscript = updateChatTranscript
    }
    
    //Required MCBrowserViewControllerDelegate protocols
    //These just need to dismiss the Alert CController respective to user action
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true)
    }
    
    //Deprected method
    func sendImage(image: UIImage) {
        if mcSession.connectedPeers.count > 0 {
            if let imageData = image.pngData() {
                do {
                    try mcSession.send(imageData, toPeers: mcSession.connectedPeers, with: .reliable)
                } catch let error as NSError {
                    let ac = UIAlertController(title: "Send error", message: error.localizedDescription, preferredStyle: .alert)
                    ac.addAction(UIAlertAction(title: "OK", style: .default))
                    present(ac, animated: true)
                }
            }
        }
    }
    
    //MARK: Handle passing data from CollectionVC to DetailVC segue
    
    //Setup segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "MainVCToDetailVC" {
            let destinationVC = segue.destination as! DetailViewController
            destinationVC.mcPeerIDS = (sender as? [MCPeerID])!
        }
        
        if segue.identifier == "MainVCToChatVC" {
            let destinationVC = segue.destination as! ChatViewController
            destinationVC.peerManager = sender as? PeerManager
        }
    }
    
    //Execute Segue when user taps on "Who's connected?" Button
    @IBAction func whoIsConnectedButton(_ sender: Any) {
       
        //Print connected peers to console for debugging
        print(mcSession.connectedPeers)
        
        //Send mcSession.connectedPeers array data object to DetailVC
        performSegue(withIdentifier: "MainVCToDetailVC", sender: mcSession.connectedPeers)
    }
    
    //Pass Peer Data object to ChatVC
    @IBAction func composeMessageButtonTapped(_ sender: Any) {
        
        //Guard against dropped connections, and prevent segue to chatVC
        if mcSession.connectedPeers.count == 0 {
            print("Can't start chat, no peers connected")
            return
        }
        
        //Construct PeerManager Data Object
        peerManager = PeerManager(mcSession: mcSession, mcPeerID: mcPeerID, chatTranscript: chatTranscript)
        
            performSegue(withIdentifier: "MainVCToChatVC", sender: peerManager)
    }

    //Segue to receive data object from ChatVC
    @IBAction func unwindToViewController(segue: UIStoryboardSegue) {

        guard segue.identifier == "saveUnwind" else { return }
        let sourceViewController = segue.source as! ChatViewController
        
        if let updateChatTranscript = sourceViewController.peerManager!.chatTranscript {
            
            chatTranscript = updateChatTranscript
            
        } else {
            return
        }
    }
}
