//
//  LoginService.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 23-09-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import UIKit

class LoginService {
    
    // probeer opnieuw als niet ingelogd
    public static func checkLogin<T>(retry: @escaping((@escaping Handler<T>) -> Void),
                                  with: @escaping Handler<T>,
                                  _ completionHandler: @escaping HttpHandler) -> HttpHandler {
        
        return {(httpResult) in
            
            HttpService.extractElements(withXPathQuery: "//button[@type=\"submit\"]", {(response) in
                
                guard case let .success(loginElements) = response else {
                    completionHandler(.error());
                    return
                }
                
                // is er een button met de tekst "inloggen"?
                for element in loginElements {
                    let value = element.attributes["value"] as! String?
                    if (value != nil && value!.lowercased().contains("inloggen")) {
                        // login en begin weer van voren af aan
                        LoginService.promptUserLogin({() in retry(with)});
                        return
                    }
                    if element.text().lowercased().contains("inloggen") {
                        // login en begin weer van voren af aan
                        LoginService.promptUserLogin({() in retry(with)});
                        return
                    }
                }
                
                // zo nee: ga verder met het oorspronkelijke resultaat
                completionHandler(httpResult);
                
            })(httpResult);
            
        }
    }
    
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
        
        HttpService.postFormNotAuthenticated(
                url: "http://www.loopgroepgroningen.nl/index.php/loopgroep-groningen-ledeninfo",
                formSelector: "@id='login-form'",
                params: ["username": username, "password": password],
            checkLogin(retry: {(completionHandler) in completionHandler(.success(false))}, with: completionHandler,
            {(result) in
                guard case .success(_) = result else {
                    print("Error logging in")
                    completionHandler(.error())
                    return
                }
                completionHandler(.success(true))
            })
        )
    }

}
