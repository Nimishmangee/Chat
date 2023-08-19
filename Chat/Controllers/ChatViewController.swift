//
//  ChatViewController.swift
//  Chat
//
//  Created by Nimish Mangee on 30/07/23.
//

import UIKit
import MessageKit
import InputBarAccessoryView

struct Message:MessageType{
    public var sender: MessageKit.SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKit.MessageKind
}

extension MessageKind{
    var messageKindString: String{
        switch self{
            
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .linkPreview(_):
            break
        case .custom(_):
            break
        }
        return self.messageKindString
    }
}

struct  Sender:SenderType{
    public var photoURL :String
    public var senderId: String
    public var displayName: String
}

class ChatViewController: MessagesViewController {
    
    public static let dateFormatter:DateFormatter = {
        let formatter=DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        
        return formatter
    }()
    
    public var isNewConversation=false
    public var otherUserEmail: String = ""
    public var conversationId: String?
    
    private var messages = [Message]()
    private var selfSender:Sender? {
        guard let email=UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        
        return Sender(photoURL: "",
               senderId: safeEmail,
               displayName: "Me")
    }
    
    init(with email:String, id:String?){
        self.conversationId=id;
        self.otherUserEmail = email
        super.init(nibName: nil, bundle: nil)
        
        if let conversationId=conversationId {
            listenForMessages(id:conversationId, shouldScrollToBottom:true)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .red
        
//        messages.append(Message(sender: selfSender, messageId: "1", sentDate: Date(), kind: .text("Hello")))
        
        messagesCollectionView.messagesDataSource=self
        messagesCollectionView.messagesLayoutDelegate=self
        messagesCollectionView.messagesDisplayDelegate=self
        messageInputBar.delegate = self
        setupInputButton()
        
//        listenForMessages()
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside {[weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
    }
    
    private func presentInputActionSheet() {
        let acionSheet = UIAlertController(title: "Attatch Media", message: "What would you like to do ?", preferredStyle: .actionSheet)
        acionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        
//        acionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
//            <#code#>
//        }))
//        
//        acionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
//                
//        }))
//        
//        acionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { [weak self] _ in
//            <#code#>
//        }))
        
        present(acionSheet, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        
    }
    
    private func listenForMessages(id:String, shouldScrollToBottom:Bool){
        DatabaseManager.shared.getAllMessagesForConversations(with: id) {[weak self] result in
            switch result{
            case .success(let messages):
                guard !messages.isEmpty else{
                    return;
                }
                self?.messages=messages
                DispatchQueue.main.async {
                    //dhyaan do why not reload data
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom{
                        self?.messagesCollectionView.reloadData()
                    }
                }
            case .failure(let error):
                print("failed to get messages \(error)")
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate{
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender=self.selfSender,
              let messageId=createMessageId() else{
            return
        }
        
        print("Sending: \(text)")
        let message=Message(sender: selfSender, messageId: messageId, sentDate: Date(), kind: .text(text))
        
        //Karo send message
        if isNewConversation{
            //create convo in database
            DatabaseManager.shared.createNewConversation(with: otherUserEmail, name:self.title ?? "User", firstMessage: message) {[weak self] success in
                if success{
                    print("Message sent")
                    self?.isNewConversation=false;
                }
                else{
                    print("Failed to send")
                }
            }
        }
        else{
            //append to existing conv
            guard let conversationId = conversationId,
            let name=self.title else{
                return;
            }
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail:otherUserEmail, name:name, newMessage: message) {[weak self] success in
                if success{
                    print("Message sent")
                } else{
                    print("Failed to send the message")
                }
            }
        }
    }
    
    private func createMessageId()->String?{
        let dateString=Self.dateFormatter.string(from: Date())
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let newIdentifier="\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        print("created message id:\(newIdentifier)")
        return newIdentifier
    }
}

extension ChatViewController:  MessagesDataSource, MessagesDisplayDelegate, MessagesLayoutDelegate{
    func currentSender() -> MessageKit.SenderType {
        if let sender=selfSender{
            return sender
        }
        //dunmmy sender
        fatalError("Self sender is nill, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    
}
