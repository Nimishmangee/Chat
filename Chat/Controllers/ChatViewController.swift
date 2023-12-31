//
//  ChatViewController.swift
//  Chat
//
//  Created by Nimish Mangee on 30/07/23.
//

import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation



class ChatViewController: MessagesViewController {
    
    private var senderPhotoURL:  URL?
    private var otherUserPhotoURL: URL?
    
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
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
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
        
        acionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        //
        acionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { [weak self] _ in
            
        }))
        
        acionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        
        acionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil ))
        
        present(acionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc=LocationPickerViewController(coordinates: nil)
        vc.title="Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = {[weak self] selectedCoordinates in
            
            guard let strongSelf=self else{
                return
            }
            
            guard let messageId=self?.createMessageId(),
                  let conversationId = self?.conversationId,
                  let name=strongSelf.title,
                  let selfSender = self?.selfSender  else{
                return
            }
            
            let longitude:Double = selectedCoordinates.longitude
            let latitude:Double = selectedCoordinates.latitude
            
            print("long=\(longitude) | l lat=\(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            DatabaseManager.shared.sendMessage(to: conversationId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                
                if success {
                    print("sent location message")
                }
                else {
                    print("failed to send location message")
                }
            })

        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach a photo from",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title:"Camera",style: .default,handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title:"Photo Library",style: .default,handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title:"Cancel",style: .cancel,handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach a video from",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title:"Camera",style: .default,handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title:"Library",style: .default,handler: {[weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: true)
        }))
        
        actionSheet.addAction(UIAlertAction(title:"Cancel",style: .cancel,handler: nil))
        
        present(actionSheet, animated: true)
    }
}


extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        picker.dismiss(animated: true,completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {//
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
              let converstionId = conversationId,
              let name = self.title,
              let selfSender = selfSender else{
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" +  messageId.replacingOccurrences(of: " ",with: "-") + ".png"
            
            StorageManager.shared.uploadMessagePhoto(with: imageData, filename: fileName, completion: {[weak self] result in
                guard let strongSelf = self else{
                    return
                }
                switch result{
                case .success(let urlString):
                    print("Uploaded Message Photo: \(urlString)")
                    
                    
                    //error ho sakta hai
                    let url1=urlString.absoluteString
                    guard let url = URL(string: url1),
                          //                  guard let url=urlString,
                          let placeholder=UIImage(systemName: "plus") else{
                        return
                    }
                    
                    let media = Media(url:  url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size:.zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    DatabaseManager.shared.sendMessage(to: converstionId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                        
                        if success {
                            print("sent photo message")
                        }
                        else {
                            print("failed to send photo message")
                        }
                    })
                    
                    
                case .failure(let error):
                    print("message photo upload error: \(error)")
                    
                }
            })
        } else if let videoUrl=info[.mediaURL] as? URL{
            print("wtf\(videoUrl)")
            //video bhej raha hai tu
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            //upload video
            StorageManager.shared.uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else{
                    return
                }
                switch result{
                case .success(let urlString):
                    print("Uploaded Message Video: \(urlString)")
                    
                    
                    //error ho sakta hai
                    let url1=urlString.absoluteString
                    guard let url = URL(string: url1),
                          //                  guard let url=urlString,
                          let placeholder=UIImage(systemName: "plus") else{
                        return
                    }
                    
                    let media = Media(url:  url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size:.zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    DatabaseManager.shared.sendMessage(to: converstionId, otherUserEmail: strongSelf.otherUserEmail, name: name, newMessage: message, completion: { success in
                        
                        if success {
                            print("sent video message")
                        }
                        else {
                            print("failed to send video message")
                        }
                    })
                    
                    
                case .failure(let error):
                    print("message video upload error: \(error)")
                    
                }
            })
            
        }
    }
    private func listenForMessages(id:String, shouldScrollToBottom:Bool){
        DatabaseManager.shared.getAllMessagesForConversations(with: id) {[weak self] result in
            switch result{
            case .success(let messages):
                print("success in getting message: \(messages)")
                guard !messages.isEmpty else{
                    return;
                }
                self?.messages=messages
                
                
                DispatchQueue.main.async {
                    //dhyaan do why not reload data
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
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
                    let newConversationId = "conversation_\(message.messageId)"
                    self?.conversationId = newConversationId
                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = ""
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
                    self?.messageInputBar.inputTextView.text = nil
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
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType,at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView){
        guard let message = message as? Message else{
            return
        }
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        let message = messages[indexPath.section]
        switch message.kind{
        case .photo(let media):
            guard let imageUrl = media.url else{
                return
            }
            
            let vc = PhotoVIewerViewController(with: imageUrl)
            self.navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId != selfSender?.senderId {
            //our message that we've sent
            return .link
        }
        
        return .lightGray
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        //do something
        let sender=message.sender
        if sender.senderId == selfSender?.senderId {
            //saadi image dikha
            if let currentUserImageURL = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImageURL, completed: nil)
            } else{
                //Pehla URL fetch kariye
                //images/safeemail_profile_picture.png
                
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
                    return
                }
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_pic.png"
                
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.senderPhotoURL=url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                        
                    case .failure(let error):
                        print(path)
                        print("\(error) ")
                    }
                }
            }
        }
        else{
            //other user image
            if let otherUserPhotoURL = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserPhotoURL, completed: nil)
            } else{
                //Pehla uRL fetch kariye
                let email = self.otherUserEmail
                
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_pic.png"
                
//                print(path)
                
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoURL=url
                        print("\(url), yahi dhund raha hu")
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                        
                    case .failure(let error):
                        print("\(error) ab kyo yaar")
                    }
                }
            }
        }
    }
}

extension ChatViewController: MessageCellDelegate{
//    func didTapMessage(in cell: MessageCollectionViewCell){
//        guard let indexPath = messagesCollectionView.indexPath(for: cell) else{
//            return
//        }
//
//        let message = messages[indexPath.section]
//
//        switch message.kind{
//        case .photo(let media):
//            guard let imageUrl = media.url else{
//                return
//            }
//
//            let vc = PhotoVIewerViewController(with: imageUrl)
//            self.navigationController?.pushViewController(vc, animated: true)
//
//        case .video(let media):
//            guard let videoUrl = media.url else{
//                return
//            }
//
//            let vc=AVPlayerViewController()
//            vc.player=AVPlayer(url: videoUrl)
//            present(vc, animated: true);
//
//        default:
//            break
//        }
//    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }

        let message = messages[indexPath.section]

        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }

    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }

        let message = messages[indexPath.section]

        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoVIewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
            
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }

            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
        default:
            break
        }
    }
}
