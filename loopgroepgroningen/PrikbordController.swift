//
//  PrikbordController.swift
//  loopgroepgroningen
//
//  Created by Michel Vollebregt on 11-06-17.
//  Copyright © 2017 Michel Vollebregt. All rights reserved.


//

import UIKit
import CoreData

class PrikbordController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate, UITextViewDelegate {
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var sendButton: UIButton!
    
    var fetchedResultsController: NSFetchedResultsController<BerichtMO>!
    var currentKeyboardHeight = CGFloat(0);
    
    func initializeFetchedResultsController() {
        let request = NSFetchRequest<BerichtMO>(entityName: "Bericht")
        let tijdstipSort = NSSortDescriptor(key: "volgnummer", ascending: true)
        request.sortDescriptors = [tijdstipSort]
        
        let moc = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        fetchedResultsController = NSFetchedResultsController(fetchRequest: request, managedObjectContext: moc, sectionNameKeyPath: nil, cacheName: nil)
        fetchedResultsController.delegate = self
        
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Failed to initialize FetchedResultsController: \(error)")
        }
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.beginUpdates()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch (type) {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
            break;
        default:
            
            print("did receive fetch with type ", type)
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.tableView.endUpdates()
        scrollToBottom()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 230 // TODO
        tableView.allowsSelection = false
        
//        textView.layer.borderWidth = 5.0
        
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.lightGray.cgColor
        textView.layer.cornerRadius = 8
        
        
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        
        initializeFetchedResultsController()
        print("view did load")
        // TODO: hier ook syncen?
        PrikbordService.syncBerichten(completionHandler: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive(notification:)), name: NSNotification.Name.UIApplicationDidBecomeActive, object:nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        scrollToBottom()
    }

    func scrollToBottom() {
        let lastRow = tableView(tableView, numberOfRowsInSection: 0) - 1;
        if (lastRow > -1) {
            self.tableView.scrollToRow(at: IndexPath(row:
                tableView(tableView, numberOfRowsInSection: 0) - 1, section: 0), at:UITableViewScrollPosition.bottom, animated: false)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BerichtTableViewCell", for: indexPath) as! BerichtCell
        // Set up the cell
        guard let bericht = self.fetchedResultsController?.object(at: indexPath) else {
            fatalError("Attempt to configure cell without a managed object")
        }
        cell.bericht = bericht
        return cell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections!.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sections = fetchedResultsController.sections else {
            fatalError("No sections in fetchedResultsController")
        }
        let sectionInfo = sections[section]
        return sectionInfo.numberOfObjects
    }
    
    
    func keyboardWillShow(notification: NSNotification)  {
        if let newKeyboardHeight = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue.height {
            let keyboardHeightDiff = newKeyboardHeight - currentKeyboardHeight
            setContentOffsetY(self.tableView.contentOffset.y + keyboardHeightDiff);
            self.view.frame.size.height -= keyboardHeightDiff
            currentKeyboardHeight = newKeyboardHeight;
        }
    }
    
    // TODO: taal van de textview/ de hele app instellen (nu verschijnt er 'select all' in plaats van 'selecteer alles')
    
    func keyboardWillHide(notification: NSNotification) {
        setContentOffsetY(self.tableView.contentOffset.y - currentKeyboardHeight)
        self.view.frame.size.height += currentKeyboardHeight
        currentKeyboardHeight = CGFloat(0)
    }
    
    private func setContentOffsetY(_ newContentOffsetY: CGFloat) {
        let navBarHeight = (self.navigationController?.navigationBar.intrinsicContentSize.height)!
            + UIApplication.shared.statusBarFrame.height
        if (newContentOffsetY >= -navBarHeight) {
//            print(newContentOffsetY);
            self.tableView.setContentOffset(CGPoint(x: 0, y: newContentOffsetY), animated: false)
        } else {
            self.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: false)
        }
    }
    
    func appDidBecomeActive(notification: NSNotification) {
        setContentOffsetY(self.tableView.contentOffset.y + currentKeyboardHeight);
        self.view.frame.size.height -= currentKeyboardHeight;
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    
    @IBAction func onClickVerstuur(_ sender: UIButton) {
        // TODO: versturen-knop disablen als geen tekst ingevoerd!!!
        WebsiteService.addPrikbordEntry(bericht: textView.text) { (success) in
            if (success) {
                DispatchQueue.main.async {
                    self.textView.text = ""
                    self.dismissKeyboard()
                }
            }
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        sendButton.isEnabled = !textView.text.isEmpty
    }
    
//    func textViewDidChange(_ textView: UITextView) {
//        textView.isScrollEnabled = false
//
//        let fixedWidth = textView.frame.size.width
//        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
//        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
//        var newFrame = textView.frame
//        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
//        textView.frame = newFrame
//    }
    
//    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        return CGFloat(40 + 20 * indexPath.row);
//    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
