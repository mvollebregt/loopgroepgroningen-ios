//
//  PrikbordService.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 22-06-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import UIKit
import CoreData
import UserNotifications

class PrikbordService {
    
    static let berichtenXPathQuery = "//div[@class='easy_frame']"
    
    // synchroniseert de berichten: geeft true terug als er nieuwe berichten zijn en false als dat niet zo is
    static func syncBerichten(completionHandler: @escaping Handler<Bool>) {

        // TODO: locking mechanisme op de juiste plek zetten!
        let lockQueue = DispatchQueue(label: "com.github.mvollebregt.prikbord")
        lockQueue.sync() {
            
            LoginService.noLogin (
                HttpService.get(url: "http://www.loopgroepgroningen.nl/index.php/prikbord",
                    HttpService.extractElements(withXPathQuery: berichtenXPathQuery,
                        slaBerichtenOp(completionHandler))))
            
        }
    }
    
    // test of de gebruiker is ingelogd: geeft true terug indien de gebruiker heeft ingelogd en de informatie achter de inlog goed is opgehaald
//    static func testLogin(_ completionHandler: @escaping Handler<Bool>) {
//
//        LoginService.checkLogin (
//            HttpService.get(url: "http://www.loopgroepgroningen.nl/index.php/loopgroep-groningen-ledeninfo/loopgroep-groningen-ledenlijst",
//                HttpService.extractElements(withXPathQuery: "//a[@href='/index.php/loopgroep-groningen-ledeninfo/loopgroep-groningen-ledenlijst/16-adri-bouma']",{(result) in
//
//                        // we verwachten een succesvol resultaat
//                        guard case let .success(elements) = result else {
//                            completionHandler(.error());
//                            return
//                        }
//
//                        // als er elementen zijn is de informatie goed opgehaald
//                        completionHandler(.success(!elements.isEmpty))
//                    }
//            ))
//        );
//    }
    
    // post een bericht en ververs meteen de berichten: geeft true terug indien bericht gepost en false als dat niet zo is
    static func verzendBericht(berichttekst: String, _ completionHandler: @escaping Handler<Bool>) {
        
        if UserDefaults.standard.bool(forKey: "demo") {
            
            do {
                let into = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
                // nieuwste al opgeslagen bericht
                let request = NSFetchRequest<BerichtMO>(entityName: "Bericht")
                request.sortDescriptors = [NSSortDescriptor(key: "volgnummer", ascending: false)]
                let nieuwsteBericht = try into.fetch(request)
                
                let bericht = NSEntityDescription.insertNewObject(forEntityName: "Bericht", into: into) as! BerichtMO
                bericht.auteur = "demo"
                
                let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
                let now = Date();
                let weekDayNum = myCalendar.component(.weekday, from: now)
                var date = ["za", "zo", "ma" ,"di", "wo", "do", "vr", "za"][weekDayNum]
                let formatter = DateFormatter()
                formatter.dateFormat = " dd "
                date += formatter.string(from: now);
                let monthNum = myCalendar.component(.month, from: now)
                date += ["dec", "jan", "feb", "maa", "apr", "mei", "jun", "jul", "aug", "sep", "okt", "nov", "dec"][monthNum]
                formatter.dateFormat = " yyyy - HH:mm"
                date += formatter.string(from: now);
                bericht.tijdstip = date
                bericht.berichttekst = berichttekst
                bericht.volgnummer = (nieuwsteBericht.first?.volgnummer ?? -1) + 1
                completionHandler(.success(true))
            }
            catch {
                print("synchronisatie mislukt")
                completionHandler(.error())
            }

            
        } else {
            
            LoginService.checkLogin (
                
                // De website EIST dat je EERST naar het prikbord gaat, en pas DAARNA naar het verzendformulier
                HttpService.get(url: "http://www.loopgroepgroningen.nl/index.php/prikbord", {(result) in
                    
                    guard case .success(_) = result else {
                        completionHandler(.error())
                        return
                    }
                
                    // OK, we hebben het prikbord opgehaald, nu gaan we echt het bericht posten
                    LoginService.noLogin(
                        HttpService.postForm(
                            url: "http://www.loopgroepgroningen.nl/index.php/prikbord/entry/add",
                            formSelector: "@name='gbookForm'",
                            params: ["gbtext": berichttekst],
                            
                            // synchroniseer de berichten adhv de response
                            {(postBerichtResult) in
                                
                                guard case let .success(_, response) = postBerichtResult, let url = response.url else {
                                    completionHandler(.error())
                                    return
                                }
                                
                                // check dat de post wel succesvol is uitgevoerd - als we nog steeds op de entry/add-pagina zijn ging er iets mis
                                guard !url.absoluteString.contains("entry/add") else {
                                    completionHandler(.success(false))
                                    return
                                }
                                
                                HttpService.extractElements(withXPathQuery: berichtenXPathQuery,
                                    slaBerichtenOp( {(synchronisatieResult) in
                                        
                                        // stuur het resultaat van het posten van het bericht terug, en NIET het resultaat van het synchroniseren
                                        switch postBerichtResult {
                                        case .error(): completionHandler(.error())
                                        case .success(_): completionHandler(.success(true)) // als we een http response hebben zal het bericht wel gepost zijn (check op fout in html?)
                                        }
                                        
                                        
                                    })
                                )(postBerichtResult)
                            }
                        )
                    )
                })
            )
        }
    }
    
    private static func slaBerichtenOp(_ completionHandler: @escaping Handler<Bool>) -> ResponseHandler {
        
        return {(result) in

            guard case let .success(elements) = result else {
                completionHandler(.error());
                return
            }
            
            DispatchQueue.main.async(execute: {
                let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

                do {
                    // nieuwste al opgeslagen bericht
                    let request = NSFetchRequest<BerichtMO>(entityName: "Bericht")
                    request.sortDescriptors = [NSSortDescriptor(key: "volgnummer", ascending: false)]
                    let nieuwsteBericht = try managedObjectContext.fetch(request)
                    
                    let vergelijkbericht = nieuwsteBericht.first(where: {$0.auteur != "demo"});
                
                    var berichten = [BerichtMO]()
                    for element in elements {
                        let bericht = mapToBerichtMO(element: element, into: managedObjectContext)
                        if (vergelijkbericht != nil && (equal(bericht1: bericht, bericht2: vergelijkbericht!))) {
                            managedObjectContext.delete(bericht)
                            break
                        }
                        berichten.append(bericht)
                    }
                
                    print("nieuwe berichten", berichten.count)
                    
                    // opslaan van alle nieuwe berichten
                    var volgnummer = nieuwsteBericht.first?.volgnummer ?? -1
                    for bericht in berichten.reversed() {
                        volgnummer += 1
                        bericht.volgnummer = volgnummer
    //                    managedObjectContext.insert(bericht)
                    }
                    do {
                        print("saving context")
                        try managedObjectContext.save()
                    } catch {
                        print("kon managed object context niet opslaan")
                        completionHandler(.error())
                    }
                    
                    notify(berichten: berichten);

                    completionHandler(.success(berichten.count > 0))
                    
                }
                catch {
                    print("synchronisatie mislukt")
                    completionHandler(.error())
                }
            })
        }
    }
    
    
    private static func notify(berichten: [BerichtMO]) {
        let userDefaults = UserDefaults.standard
        let badgeCount = userDefaults.integer(forKey: "badgeCount") + berichten.count;
        userDefaults.set(badgeCount, forKey: "badgeCount")
        
        for bericht in berichten {
            let content = UNMutableNotificationContent()
            content.title = bericht.auteur!
            content.body = bericht.berichttekst!
            content.badge = NSNumber(value: badgeCount)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: String(format:"Loopgroep %d", bericht.volgnummer), content: content, trigger: trigger)
            let center = UNUserNotificationCenter.current()
            center.add(request) { (error : Error?) in
                if let theError = error {
                    print(theError.localizedDescription)
                }
            }
        }
    }
    
    static func mapToBerichtMO(element: TFHppleElement, into: NSManagedObjectContext) -> BerichtMO {
        let bericht = NSEntityDescription.insertNewObject(forEntityName: "Bericht", into: into) as! BerichtMO
        bericht.auteur = getText(fromElement:element, withXPathQuery: "//*[@class='easy_big']");
        bericht.tijdstip = formatBerichtDatum(datum: getText(fromElement:element, withXPathQuery: "//*[@class='easy_small']"))
        bericht.berichttekst = ""
        
        let berichtElements = element.search(withXPathQuery: "//*[@class='easy_content']/node()") as! [TFHppleElement]?
        
        for contentElement in berichtElements! {
            if (contentElement.isTextNode()) {
                bericht.berichttekst!.append(contentElement.content)
            } else {
                bericht.berichttekst!.append("\n");
            }
        }
        bericht.berichttekst = bericht.berichttekst?.trimmingCharacters(in: .whitespacesAndNewlines)
        return bericht

    }
    
    static func formatBerichtDatum(datum: String) -> String {
        let woorden = datum.split(separator: " ")
        return String(format: "%@ %@ %@ %@ - %@",
                      String(woorden[0][...woorden[0].index(woorden[0].startIndex, offsetBy: 1)]),
                      String(woorden[1]),
                      String(woorden[2][...woorden[2].index(woorden[2].startIndex, offsetBy: 2)]),
                      String(woorden[3]),
                      String(woorden[4]))
    }
    
    static func equal(bericht1: BerichtMO, bericht2: BerichtMO) -> Bool {
        return
            bericht1.auteur == bericht2.auteur &&
            bericht1.berichttekst == bericht2.berichttekst &&
            bericht1.tijdstip == bericht2.tijdstip
    }
    
    static func getText(fromElement: TFHppleElement, withXPathQuery: String) -> String {
        let auteurElements = fromElement.search(withXPathQuery: withXPathQuery) as! [TFHppleElement]?
        if (auteurElements!.count > 0) {
            return auteurElements![0].content.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
        }
        return "";
    }
    
}
