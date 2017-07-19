//
//  PrikbordService.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 22-06-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.
//

import UIKit
import CoreData

class PrikbordService {
    
    static func syncBerichten(completionHandler: Optional<(UIBackgroundFetchResult) -> Void>) {
        
        // TODO: locking mechanisme op de juiste plek zetten!
        let lockQueue = DispatchQueue(label: "com.github.mvollebregt.prikbord")
        lockQueue.sync() {
            
            let managedObjectContext = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

            do {
                // nieuwste al opgeslagen bericht
                let request = NSFetchRequest<BerichtMO>(entityName: "Bericht")
                request.sortDescriptors = [NSSortDescriptor(key: "volgnummer", ascending: false)]
                let nieuwsteBericht = try managedObjectContext.fetch(request)

                // berichten ophalen van website tot aan nieuwste al opgeslagen bericht
                let url = URL(string: "http://www.loopgroepgroningen.nl/index.php/prikbord")
                
                let task = URLSession.shared.dataTask(with: url!) { data, response, error in
                    guard error == nil else {
                        print(error!)
                        completionHandler?(UIBackgroundFetchResult.failed)
                        return
                    }
                    guard let data = data else {
                        print("Data is empty")
                        completionHandler?(UIBackgroundFetchResult.failed)
                        return
                    }
                    
                    let parser = TFHpple.init(htmlData: data);
                    let elements = parser?.search(withXPathQuery: "//div[@class='easy_frame']") as! [TFHppleElement]?;
                    
                    var berichten = [BerichtMO]()
                    for element in elements! {
                        let bericht = mapToBerichtMO(element: element, into: managedObjectContext)
                        if (!nieuwsteBericht.isEmpty && (equal(bericht1: bericht, bericht2: nieuwsteBericht.first!))) {
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
                        completionHandler?(UIBackgroundFetchResult.failed)
                    }
                    print("call completion handler")
                    completionHandler?(berichten.count == 0 ? UIBackgroundFetchResult.noData : UIBackgroundFetchResult.newData)
                }
                task.resume()
            }
            catch {
                fatalError("Synchronisatie mislukt")
            }
        }
    }
    
    static func mapToBerichtMO(element: TFHppleElement, into: NSManagedObjectContext) -> BerichtMO {
        let bericht = NSEntityDescription.insertNewObject(forEntityName: "Bericht", into: into) as! BerichtMO
        bericht.auteur = getText(fromElement:element, withXPathQuery: "//*[@class='easy_big']");
        bericht.tijdstip = getText(fromElement:element, withXPathQuery: "//*[@class='easy_small']")
        bericht.berichttekst = ""
        
        let berichtElements = element.search(withXPathQuery: "//*[@class='easy_content']/node()") as! [TFHppleElement]?
        
        for contentElement in berichtElements! {
            if (contentElement.isTextNode()) {
                bericht.berichttekst!.append(contentElement.content)
            } else {
                bericht.berichttekst!.append("\n");
            }
        }
        return bericht

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
