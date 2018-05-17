//
//  AddWork.swift
//  Weekly Work
//
//  Created by James Tran on 10/13/17.
//  Copyright © 2017 James Tran. All rights reserved.
//

import Foundation
import UIKit
import CoreData


class AddWorkViewController : UIViewController, UICollectionViewDelegateFlowLayout, UITextFieldDelegate {
    
    @IBOutlet weak var workName: UITextField!
    @IBOutlet weak var workGoal: UITextField!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    
    let dayNameList = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "All"]
    
    var dayNameDict : [String : Bool] = [ "Sunday" : false, "Monday" : false, "Tuesday" : false, "Wednesday" : false, "Thursday" : false, "Friday" : false, "Saturday" : false, "All" : false ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let datePickerView = UIDatePicker()

        datePickerView.datePickerMode = UIDatePickerMode.countDownTimer
        datePickerView.minuteInterval = 10

        datePickerView.addTarget(self, action: #selector(AddWorkViewController.datePickerValueChanged), for: UIControlEvents.valueChanged)
        
        workGoal.inputView = datePickerView
        workGoal.delegate = self
        
        let calendar = Calendar(identifier: .gregorian)
        let date = DateComponents(calendar: calendar, hour: 0, minute: 10).date!
        datePickerView.setDate(date, animated: true)
        
        let width = UIScreen.main.bounds.width
        
        collectionViewHeightConstraint.constant = width / 2
        print(width)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setDateFromSeconds(seconds: Double) -> (Date) {
        let intSeconds = Int(seconds)
        let minutes = (intSeconds / 60) % 60
        let hours = intSeconds / 3600
        let dateString = NSString(format: "%0.2d:%0.2d", hours, minutes)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm"
        return dateFormatter.date(from: dateString as String)!
    }
    
    @objc func datePickerValueChanged(sender:UIDatePicker) {
        print("value changed")
        let ti = NSInteger(sender.countDownDuration)
        
        let minutes = (ti / 60) % 60
        let hours = (ti / 3600)
        
        
        if hours == 0 {
            workGoal.text = String(format: "%i min", minutes)
        } else {
            if hours == 1 {
                workGoal.text = String(format: "%i hour %i min", hours, minutes)
            } else {
                workGoal.text = String(format: "%i hours %i min", hours, minutes)
            }
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            sender.countDownDuration += 0
        }
    }
    
    
    
    // TextField delegate for displaying keyboard and datePickerView
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if textField.placeholder == "Hours work goal" && textField.text == "" {
            textField.text = "10 min"
        }
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let datePickerView = textField.inputView as? UIDatePicker {
                datePickerView.countDownDuration += 0
            }
        }
        return true
    }
    
    // Save button pressed and save to CoreData managed context
    @IBAction func saveButtonPressed(_ sender: Any) {
        
        // Check input integrity
        var integrity = true
        if workGoal.text == "" {
            integrity = false
        }
        if workName.text == "" {
            integrity = false
        }
        var allFalse = true
        for (key, _) in dayNameDict {
            if (dayNameDict[key] ?? false) {
                allFalse = false
            }
        }
        if integrity {
            integrity = !allFalse
        }
        
        if !integrity {
            let alert = UIAlertController(title: "Empty input", message: "Some input fields are empty.", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { action in
                alert.dismiss(animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true, completion: nil)

            return
        }
        
        print("get to after alert")
        // Work name size warning
        
        
        // Save to managed context
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        let managedContext = appDelegate.persistentContainer.viewContext
        var dayObjectList : [Day] = []
        
        let fetchRequest = NSFetchRequest<Day>(entityName: "Day")
        do {
            dayObjectList = try managedContext.fetch(fetchRequest)
        } catch let error as NSError {
            print("Could not fetch. \(error), \(error.userInfo)")
        }
        
        for (key, _) in dayNameDict {
            if key != "All" && dayNameDict[key] == true && integrity {
                let workEntity = NSEntityDescription.entity(forEntityName: "Work", in: managedContext)!
                let work = Work(entity: workEntity, insertInto: managedContext)
                
                
                work.setValue(workName.text ?? "N/A", forKeyPath: "name")
                
                if let datePickerView = self.workGoal.inputView as? UIDatePicker {
                    work.setValue( Float(datePickerView.countDownDuration / 3600.0), forKey: "maxHours")
                    work.setValue( Float(datePickerView.countDownDuration / 3600.0), forKey: "hoursLeft")
                }
                
                
                work.setValue(false, forKey: "isTicking")
                
                for dayObject in dayObjectList {
                    if dayObject.name == key {
                        dayObject.addToGetWork(work)
                    }
                }
            }
        }
        
        do {
            try managedContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
        
        self.navigationController?.popViewController(animated: true)
    }
    
}

extension AddWorkViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dayNameList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "DayCollectionCell", for: indexPath) as! DayCollectionCell
        var imageName = dayNameList[indexPath.row]
        if dayNameDict[dayNameList[indexPath.row]]!  {
            imageName += "Inv"
            cell.backgroundColor = .black
        } else {
            cell.backgroundColor = .white
        }
                
        cell.dayIconImageView.image = UIImage(named: imageName)
        
        return cell
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row == 7 {
            if dayNameDict[dayNameList[indexPath.row]]! {
                for (key, _) in dayNameDict {
                    dayNameDict[key] = false
                }
            } else {
                for (key, _) in dayNameDict {
                    dayNameDict[key] = true
                }
            }
        } else {
            if dayNameDict[dayNameList[indexPath.row]]! {
                dayNameDict[dayNameList[indexPath.row]] = false
                dayNameDict["All"] = false
            } else {
                dayNameDict[dayNameList[indexPath.row]] = true
                
                var all = true
                for dayName in dayNameList {
                    if dayName != "All" && dayNameDict[dayName] == false {
                        all = false
                    }
                }
                if all {
                    dayNameDict["All"] = true
                }
            }
        }
        
        collectionView.reloadData()
        collectionView.scrollToItem(at: indexPath, at: UICollectionViewScrollPosition.centeredHorizontally, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize
    {
        let width = UIScreen.main.bounds.width
        return CGSize(width: width/6, height: width/6)
    }
}

