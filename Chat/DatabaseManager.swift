//
//  DatabaseManager.swift
//  Chat
//
//  Created by Nimish Mangee on 30/07/23.
//

import Foundation
import FirebaseDatabase

final class DatabaseManager{
    static let shared = DatabaseManager()
    
    private let database=Database.database().reference()
    
    static func safeEmail(emailAddress:String) ->String {
        var safeEmail=emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail=safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
}

extension DatabaseManager{
    public func getDataFor(path:String, completion:@escaping(Result<Any, Error>) -> Void){
        self.database.child("\(path)").observeSingleEvent(of: .value) { snapshot in
            guard let value=snapshot.value else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
}

// MARK: - Account Management
extension DatabaseManager{
    
    ///Inserts new user to database
    public func insertUser(with user: ChatAppUser, completion:@escaping(Bool) -> Void ){
        database.child(user.safeEmail).setValue([
            "first_name":user.firstName,
            "last_name": user.lastName
            
        ]) { error, _ in
            guard error == nil else{
                print("Failed to write to database")
                completion(false)
                return
            }
            
            self.database.child("users").observeSingleEvent(of: .value) {[weak self] snapshot in
                if var usersCollection = snapshot.value as? [[String: String]] {
                    //append to dictionary
                    let newElement=[
                        "name":user.firstName + " " + user.lastName,
                        "email":user.safeEmail
                    ]
                    usersCollection.append(newElement)
                    //check for weak self
                    self?.database.child("users").setValue(usersCollection) { error, _ in
                        guard error==nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                    
                }
                else{
                    //create kar dictionary
                    let newCollection:[[String:String]] = [
                        [
                            "name":user.firstName + " " + user.lastName,
                            "email":user.safeEmail
                        ]
                    ]
                    self?.database.child("users").setValue(newCollection) { error, _ in
                        guard error==nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
    
    public func getAllUsers(completion: @escaping(Result<[[String: String]], Error>) -> Void){
        database.child("users").observeSingleEvent(of: .value) { snapshot in
            guard let value = snapshot.value as? [[String:String]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            completion(.success(value))
        }
    }
    public enum DatabaseError: Error {
        case failedToFetch
    }
}

// MARK: - Sending Messages/conversations
extension DatabaseManager{
    
    /*
     "hkhdfshdf" {
     "messages":[
     {
     "id":String,
     "type":text, photo, video
     "content":String,
     "date":Date(),
     "sender_email":String,
     "isRead":true/false
     }
     ]
     }
     conversations => [
     [
     "conversation_id":hkhdfshdf:
     "other_user_email":
     "latest_message" =>{
     "date":Date()
     "latest_message":"message"
     "is_read": true/false
     }
     ]
     ]
     
     */
    
    ///Create  a new conversation with target user email id jisme first message sent
    public func createNewConversation(with otherUserEmail: String, name:String, firstMessage:Message, completion:@escaping(Bool)->Void){
        guard let currentEmail = UserDefaults.standard.value(forKey: "email") as? String,
              let currentName = UserDefaults.standard.value(forKey: "name") as? String else{
            return
        }
        let safeEmail=DatabaseManager.safeEmail(emailAddress:currentEmail)
        let ref=database.child("\(safeEmail)")
        ref.observeSingleEvent(of: .value) {[weak self] snapshot in
            guard var userNode=snapshot.value as? [String:Any] else{
                completion(false)
                print("User not found")
                return
            }
            
            let messageDate = firstMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message=""
            
            switch firstMessage.kind {
                
            case .text(let messageText):
                message=messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
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
            
            let conversationId="conversation_\(firstMessage.messageId)"
            let newConversationsData:[String:Any] = [
                "id": conversationId ,
                "other_user_email" : otherUserEmail,
                "name":name,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "is_read": false
                ] as [String : Any]
            ]
            
            let recipient_newConversationsData:[String:Any] = [
                "id": conversationId ,
                "other_user_email" : safeEmail,
                "name":currentName,
                "latest_message" : [
                    "date" : dateString,
                    "message" : message,
                    "is_read": false
                ] as [String : Any]
            ]
            //Update recipient user conversations entry
            self?.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { [weak self]snapshot in
                if var conversations = snapshot.value as? [[String:Any]] {
                    //append
                    conversations.append(recipient_newConversationsData)
                    self?.database.child("\(otherUserEmail)/conversations").setValue(conversations)
                }
                else{
                    //creation
                    self?.database.child("\(otherUserEmail)/conversations").setValue([recipient_newConversationsData])
                }
            }
            
            //Update current user conversations entry
            if var conversations=userNode["conversations"] as? [[String:Any]]{
                //conversations array exists for current user
                //you should append
                conversations.append(newConversationsData)
                userNode["conversations"]=conversations
                ref.setValue(userNode) { error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    self?.finishCreatingConversations(name:name, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                }
                
            }
            else{
                //create conversations array
                userNode["conversations"] = [
                    newConversationsData
                ]
                ref.setValue(userNode) { error, _ in
                    guard error == nil else{
                        completion(false)
                        return
                    }
                    //why did this completion is marked as a parameter
                    self?.finishCreatingConversations(name:name, conversationID: conversationId, firstMessage: firstMessage, completion: completion)
                }
            }
        }
    }
    
    private func finishCreatingConversations(name: String, conversationID:String, firstMessage:Message, completion:@escaping(Bool)->Void){
        //        {
        //            "id": String ,
        //            "type": text, photo, video,
        //            "content": String,
        //            "date" : Date(),
        //            "sender_email":String,
        //            "is_read": true/false
        //        }
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        
        var message=""
        switch firstMessage.kind {
        case .text(let messageText):
            message=messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
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
        
        guard let myEmail=UserDefaults.standard.value(forKey: "email") as?String else{
            completion(false)
            return
        }
        
        let currentUserEmail=DatabaseManager.safeEmail(emailAddress: myEmail)
        
        let collectionMessage: [String:Any] = [
            "id":firstMessage.messageId,
            "type":firstMessage.kind.messageKindString,
            "content":message,
            "date":dateString,
            "sender_email":currentUserEmail,
            "is_read":false,
            "name": name
        ]
        
        let value:[String:Any] = [
            "messages":[collectionMessage]
        ]
        database.child("\(conversationID)").setValue(value) { error, _ in
            guard error == nil else{
                completion(false)
                return
            }
            completion(true)
        }
    }
    
    ///Fetches and returns all conversations for user with passed email
    public func getAllConversations(for email:String, completion:@escaping(Result<[Conversation], Error>)->Void){
        database.child("\(email)/conversations").observe(.value, with: {snapshot in
            guard let value=snapshot.value as? [[String:Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let conversations:[Conversation] = value.compactMap({ dictionary in
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String ,
                      let otherUserEmail = dictionary["other_user_email"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String:Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead=latestMessage["is_read"] as? Bool else{
                    
                    print("No way")
                    return nil
                }
                let latestMessagedObject = LatestMessage(date: date, text: message, isRead: isRead);
                
                return Conversation(id: conversationId, name: name, otherUserEmail: otherUserEmail, latestMessage: latestMessagedObject)

            })
            completion(.success(conversations))
        })
    }
    ///Gets all messages for a given conversation
    public func getAllMessagesForConversations(with id:String, completion:@escaping(Result<[Message], Error>)->Void){
        database.child("\(id)/messages").observe(.value, with: {snapshot in
            guard let value=snapshot.value as? [[String:Any]] else{
                completion(.failure(DatabaseError.failedToFetch))
                return
            }
            let messages:[Message] = value.compactMap { dictionary in
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? Bool,
                      let messageID = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderEmail = dictionary["sender_email"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date=ChatViewController.dateFormatter.date(from: dateString) else{
                    
                    print("Same problem hai, string ke naam check kar message ke liye")
                    return nil;
                }
                let sender = Sender(photoURL: "", senderId: senderEmail, displayName: name)
                return Message(sender: sender, messageId: messageID, sentDate: date, kind: .text(content))
            }
            
            completion(.success(messages))
        })
    }
    
    ///Sends a message with target conversation and message
    public func sendMessage(to conversation:String, otherUserEmail:String, name:String, newMessage:Message, completion: @escaping(Bool)->Void){
        //add new message to messages
        //update sender latest message
        //update recipient latest message
        
        guard let myEmail = UserDefaults.standard.value(forKey: "email") as? String else{
            completion(false)
            return
        }
        
        let currentEmail=DatabaseManager.safeEmail(emailAddress: myEmail)
        
        database.child("\(conversation)/messages").observeSingleEvent(of: .value) {[weak self] snapshot,_  in
            guard let strongSelf=self else{
                return
            }
            guard var currentMessages=snapshot.value as? [[String:Any]] else{
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            
            var message=""
            switch newMessage.kind {
            case .text(let messageText):
                message=messageText
            case .attributedText(_):
                break
            case .photo(_):
                break
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
            
            guard let myEmail=UserDefaults.standard.value(forKey: "email") as?String else{
                completion(false)
                return
            }
            
            let currentUserEmail=DatabaseManager.safeEmail(emailAddress: myEmail)
            
            let newMessageEntry: [String:Any] = [
                "id":newMessage.messageId,
                "type":newMessage.kind.messageKindString,
                "content":message,
                "date":dateString,
                "sender_email":currentUserEmail,
                "is_read":false,
                "name": name
            ]
            currentMessages.append(newMessageEntry)
            strongSelf.database.child("\(conversation)/messages").setValue(currentMessages) { error, _ in
                guard error==nil else{
                    completion(false)
                    return
                }
                //mistake possible
                strongSelf.database.child("\(currentEmail)/conversations").observeSingleEvent(of: .value) { snapshot,_  in
                    guard var currentUserConversations = snapshot.value as? [[String:Any]] else{
                        completion(false)
                        return
                    }
                    
                    let updatedValue : [String:Any] = [
                        "date":dateString,
                        "is_read":false,
                        "message":message
                    ]
                    
                    var targetConversation: [String:Any]?
                    
                    var position=0
                    
                    for conversationDictionary in currentUserConversations{
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                            targetConversation = conversationDictionary
                            break
                        }
                        position+=1
                    }
                    //doubt
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else{
                        completion(false)
                        return
                    }
                    currentUserConversations[position] = finalConversation
                    strongSelf.database.child("\(currentEmail)/conversations").setValue(currentUserConversations) { error, _ in
                        guard error==nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
                //update latest message for recepient user
                strongSelf.database.child("\(otherUserEmail)/conversations").observeSingleEvent(of: .value) { snapshot,_  in
                    guard var otherUserConversations = snapshot.value as? [[String:Any]] else{
                        completion(false)
                        return
                    }
                    
                    let updatedValue : [String:Any] = [
                        "date":dateString,
                        "is_read":false,
                        "message":message
                    ]
                    
                    var targetConversation: [String:Any]?
                    
                    var position=0
                    
                    for conversationDictionary in otherUserConversations{
                        if let currentId = conversationDictionary["id"] as? String, currentId == conversation {
                            targetConversation = conversationDictionary
                            break
                        }
                        position+=1
                    }
                    //doubt
                    targetConversation?["latest_message"] = updatedValue
                    guard let finalConversation = targetConversation else{
                        completion(false)
                        return
                    }
                    otherUserConversations[position] = finalConversation
                    strongSelf.database.child("\(otherUserEmail)/conversations").setValue(otherUserConversations) { error, _ in
                        guard error==nil else{
                            completion(false)
                            return
                        }
                        completion(true)
                    }
                }
            }
        }
    }
}






struct ChatAppUser{
    let firstName:String
    let lastName :String
    let emailAddress:String
    
    var safeEmail:String{
        var safeEmail=emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail=safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
    
    var profilePictureFileName: String{
        return "\(safeEmail)_profile_pic.png"
    }
}
