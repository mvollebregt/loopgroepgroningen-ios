//
//  LoginService.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 23-09-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import UIKit

class LoginService {
    
    static func promptUserLogin(_ completionHandler: @escaping () -> ()) {
        
        DispatchQueue.main.async {
            
            let application = UIApplication.shared
            let rootViewController = application.keyWindow?.rootViewController
            
            let loginViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            
            loginViewController.completion = { (username, password) in
                login(username: username, password: password, {(result) in
                    
                    switch result {
                    case .success(true): completionHandler() // als succesvol ingelogd: ga verder
                    case .success(false): promptUserLogin(completionHandler) // als niet succesvol ingelogd: probeer opnieuw
                    case .error(): //bij fout: toon melding en breek af
                        let alert = UIAlertController(title: "Fout", message: "Fout bij inloggen. Probeer het later opnieuw.", preferredStyle: UIAlertControllerStyle.alert)
                        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                        rootViewController?.present(alert, animated: true, completion: nil)
                    }
                })
            }
            
            rootViewController?.present(
                loginViewController, animated: true, completion: nil);
        }
    }
    
    static func login(username: String, password: String, _ completionHandler: @escaping (Result<Bool>) -> ()) {
        
        completionHandler(.error());
        
    }

}
