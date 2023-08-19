//
//  ViewController.swift
//  Chat
//
//  Created by Nimish Mangee on 30/07/23.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

struct Conversation {
    let id: String
    let name: String
    let otherUserEmail: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text:String
    let isRead:Bool
}

class ConversationsViewController: UIViewController {
    
    private var conversations = [Conversation]()
    
    private let spinner=JGProgressHUD(style: .dark)
    
    private let tableView:UITableView = {
       let table=UITableView()
        table.isHidden=true
        table.register(ConversationTableViewCell.self, forCellReuseIdentifier: ConversationTableViewCell.identifier)
//        table.register(UITableViewCell.self, forCellReuseIdentifier: "cell")

        return table;
    }()
    
    private let noConservationsLabel:UILabel = {
       let label=UILabel()
        label.text="No conversations"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
//        label.isHidden=true
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem=UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        view.addSubview(noConservationsLabel)
        setupTableView()
        fetchConversations()
        startListeningForConversation()
    }
    
    private func startListeningForConversation(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return ;
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail) {[weak self] result in
            switch result{
            case .success(let conversations):
                guard !conversations.isEmpty else{
                    print("No conversations found")
                    return
                }
                self?.conversations=conversations
                
//                let x=LatestMessage(date: "", text: "ki kehnda hai ", isRead: true)
//                self?.conversations=[Conversation(id: "123", name: "Nimish", otherUserEmail: "", latestMessage: x)]
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failed to get conversations:\(error)")
            }
        }
    }
    
    @objc func didTapComposeButton(){
        let vc=NewConversationViewController()
        ///not understanding, search GPT
        vc.completion = { [weak self] result in
            print("\(result)")
            self?.createNewConversation(result: result)
        }
        let navVC=UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    func createNewConversation(result: [String:String]) {
        guard let name=result["name"], let email=result["email"] else{
            return;
        }
        let vc=ChatViewController(with: email, id:nil)
        vc.isNewConversation=true
        vc.title="Jenny Smith"
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        tableView.frame=view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        validateAuth();
    }
    
    func validateAuth(){
        if Auth.auth().currentUser == nil {
            let vc = LoginViewController()
            let nav=UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: false);
        }
    }
    
    private func setupTableView(){
        tableView.delegate=self;
        tableView.dataSource=self
    }
    
    func fetchConversations(){
        tableView.isHidden=false;
    }
}

extension ConversationsViewController:UITableViewDelegate, UITableViewDataSource{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        print(conversations.count)
        return conversations.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model=conversations[indexPath.row]
        let cell=tableView.dequeueReusableCell(withIdentifier: ConversationTableViewCell.identifier, for: indexPath) as! ConversationTableViewCell
        cell.configure(with: model)
        
//        cell.textLabel?.text="Hello World"
//        cell.accessoryType = .disclosureIndicator
        return cell;
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model=conversations[indexPath.row]
        
        let vc=ChatViewController(with: model.otherUserEmail, id:model.id)
        vc.title=model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120;
    }
}

