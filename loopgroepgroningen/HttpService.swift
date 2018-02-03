//
//  WebsiteService.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 28-08-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import UIKit

enum Result<T> {
    case success(T)
    case error()
    
    var result: T {
        switch (self) {
            case .success(let result): return result
            default: return nil as T!
        }
    }
}

typealias Handler<T> = (Result<T>) -> Void
typealias HttpHandler = Handler<(Data, URLResponse)>
typealias ResponseHandler = Handler<[TFHppleElement]>

class HttpService {
    
    // voer een get-request uit
    public static func get(url: String, _ completionHandler: @escaping HttpHandler) -> Handler<Bool> {
        
        return {(successfulLogin) in
            
            guard case .success(true) = successfulLogin else {
                handleError(completionHandler, "actie gestopt ivm niet gelukte login");
                return;
            }
        
            guard let urlObj = URL(string: url) else {
                handleError(completionHandler, "ongeldige URL: %@", url)
                return
            }

            doRequest(request: URLRequest(url: urlObj), completionHandler)
        }
    }
    
    // extraheer elementen met xpath
    public static func extractElements(withXPathQuery: String, _ completionHandler: @escaping ResponseHandler) -> HttpHandler {
        return {(result) in
            
            guard case let .success((data, _)) = result else {
                completionHandler(.error());
                return
            }
            
            guard let parser = TFHpple.init(htmlData: data) else {
                handleError(completionHandler, "Parser could not be initialised for data: %@", data)
                return
            }
            
            guard let elements = parser.search(withXPathQuery: withXPathQuery) as! [TFHppleElement]? else {
                handleError(completionHandler, "No elements found")
                return
            }
            
            completionHandler(.success(elements));
        }
    }
    
    // haal een form op en post het met parameters
    public static func postForm(url: String, formSelector: String, params: [String: String], _ completionHandler: @escaping HttpHandler) -> Handler<Bool> {
        
        return get(url: url,
                postFromGet(url: url, formSelector: formSelector, params: params,
                    completionHandler));

    }
    
    // doe een form post
    private static func postFromGet(url: String, formSelector: String, params: [String: String], _ completionHandler: @escaping HttpHandler) -> HttpHandler {
        
        return extractElements(withXPathQuery: String(format: "//form[%@]", formSelector), {(extractionResult) in

            guard case let .success(elements) = extractionResult else {
                handleError(completionHandler, "Formulier kon niet worden opgehaald op %@", url)
                return
            }
            
            guard elements.count == 1 else {
                handleError(completionHandler, "Formulier kon niet worden opgehaald op %@", url)
                return
            }
            
            let formElement = elements.first!
            var actionUrl = formElement.attributes["action"] as! String;
            if (!actionUrl.contains("loopgroepgroningen.nl")) {
                actionUrl = "http://www.loopgroepgroningen.nl" + actionUrl;
            }
            let inputs = formElement.search(withXPathQuery: "//input") as! [TFHppleElement]
            
            var formData : [String: String] = [:]
            for input in inputs {
                if let value = input.attributes["value"] {
                    let key = input.attributes["name"] as! String
                    formData[key] = value as? String
                }
            }
            
            // params invullen
            for param in params {
                formData[param.0] = param.1
            }
            
            post(url: actionUrl, params: formData, completionHandler);

        })
            
    }
    
    // voer een post-request uit
    private static func post(url: String, params: [String: String], _ completionHandler: @escaping HttpHandler) {
        
        guard let urlObj = URL(string: url) else {
            handleError(completionHandler, "ongeldige URL: %@", url)
            return
        }
        
        // request body maken
        var body = ""
        for keyValue in params {
            if (body != "") {
                body += "&"
            }
            body += keyValue.key + "=" + keyValue.value
        }
        
        var request = URLRequest(url: urlObj)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        
        doRequest(request: request, completionHandler)
    }

    // voer een request uit
    private static func doRequest(request: URLRequest, _ completionHandler: @escaping HttpHandler) {
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            
            guard error == nil else {
                handleError(completionHandler, "fout bij opvragen URL", (request.url, error))
                return
            }
            
            guard let response = response, let data = data else {
                handleError(completionHandler, "geen data bij opvragen URL %@", request.url)
                return
            }
            
            completionHandler(.success(data, response))
        }
        task.resume();
    }
    
    // handel een onverwachte foutsituatie af
    private static func handleError<T>(_ completionHandler: Handler<T>, _ error: String, _ param: Any? = nil) {
        if (param == nil) {
            print(error);
        } else {
            print(String(format: "%@ %@", error, String(describing: param!)));
        }
        completionHandler(.error());
    }
    

    
    
//    
//    
//    
//    
//    private static func getProtectedInfo(url: String, completionHandler: @escaping (Bool) -> ()) {
//        
//        let urlObj = URL(string: url)
//        
//        let task = URLSession.shared.dataTask(with: urlObj!) { data, response, error in
//            guard error == nil else {
//                print(error!)
//                completionHandler(false)
//                return
//            }
//            guard let _ = response, let data = data else {
//                print("Data is empty")
//                completionHandler(false)
//                return
//            }
//            
//            if (!loggedIn(data: data)) {
//                tryLogin() { (success) in
//                    if (success) {
//                        // opnieuw proberen na login
//                        getProtectedInfo(url: url, completionHandler: completionHandler)
//                        return
//                    }
//                }
//            }
//            
//            // testcode:
//            let parser = TFHpple.init(htmlData: data);
//            let elements = parser?.search(withXPathQuery: "//a[@href='/index.php/loopgroep-groningen-ledeninfo/loopgroep-groningen-ledenlijst/16-adri-bouma']") as! [TFHppleElement]?;
//            for element in elements! {
//                print(element.text())
//            }
//            
//        }
//        task.resume()
//    }
//    
//    
//    private static func postForm(url: String, formSelector: String, params: [String: String], completion: @escaping (Bool) -> ()) {
//        
//        print(url)
//        
//        // form ophalen
//        guard let urlObj = URL(string: url) else { return }
//        let task = URLSession.shared.dataTask(with: urlObj) { (data, response, error) in
//            guard error == nil else {
//                print(error!)
//                completion(false)
//                return
//            }
//            guard let response = response, let data = data else {
//                print("Data is empty")
//                completion(false)
//                return
//            }
//            
//            print("----")
//            print(String(data: data, encoding: String.Encoding.utf8)!)
//            print(response.url as Any)
//            
//            if (!loggedIn(data: data) && formSelector != "@id='login-form'") {
//                tryLogin() { (success) in
//                    if (success) {
//                        // opnieuw proberen na login
//                        postForm(url: url, formSelector: formSelector, params: params, completion: completion)
//                        return
//                    }
//                }
//                return
//            }
//            
//            // form-elementen ophalen
//            let parser = TFHpple.init(htmlData: data);
//            let formElements = parser?.search(withXPathQuery: String(format: "//form[%@]", formSelector))
//            let formElement = (formElements as! [TFHppleElement]).first!
//            let elements = formElement.search(withXPathQuery: "//input") as! [TFHppleElement]
//            
//            var formData : [String: String] = [:]
//            for element in elements {
//                if let value = element.attributes["value"] {
//                    let key = element.attributes["name"] as! String
//                    formData[key] = value as? String
//                }
//            }
//            
//            // params invullen
//            for param in params {
//                formData[param.0] = param.1
//            }
//            
//            // request body maken
//            var body = ""
//            for keyValue in formData {
//                if (body != "") {
//                    body += "&"
//                }
//                body += keyValue.key + "=" + keyValue.value
//            }
//            
//            // form posten
//            var request = URLRequest(url: urlObj)
//            request.httpMethod = "POST"
//            request.httpBody = body.data(using: .utf8)
//            
//            // FORM DAADWERKELIJK POSTEN
//            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
//                
//                // verwerk resultaat van form post
//                print("----")
//                print(String(data: data!, encoding: String.Encoding.utf8) as Any)
//                print(response!.url as Any)
//                
//                if (!loggedIn(data: data!)) {
//                    // TODO: check op wel of niet ingelogd werkt niet.
//                    // als ik een post doe uit /prikbord/entry/add word ik doorgelust naar prikbord, en dat is helemaal prima
//                    // maar de app denkt dat ik dan niet meer ingelogd ben!
//                    tryLogin() { (success) in
//                        if (success) {
//                            // opnieuw proberen na login
//                            postForm(url: url, formSelector: formSelector, params: params, completion: completion)
//                            return
//                        }
//                    }
//                } else {
//                    completion(true)
//                }
//            }
//            task.resume()
//            
//        }
//        task.resume()
//    }
//    
//    private static func loggedIn(data: Data) -> Bool {
//        let parser = TFHpple.init(htmlData: data);
//        // zoek naar buttons met de tekst "inloggen"
//        let loginElements = parser?.search(withXPathQuery: String(format: "//button[@type=\"submit\"]")) as! [TFHppleElement]
//        
//        for element in loginElements {
//            let value = element.attributes["value"] as! String?
//            if (value != nil && value!.lowercased().contains("inloggen")) {
//                return false;
//            }
//            if element.text().lowercased().contains("inloggen") {
//                return false;
//            }
//        }
//        
//        return true;
//        
//        //        print(request);
//        //        print((response.url?.absoluteString)!);
//        //        return (response.url?.absoluteString)! == request;
//    }
}
