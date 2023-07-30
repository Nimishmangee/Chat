//
//  NewConversationViewController.swift
//  Chat
//
//  Created by Nimish Mangee on 30/07/23.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    private let spinner = JGProgressHUD()
    
    let searchBar:UISearchBar = {
        let searchBar=UISearchBar()
        searchBar.placeholder="Search"
        return searchBar
    }()
    
    let tableView:UITableView = {
        let table=UITableView()
        table.isHidden=true
        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        return table
    }()
    
    let noResultsLabel:UILabel = {
        let label=UILabel()
        label.isHidden=true
        label.text="No Results"
        label.textAlignment = .center
        label.textColor = .green
        label.font = .systemFont(ofSize:21, weight: .medium)
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchBar.delegate=self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView=searchBar
        navigationItem.rightBarButtonItem=UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        
        searchBar.becomeFirstResponder()
    }
    
    @objc func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }
}

extension NewConversationViewController:UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
    }
}
