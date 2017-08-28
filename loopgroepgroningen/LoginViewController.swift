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
    
    @IBAction func onClick(_ sender: UIButton) {
        
        guard
            let username = usernameTextField.text,
            let password = passwordTextField.text
        else {
            return
        }
        
        self.dismiss(animated: true, completion: nil);

        if let completion = completion {
            completion(username, password)
        }
    }
}
