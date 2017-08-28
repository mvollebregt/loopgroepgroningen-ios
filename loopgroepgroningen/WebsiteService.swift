
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
    }
    
    private static func tryLogin(completion: @escaping (Bool) -> ()) {
        DispatchQueue.main.async {
//        OperationQueue.main.addOperation {
            let application = UIApplication.shared
            
            // check of gebruiker ingelogd, zo niet, dan loginvenster tonen
            let rootViewController = application.keyWindow?.rootViewController
            if (!(rootViewController?.presentedViewController is LoginViewController)) {
                let loginViewController = UIStoryboard(name: "Main", bundle: nil)
                    .instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
                loginViewController.completion = { (username, password) in
                    login(username: username, password: password, completion: completion)
                }
                rootViewController?.present(
                    loginViewController, animated: true, completion: nil);
            }
        }
//        );
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
            
            if (!loggedIn(request: url, response: response)) {
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
            
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

                // verwerk resultaat van form post
                print("----")
                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
                print(response!.url as Any)

                if (!loggedIn(request: url, response: response!)) {
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
    
    private static func loggedIn(request: String, response: URLResponse) -> Bool {
        print(request);
        print((response.url?.absoluteString)!);
        return (response.url?.absoluteString)! == request;
    }
}
