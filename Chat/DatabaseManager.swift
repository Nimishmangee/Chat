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
    
}

// MARK: - Account Management
extension DatabaseManager{
    
    ///Inserts new user to database
    public func insertUser(with user: ChatAppUser){
        var safeEmail=user.emailAddress.replacingOccurrences(of: ".", with: "-")
        safeEmail=safeEmail.replacingOccurrences(of: "@", with: "-")
        print(safeEmail)
        database.child(safeEmail).setValue([
            "first_name":user.firstName,
            "last_name": user.lastName
            
        ])
    }
}

struct ChatAppUser{
    let firstName:String
    let lastName :String
    let emailAddress:String
//    let profilePictureUrl: String
}
