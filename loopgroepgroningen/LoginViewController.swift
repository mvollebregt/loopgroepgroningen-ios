//
//  LoginViewController.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 25-07-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import UIKit

class LoginViewController : UIViewController {
    
    @IBOutlet var usernameTextField : UITextField!
    @IBOutlet var passwordTextField : UITextField!
    
    var completion: ((String, String) -> ())?
    
    override func viewDidLoad() {
        if let storedUserName = KeyChain.load(key: "username"), let storedPassword = KeyChain.load(key: "password") {
            usernameTextField.text = String(data: storedUserName, encoding: String.Encoding.utf8)
            passwordTextField.text = String(data: storedPassword, encoding: String.Encoding.utf8);
        }
    }
    
    @IBAction func onClick(_ sender: UIButton) {
        
        guard
            let username = usernameTextField.text,
            let password = passwordTextField.text
        else {
            return
        }
        
        let _ = KeyChain.save(key: "username", data: username.data(using: String.Encoding.utf8, allowLossyConversion: false)!);
        let _ = KeyChain.save(key: "password", data: password.data(using: String.Encoding.utf8, allowLossyConversion: false)!);
        
        self.dismiss(animated: true, completion: nil);

        if let completion = completion {
            completion(username, password)
        }
    }
}
