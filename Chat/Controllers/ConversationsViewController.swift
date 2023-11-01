//
//  ViewController.swift
//  Chat
//
//  Created by Nimish Mangee on 30/07/23.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

///Controller shows list of conversations 
final class ConversationsViewController: UIViewController {
    
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
        label.text="No Conversations"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
//        label.isHidden=true
        return label
    }()
    
    private var loginObserver:NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.rightBarButtonItem=UIBarButtonItem(barButtonSystemItem: .compose, target: self, action: #selector(didTapComposeButton))
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        view.addSubview(noConservationsLabel)
        setupTableView()
//        fetchConversations()
        startListeningForConversation()
        
        loginObserver=NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf=self else{
                return
            }
//            strongSelf.navigationController?.dismiss(animated: true, completion: nil);
            strongSelf.startListeningForConversation()
        })
    }
    
    private func startListeningForConversation(){
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else{
            return ;
        }
        
        if let observer = loginObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        DatabaseManager.shared.getAllConversations(for: safeEmail) {[weak self] result in
            switch result{
            case .success(let conversations):
                guard !conversations.isEmpty else{
                    print("No conversations found")
                    self?.tableView.isHidden=true
                    self?.noConservationsLabel.isHidden=false
                    return
                }
//                self?.fetchConversations()
                self?.noConservationsLabel.isHidden=true
                self?.tableView.isHidden=false
                self?.conversations=conversations
                
//                let x=LatestMessage(date: "", text: "ki kehnda hai ", isRead: true)
//                self?.conversations=[Conversation(id: "123", name: "Nimish", otherUserEmail: "", latestMessage: x)]
                
                DispatchQueue.main.async {
                    self?.tableView.reloadData()
                }
                
            case .failure(let error):
                print("failed to get conversations:\(error)")
                self?.tableView.isHidden=true
                self?.noConservationsLabel.isHidden=false
            }
        }
    }
    
    @objc private func didTapComposeButton(){
        let vc=NewConversationViewController()
        ///not understanding, search GPT
        vc.completion = { [weak self] result in
            print("\(result)")
            guard let strongSelf=self else{
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversation=currentConversations.first(where: {
                $0.otherUserEmail == DatabaseManager.safeEmail(emailAddress: result.email)
            }){
                let vc=ChatViewController(with: targetConversation.otherUserEmail, id:targetConversation.id)
                vc.isNewConversation=false
                vc.title=targetConversation.name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
            else{
                strongSelf.createNewConversation(result: result)
            }
        }
        let navVC=UINavigationController(rootViewController: vc)
        present(navVC, animated: true)
    }
    
    func createNewConversation(result: SearchResult) {
        let name=result.name
        let email=result.email
        
        // check in datbase if conversation with these two users exists
        // if it does, reuse conversation id
        // otherwise use existing code

        DatabaseManager.shared.conversationExists(with: email, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversationId):
                let vc = ChatViewController(with: email, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: email, id: nil)
                vc.isNewConversation = true
                vc.title = name
                vc.navigationItem.largeTitleDisplayMode = .never
                strongSelf.navigationController?.pushViewController(vc, animated: true)
            }
        })
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        tableView.frame=view.bounds
        noConservationsLabel.frame = CGRect(x: 10, y: (view.height-100)/2, width: view.width-20, height: 100)
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
    
//    private func fetchConversations(){
//        tableView.isHidden=false;
//    }
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
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation){
        let vc=ChatViewController(with: model.otherUserEmail, id:model.id)
        vc.title=model.name
        vc.navigationItem.largeTitleDisplayMode = .never
        navigationController?.pushViewController(vc, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120;
    }
    
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete{
            //begin delete
            let conversationId=conversations[indexPath.row].id
            tableView.beginUpdates()
            self.conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left)
            
            DatabaseManager.shared.deleteConversation(conversationId: conversationId) {[weak self] success in
                if !success{
                    print("failed to delete")
                }
            }
            
            tableView.endUpdates()
        }
    }
}

