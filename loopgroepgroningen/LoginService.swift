//
//  LoginService.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 23-09-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import UIKit

class LoginService {
    
    // vraag de user om in te loggen, als hij nog niet ingelogd is
    static func checkLogin(_ completionHandler: @escaping () -> ()) {
        
        HttpService.get(
            url: "http://www.loopgroepgroningen.nl/index.php/loopgroep-groningen-ledeninfo",
            
                HttpService.extractElements(withXPathQuery: "//button[@type=\"submit\"]", {(response) in
                    
                    guard case let .success(loginElements) = response else {
                        // fout bij inloggen: kap ermee
                        print("Fout bij checken op geldige login");
                        return
                    }
                    
                    // is er een button met de tekst "inloggen"?
                    for element in loginElements {
                        let value = element.attributes["value"] as! String?
                        if (value != nil && value!.lowercased().contains("inloggen")) {
                            // vraag de gebruiker om in te loggen en check opnieuw
                            promptUserLogin(completionHandler);
                            return
                        }
                        if element.text().lowercased().contains("inloggen") {
                            // vraag de gebruiker om in te loggen en check opnieuw
                            promptUserLogin(completionHandler);
                            return
                        }
                    }
                    
                    // zo nee: ga verder met het oorspronkelijke resultaat
                    completionHandler();
                    
                })
        )
    }
    
    private static func promptUserLogin(_ completionHandler: @escaping () -> ()) {
        
        DispatchQueue.main.async {
            
            let application = UIApplication.shared
            let rootViewController = application.keyWindow?.rootViewController
            
            let loginViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            
            loginViewController.completion = { (username, password) in
                login(username: username, password: password, completionHandler)}
            
            rootViewController?.present(
                loginViewController, animated: true, completion: nil);
        }
    }
    
    private static func login(username: String, password: String, _ completionHandler: @escaping () -> ()) {
        
        HttpService.postForm(
                url: "http://www.loopgroepgroningen.nl/index.php/loopgroep-groningen-ledeninfo",
                formSelector: "@id='login-form'",
                params: ["username": username, "password": password],
                // probeer het weer opnieuw
                {(_) in checkLogin(completionHandler)}
        )
    }

}
