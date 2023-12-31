//
//  Extensions.swift
//  Chat
//
//  Created by Nimish Mangee on 30/07/23.
//

import Foundation
import UIKit

extension UIView{
    public var width:CGFloat{
        return frame.size.width
    }
    
    public var height:CGFloat{
        return frame.size.height
    }
    
    public var top:CGFloat{
        return frame.origin.y
    }
    
    public var bottom:CGFloat{
        return frame.height + frame.origin.y
    }
    
    public var left:CGFloat{
        return frame.origin.x
    }
    
    public var right:CGFloat{
        return frame.origin.x + frame.size.width
    }
}

extension Notification.Name {
    static let didLogInNotification=Notification.Name("didLogInNotification")
}
