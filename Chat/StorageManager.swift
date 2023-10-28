//
//  StorageManager.swift
//  Chat
//
//  Created by Nimish Mangee on 31/07/23.
//

import Foundation
import FirebaseStorage

final class StorageManager {
    static let shared = StorageManager()
    
    let storage=Storage.storage().reference()
    
    public typealias UploadPictureCompletion = (Result<URL, Error>) ->Void
    
    /// Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data:Data, filename:String, completion:@escaping UploadPictureCompletion){
        storage.child("images/\(filename)").putData(data, metadata: nil) { metadata, error in
            guard error == nil else{
                //failed
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("images/\(filename)").downloadURL { url, error in
                guard let url = url else {
                    print("")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
//                let urlString=url.absoluteString
                print("Download URL returned:\(url)")
                completion(.success(url))
            }
        }
    }
    
    /// Upload image that will be sent in a conversation message
    public func uploadMessagePhoto(with data:Data, filename:String, completion:@escaping UploadPictureCompletion){
        storage.child("message_images/\(filename)").putData(data, metadata: nil) { metadata, error in
            guard error == nil else{
                //failed
                completion(.failure(StorageErrors.failedToUpload))
                return
            }
            self.storage.child("message_images/\(filename)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failedToGetDownloadURL))
                    return
                }
                
//                let urlString=url.absoluteString
                print("Download URL returned:\(url)")
                completion(.success(url))
            }
        }
    }



    public enum StorageErrors:Error{
        case failedToUpload
        case failedToGetDownloadURL
    }
    
    func downloadURL(for path:String, completion:@escaping UploadPictureCompletion){
        let reference =  Storage.storage().reference(withPath: path)
        reference.downloadURL { url, error in
            guard let url=url, error==nil else{
                completion(.failure(StorageErrors.failedToGetDownloadURL))
                return
            }
            
            print("Download URL returned:\(url)")
            completion(.success(url))
        }
    }
}
