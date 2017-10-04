//
//  LoginService.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 23-09-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import UIKit

class LoginService {
    
    // voer een actie uit zonder dat daarvoor een login vereist is
    static func noLogin(_ completionHandler: @escaping (Result<Bool>) -> ()) {
        completionHandler(.success(true));
    }
    
    // vraag de user om in te loggen, als hij nog niet ingelogd is
    static func checkLogin(promptForPassword: Bool = true, _ completionHandler: @escaping (Result<(Bool)>) -> ()) {
        
        noLogin (
            HttpService.get(
                url: "http://www.loopgroepgroningen.nl/index.php/loopgroep-groningen-ledeninfo",
                
                    HttpService.extractElements(withXPathQuery: "//button[@type=\"submit\"]", {(response) in
                        
                        guard case let .success(loginElements) = response else {
                            // fout bij inloggen: kap ermee
                            print("Fout bij checken op geldige login");
                            completionHandler(.error());
                            return
                        }
                        
                        // is er een button met de tekst "inloggen"?
                        var loggedIn = true;
                        for element in loginElements {
                            let value = element.attributes["value"] as! String?
                            if (value != nil && value!.lowercased().contains("inloggen")) {
                                loggedIn = false;
                                break;
                            }
                            if element.text().lowercased().contains("inloggen") {
                                // vraag de gebruiker om in te loggen en check opnieuw
                                loggedIn = false;
                                break;
                            }
                        }
                        
                        if (!loggedIn && promptForPassword) {
                            promptUserLogin(completionHandler);
                            return
                        }
                        
                        if (!loggedIn) {
                            DispatchQueue.main.async(execute: {
                                let rootViewController = UIApplication.shared.keyWindow?.rootViewController
                                let alert = UIAlertController(title: "Inloggen", message: "Inloggen is mislukt. Probeer het opnieuw.", preferredStyle: UIAlertControllerStyle.alert)
                                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                                rootViewController?.present(alert, animated: true, completion: nil)
                            })
                        }
                        
                        // zo nee: ga verder met het oorspronkelijke resultaat
                        completionHandler(.success(loggedIn));
                        
                    })
            )
        )
    }
    
    private static func promptUserLogin(_ completionHandler: @escaping (Result<(Bool)>) -> ()) {
        
        DispatchQueue.main.async {
            
            let application = UIApplication.shared
            let rootViewController = application.keyWindow?.rootViewController
            
            let loginViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
            
            loginViewController.completion = { result in
                
                guard case let .success(username, password) = result else {
                    // gebruiker heeft geannuleerd
                    completionHandler(.success(false))
                    return
                }
                
                login(username: username, password: password, completionHandler)
                
            }
            
            rootViewController?.present(
                loginViewController, animated: true, completion: nil);
        }
    }
    
    private static func login(username: String, password: String, _ completionHandler: @escaping (Result<(Bool)>) -> ()) {
        
        noLogin (
            HttpService.postForm(
                    url: "http://www.loopgroepgroningen.nl/index.php/loopgroep-groningen-ledeninfo",
                    formSelector: "@id='login-form'",
                    params: ["username": username, "password": password],
                    // probeer opnieuw
                    {(_) in checkLogin(promptForPassword: false, completionHandler)}
            )
        )
    }
}
