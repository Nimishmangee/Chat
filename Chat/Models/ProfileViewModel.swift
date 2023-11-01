//
//  ProfileViewModel.swift
//  Chat
//
//  Created by Nimish Mangee on 01/11/23.
//

import Foundation

enum ProfileViewModelType {
    case info, logout
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    let title: String
    let handler: (() -> Void)?
}

