//
//  LoginViewController.swift
//  Chat
//
//  Created by Nimish Mangee on 30/07/23.
//

import UIKit
import FirebaseAuth
import JGProgressHUD

final class LoginViewController: UIViewController{
    
    let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds=true
        return scrollView
    }()
    
    let imageView:UIImageView = {
        let imageView=UIImageView()
        imageView.image=UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    let emailField:UITextField = {
        let field=UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius=12
        field.layer.borderWidth=1
        field.layer.borderColor=UIColor.lightGray.cgColor
        field.placeholder="Email"
        field.leftView=UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field;
    }()
    
    let passwordField:UITextField = {
        let field=UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius=12
        field.layer.borderWidth=1
        field.layer.borderColor=UIColor.lightGray.cgColor
        field.placeholder="Password"
        field.leftView=UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry=true
        return field;
    }()
    
    let loginButton: UIButton = {
        let button=UIButton()
        button.setTitle("Log In", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius=12
        button.layer.masksToBounds=true
        button.titleLabel!.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private var loginObserver: NSObjectProtocol?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginObserver=NotificationCenter.default.addObserver(forName: .didLogInNotification, object: nil, queue: .main, using: { [weak self] _ in
            guard let strongSelf=self else{
                return
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil);
        })
        
        title="Log In";
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem=UIBarButtonItem(title: "Register",
                                                          style: .done,
                                                          target: self,
                                                          action: #selector(didTapRegister))
        loginButton.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        emailField.delegate=self
        passwordField.delegate=self
        
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        
        let size=scrollView.width/3
        imageView.frame=CGRect(x: (scrollView.width-size)/2, y: 20, width: size, height: size)
        emailField.frame=CGRect(x: 30, y: imageView.bottom+10, width: scrollView.width-60, height: 52)
        passwordField.frame=CGRect(x: 30, y: emailField.bottom+10, width: scrollView.width-60, height: 52)
        loginButton.frame=CGRect(x: 30, y: passwordField.bottom+10, width: scrollView.width-60, height: 52)
    }
    
    @objc private func loginButtonTapped(){
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email=emailField.text, let password=passwordField.text, !email.isEmpty, !password.isEmpty else{
            alertUserLoginError()
            return;
        }
        
        spinner.show(in: view)
        
        //Firebase log in
        Auth.auth().signIn(withEmail: email, password: password) {[weak self] authResult, error in
            guard let strongSelf=self else{
                return;
            }
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            if let e=error{
                print(e)
            }else{
                print(" User logged in successfully")
                let user=authResult?.user
                
                let safeEmail=DatabaseManager.safeEmail(emailAddress: email)
                DatabaseManager.shared.getDataFor(path: safeEmail) {[weak self] result in
                    switch result{
                    case .success(let data):
                        guard let userData = data as? [String:Any],
                              let firstName = userData["first_name"] as? String,
                              let lastName = userData["last_name"] as? String else{
                            return
                        }
                        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                    case .failure(let error):
                        print("failed to read data with error \(error)")
                    }
                }
                
                UserDefaults.standard.set(email, forKey: "email")
                strongSelf.navigationController?.dismiss(animated: true)
            }
        }
    }
    
    func alertUserLoginError(){
        let alertController = UIAlertController(title: "Login Failed", message:"Please enter correct details", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Dismiss", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
    @objc private func didTapRegister(){
        let vc=RegisterViewController()
        vc.title="Create Account";
        navigationController?.pushViewController(vc, animated: true)
    }
}

extension LoginViewController:UITextFieldDelegate{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField==emailField{
            passwordField.becomeFirstResponder()
        }
            
        if(textField==passwordField){
            loginButtonTapped()
        }
        return true
    }
}
