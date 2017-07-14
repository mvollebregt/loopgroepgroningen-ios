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
    
    static func syncBerichten() {
        
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
                    return
                }
                guard let data = data else {
                    print("Data is empty")
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
                var volgnummer = nieuwsteBericht.first?.volgnummer ?? 0
                for bericht in berichten.reversed() {
                    bericht.volgnummer = volgnummer
//                    managedObjectContext.insert(bericht)
                    volgnummer += 1
                }
                do {
                    try managedObjectContext.save()
                } catch {
                    fatalError("Kon managed object context niet opslaan")
                }
            }
            task.resume()
        }
        catch {
            fatalError("Synchronisatie mislukt")
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
