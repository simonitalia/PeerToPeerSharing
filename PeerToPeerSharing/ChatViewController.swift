//
//  ChatViewController.swift
//  PeerToPeerSharing
//
//  Created by Simon Italia on 3/5/19.
//  Copyright © 2019 SDI Group Inc. All rights reserved.
//

import UIKit
import MultipeerConnectivity

class ChatViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var chatTextView: UITextView!
    @IBOutlet weak var messageInputTextField: UITextField!
    
    var sendButtonTapped = false
    
    //MPC properties to store MPC object received from MainVC
    //var mcSession: MCSession! = nil
    var peerManager: PeerManager?
    var chatTranscript: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

       self.messageInputTextField.delegate = self
       self.chatTextView.delegate = self
        
       //Call hideKeyboard when user taps View
        let viewTapped = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard(_ :)))
        view.addGestureRecognizer(viewTapped)
        
        //Keyboard Notification observer
        let notificationCenter = NotificationCenter.default
        
        notificationCenter.addObserver(self, selector: #selector(keyboardWillHide), name:
            UIResponder.keyboardWillHideNotification, object: nil)
        
        notificationCenter.addObserver(self, selector: #selector(keyboardWillShow), name:
            UIResponder.keyboardWillChangeFrameNotification, object: nil)
        
        //Update chatView with conversation
        chatTextView.text = peerManager?.chatTranscript
    }
    
    @IBAction func sendKeyTapped(_ sender: Any) {
        
        //Send text if user has inputted text
        if messageInputTextField.text != "" || messageInputTextField.text != "Enter message" {
            
            //Call send message method
            sendMessage()
        
        } else {
            return
        }
    }
    
    //Method dimisses Keyboard if displayed in view
    @objc func hideKeyboard(_ sender: UITapGestureRecognizer) {
        
        view.endEditing(true)
        
    }
    
    //MARK: Move text field up, above Keyboard when user taps text field
    
    //AdjustForKeyboard() methods
    @objc func keyboardWillShow(notification: Notification) {
        
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue {
            if self.view.frame.origin.y == 0 {
                self.view.frame.origin.y -= keyboardSize.height
            }
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    //Action to take when user taps send button
    func sendMessage() {
        sendButtonTapped = !sendButtonTapped
        
        //Send message
        if sendButtonTapped == true {
            
            if let mcSession = peerManager?.mcSession {
                let myPeerID = peerManager?.mcSession.myPeerID
                let messageToSend = "\n\(myPeerID!.displayName): \n\(messageInputTextField.text!)\n"
            
                //Convert message text to Data object so it can be received and decoded by connected device/s
                let messageData = messageToSend.data(using: String.Encoding.utf8)
                
                do {
                    try mcSession.send(messageData!, toPeers: mcSession.connectedPeers, with: .reliable)
                    print("Message sent successfully")
                
                } catch {
                    print("Error sending message to peers")
                }
                
                //Append chatTextView with messageInputText
                chatTextView.text = chatTextView.text + "\nMe: \n\(messageInputTextField.text!)\n"
                
                //Clear out enterMessageTextField
                messageInputTextField.text = ""
            }
        
        } else {
            //do nothing
            return
        }
    }
    
    //Pass chatTranscript object back to MainVC from ChatVC via Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        guard segue.identifier == "saveUnwind" else { return }

        //Prepare data object to send to MainVC
        peerManager?.chatTranscript = chatTextView.text
    }
    
    
}
