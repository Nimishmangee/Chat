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
            completion(true)
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
