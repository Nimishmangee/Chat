//
//  ChatModels.swift
//  Chat
//
//  Created by Nimish Mangee on 01/11/23.
//

import Foundation
import CoreLocation
import MessageKit

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
            return "video"
        case .location(_):
            return "location"
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
struct Media: MediaItem{
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
}

struct Location: LocationItem{
    var location: CLLocation
    
    var size: CGSize
}
