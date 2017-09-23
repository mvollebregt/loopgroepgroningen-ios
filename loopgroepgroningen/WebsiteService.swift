
//
//  WebsiteService.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 28-08-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import UIKit

class WebsiteService {
    
    static func login(username: String, password: String, completion: @escaping (Bool) -> ()) {
        postForm(url: "http://www.loopgroepgroningen.nl/index.php/loopgroep-groningen-ledeninfo",
                 formSelector: "@id='login-form'",
                 params: ["username": username, "password": password],
                 completion: completion)
    }
    
    static func addPrikbordEntry(bericht: String, completion: @escaping (Bool) -> ()) {
        postForm(url: "http://www.loopgroepgroningen.nl/index.php/prikbord/entry/add",
                 formSelector: "@name='gbookForm'",
                 params: ["gbtext": bericht],
                 completion: completion)
        // TODO: response is prikbord zelf! dit kan ik uitlezen om het prikbord weer te verversen!
        // TODO: als niet gelukt/offline, dan bericht bewaren voor later?
    }
    
    static func testLogin(completion: @escaping (Bool) -> ()) {
        
        getProtectedInfo(url: "http://www.loopgroepgroningen.nl/index.php/loopgroep-groningen-ledeninfo/loopgroep-groningen-ledenlijst", completionHandler: completion)
    }
    
    private static func tryLogin(completion: @escaping (Bool) -> ()) {
        DispatchQueue.main.async {
//        OperationQueue.main.addOperation {
            let application = UIApplication.shared
            
            let rootViewController = application.keyWindow?.rootViewController
//            if (!(rootViewController?.presentedViewController is LoginViewController)) {
                let loginViewController = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                loginViewController.completion = { (username, password) in
                    login(username: username, password: password, completion: completion)
                }
                rootViewController?.present(
                    loginViewController, animated: true, completion: nil);
            
                // MODAL maken?!?
            
//            }
        }
//        );
    }
    
    private static func getProtectedInfo(url: String, completionHandler: @escaping (Bool) -> ()) {
        
        let urlObj = URL(string: url)
        
        let task = URLSession.shared.dataTask(with: urlObj!) { data, response, error in
            guard error == nil else {
                print(error!)
                completionHandler(false)
                return
            }
            guard let _ = response, let data = data else {
                print("Data is empty")
                completionHandler(false)
                return
            }
            
            if (!loggedIn(data: data)) {
                tryLogin() { (success) in
                    if (success) {
                        // opnieuw proberen na login
                        getProtectedInfo(url: url, completionHandler: completionHandler)
                        return
                    }
                }
            }
            
            // testcode:
            let parser = TFHpple.init(htmlData: data);
            let elements = parser?.search(withXPathQuery: "//a[@href='/index.php/loopgroep-groningen-ledeninfo/loopgroep-groningen-ledenlijst/16-adri-bouma']") as! [TFHppleElement]?;
            for element in elements! {
                print(element.text())
            }
            
        }
        task.resume()
    }
    
    
    private static func postForm(url: String, formSelector: String, params: [String: String], completion: @escaping (Bool) -> ()) {
        
        print(url)
        
        // form ophalen
        guard let urlObj = URL(string: url) else { return }
        let task = URLSession.shared.dataTask(with: urlObj) { (data, response, error) in
            guard error == nil else {
                print(error!)
                completion(false)
                return
            }
            guard let response = response, let data = data else {
                print("Data is empty")
                completion(false)
                return
            }
            
            print("----")
            print(String(data: data, encoding: String.Encoding.utf8)!)
            print(response.url as Any)
            
            if (!loggedIn(data: data) && formSelector != "@id='login-form'") {
                tryLogin() { (success) in
                    if (success) {
                        // opnieuw proberen na login
                        postForm(url: url, formSelector: formSelector, params: params, completion: completion)
                        return
                    }
                }
                return
            }
            
            // form-elementen ophalen
            let parser = TFHpple.init(htmlData: data);
            let formElements = parser?.search(withXPathQuery: String(format: "//form[%@]", formSelector))
            let formElement = (formElements as! [TFHppleElement]).first!
            let elements = formElement.search(withXPathQuery: "//input") as! [TFHppleElement]
            
            var formData : [String: String] = [:]
            for element in elements {
                if let value = element.attributes["value"] {
                    let key = element.attributes["name"] as! String
                    formData[key] = value as? String
                }
            }
            
            // params invullen
            for param in params {
                formData[param.0] = param.1
            }
            
            // request body maken
            var body = ""
            for keyValue in formData {
                if (body != "") {
                    body += "&"
                }
                body += keyValue.key + "=" + keyValue.value
            }
            
            // form posten
            var request = URLRequest(url: urlObj)
            request.httpMethod = "POST"
            request.httpBody = body.data(using: .utf8)

            // FORM DAADWERKELIJK POSTEN
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

                // verwerk resultaat van form post
                print("----")
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                print(response!.url as Any)

                if (!loggedIn(data: data!)) {
                    // TODO: check op wel of niet ingelogd werkt niet.
                    // als ik een post doe uit /prikbord/entry/add word ik doorgelust naar prikbord, en dat is helemaal prima
                    // maar de app denkt dat ik dan niet meer ingelogd ben!
                    tryLogin() { (success) in
                        if (success) {
                            // opnieuw proberen na login
                            postForm(url: url, formSelector: formSelector, params: params, completion: completion)
                            return
                        }
                    }
                } else {
                    completion(true)
                }
            }
            task.resume()
        
        }
        task.resume()
    }
    
    private static func loggedIn(data: Data) -> Bool {
        let parser = TFHpple.init(htmlData: data);
        // zoek naar buttons met de tekst "inloggen"
        let loginElements = parser?.search(withXPathQuery: String(format: "//button[@type=\"submit\"]")) as! [TFHppleElement]
        
        for element in loginElements {
            let value = element.attributes["value"] as! String?
            if (value != nil && value!.lowercased().contains("inloggen")) {
                return false;
            }
            if element.text().lowercased().contains("inloggen") {
                return false;
            }
        }

        return true;
        
        //        print(request);
//        print((response.url?.absoluteString)!);
//        return (response.url?.absoluteString)! == request;
    }
}
