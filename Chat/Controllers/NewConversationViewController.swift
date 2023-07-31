//
//  NewConversationViewController.swift
//  Chat
//
//  Created by Nimish Mangee on 30/07/23.
//

import UIKit
import JGProgressHUD

class NewConversationViewController: UIViewController {
    
    public var completion: (([String:String]) ->(Void))?
    
    private var users=[[String:String]]()
    private var results=[[String:String]]()
    private var hasFetched=false
    
    private let spinner = JGProgressHUD(style: .dark)
    
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
        view.addSubview(noResultsLabel)
        view.addSubview(tableView)
        
        tableView.delegate=self
        tableView.dataSource=self
        
        searchBar.delegate=self
        view.backgroundColor = .white
        navigationController?.navigationBar.topItem?.titleView=searchBar
        navigationItem.rightBarButtonItem=UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(dismissSelf))
        
        searchBar.becomeFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableView.frame=view.bounds
        noResultsLabel.frame = CGRect(x: view.width/4, y: (view.height-200)/2, width: view.width/2, height: 200)
    }
    
    @objc func dismissSelf(){
        dismiss(animated: true, completion: nil)
    }
}

extension NewConversationViewController:UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell=tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text=results[indexPath.row]["name"]
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //os bande di chat kholo, search GPT
        let targetUserData=results[indexPath.row]
        
        dismiss(animated: true) { [weak self] in
            self?.completion?(targetUserData)
        }
    }
}

extension NewConversationViewController:UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let text=searchBar.text, !text.replacingOccurrences(of: " ", with: "").isEmpty else{
            return
        }
        
        searchBar.resignFirstResponder()
        
        results.removeAll()
        spinner.show(in: view)
        self.searchUsers(query: text)
    }
    func searchUsers(query:String){
        //check if array has firebase results
        if(hasFetched){
            filterUsers(with: query)
        } else{
            DatabaseManager.shared.getAllUsers {[weak self]result in
                switch result{
                case .success(let usersCollection):
                    self?.hasFetched=true
                    self?.users = usersCollection
                    self?.filterUsers(with: query)
                
                case .failure(let error):
                    print("Failed to get users:\(error)")
                }
            }
        }
    }
    
    func filterUsers(with term:String){
        guard hasFetched else{
            return
        }
        
        self.spinner.dismiss()
        
        //having some confusion ask GPT
        let results:[[String:String]] = self.users.filter({
            guard let name=$0["name"]?.lowercased() else{
                return false
            }
            return name.hasPrefix(term.lowercased())
        })
        self.results=results
//        print(users[0]["email"]!)
        updateUI()
    }
    
    func updateUI(){
        if results.isEmpty{
            self.noResultsLabel.isHidden=false;
            self.tableView.isHidden=true
        }
        else{
            self.noResultsLabel.isHidden=true
            self.tableView.isHidden=false
            self.tableView.reloadData()
        }
    }
}
