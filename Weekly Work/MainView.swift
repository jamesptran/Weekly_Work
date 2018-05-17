//
//  ViewController.swift
//  Weekly Work
//
//  Created by James Tran on 10/9/17.
//  Copyright © 2017 James Tran. All rights reserved.
//

import UIKit
import CoreData

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    
    let dayNameList = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    var dayChosenIndex = -1
    let defaults:UserDefaults = UserDefaults.standard

    var dayList : [Day] = []
    var workList : [Work] = []
    
    // View setup and additional functions
    // Create 7 day ManagedObjects for CoreData if no day object found.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        let fetchRequest = NSFetchRequest<Day>(entityName: "Day")
        do {
            dayList = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        if dayList.count == 0 {
            for dayName in dayNameList {
                let dayEntity = NSEntityDescription.entity(forEntityName: "Day", in: managedContext)!
                let day = Day(entity: dayEntity, insertInto: managedContext)
                
                day.setValue(dayName, forKeyPath: "name")
                
                do {
                    try managedContext.save()
                } catch let error as NSError {
                    print("Could not save. \(error), \(error.userInfo)")
                }
            }
        } else {
            if dayList.count != 7 {
                print("Number of day object is not 7 or 0. Reset app.")
            }
        }
        
        let today = dayNameList[getDayOfWeek()]
        if today == "Sunday" {
            for dayObj in dayList {
                for workObj in (dayObj.getWork?.allObjects as! [Work]) {
                    workObj.hoursLeft = workObj.maxHours
                }
            }
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
        }
        
        // Use notification center to detect app resumes to resume the spining animation
        NotificationCenter.default.addObserver(self, selector:#selector(MainViewController.appResumesBackground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)

    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func appResumesBackground() {
        tableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        
        dayChosenIndex = getDayOfWeek()
        
        let indexPath = IndexPath(row: dayChosenIndex, section: 0)
        collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: true)
        
        
        let fetchRequest = NSFetchRequest<Day>(entityName: "Day")
        do {
            dayList = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        
        reloadWorkList()
        collectionView.reloadData()
        tableView.reloadData()
    }
    
    @IBAction func resetButtonTouched(_ sender: Any) {
        let alert = UIAlertController(title: "Reset", message: "Reset all work timer? Keep in mind that all the timer will be automatically reset every Sunday.", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { action in
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let managedContext = appDelegate.persistentContainer.viewContext
            
            for dayObj in self.dayList {
                for workObj in (dayObj.getWork?.allObjects as! [Work]) {
                    workObj.hoursLeft = workObj.maxHours
                }
            }
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            
            alert.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "No", style: .default, handler: { action in
            alert.dismiss(animated: true, completion: nil)
        }))

        
        self.present(alert, animated: true, completion: nil)
        return
    }
    
    
    // Used to reload the workList based on the day selected on the dayList
    func reloadWorkList() {
        let chosenDayName = dayNameList[dayChosenIndex]
        for dayDataObject in dayList {
            if dayDataObject.name == chosenDayName {
                workList = (dayDataObject.getWork?.allObjects as? [Work]) ?? []
            }
        }
        
        print(dayList)
        print(dayList.count)
    }
    
    func getDayOfWeek()->Int {
        let todayDate = Date(timeIntervalSinceNow: 0)
        let myCalendar = NSCalendar(calendarIdentifier: NSCalendar.Identifier.gregorian)!
        let myComponents = myCalendar.components(.weekday, from: todayDate)
        let weekDay = myComponents.weekday
        return (weekDay ?? -1) - 1
    }

    // Collection View, the day of week list. The data displayed is dayList and dayNameList
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dayNameList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCollectionCell", for: indexPath) as! DayCollectionCell
        var imageName = dayNameList[indexPath.row]
        if indexPath.row == dayChosenIndex {
            imageName += "Inv"
            cell.backgroundColor = .black
        } else {
            cell.backgroundColor = .white
        }
        
        cell.dayIconImageView.image = UIImage(named: imageName)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dayChosenIndex = indexPath.row
        collectionView.reloadData()
        collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: true)
        
        reloadWorkList()
        tableView.reloadData()
        if dayChosenIndex == getDayOfWeek() {
            
        }
    }
    
    // Table View, the work for each day list. The data displayed is workList
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "WorkTableCell") as! WorkTableCell
        
        cell.workName.text = workList[indexPath.row].name ?? ""
        if workList[indexPath.row].isTicking {
            cell.statusImage.image = UIImage(named: "Three_Dots")
        } else {
            cell.statusImage.image = UIImage(named: "Calendar_X")
        }
        
        if workList[indexPath.row].hoursLeft <= 0.0003 {
            cell.statusImage.image = UIImage(named: "Calendar_Tick")
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let delete = UITableViewRowAction(style: .normal, title: "Delete") { action, index in
            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
                return
            }
            let managedContext = appDelegate.persistentContainer.viewContext
            
            managedContext.delete(self.workList[indexPath.row])
            self.workList.remove(at: indexPath.row)
            
            do {
                try managedContext.save()
            } catch let error as NSError {
                print("Could not save. \(error), \(error.userInfo)")
            }
            
            tableView.deleteRows(at: [indexPath], with: .automatic)
        }
        delete.backgroundColor = .red
        
        return [delete]
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "Main-TimerViewSegue", sender: workList[indexPath.row])
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        var numOfSections: Int = 1
        if workList.count > 0
        {
            numOfSections = 1
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
        else
        {
            let noDataLabel: UILabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
            noDataLabel.text = "No work scheduled this day"
            noDataLabel.font = noDataLabel.font.withSize(20)
            noDataLabel.textColor = UIColor.gray
            noDataLabel.textAlignment = .center
            tableView.backgroundView = noDataLabel
            tableView.separatorStyle = .none
        }
        return numOfSections
    }
    
    
    
    // Prepare for segue methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Main-TimerViewSegue" {
            if let timerVC = segue.destination as? TimerViewController {
                if let workSelected = sender as? Work {
                    timerVC.workImported = workSelected
                }
            }
        }
    }
}

class DayCollectionCell : UICollectionViewCell {
    @IBOutlet var dayIconImageView: UIImageView!
}

class WorkTableCell : UITableViewCell {
    @IBOutlet var workName: UILabel!
    @IBOutlet var statusImage: UIImageView!
    
}



