//
//  TimerViewController.swift
//  Weekly Work
//
//  Created by James Tran on 10/14/17.
//  Copyright © 2017 James Tran. All rights reserved.
//

import Foundation
import CoreData
import UIKit

class TimerViewController : UIViewController {
    
    @IBOutlet weak var dayImageView: UIImageView!
    @IBOutlet weak var workNameLabel: UILabel!
    @IBOutlet weak var timerLabel : UILabel!
    @IBOutlet weak var timerButton: UIButton!
    var workImported : Work = Work()
    var timer = Timer()
    var isToday : Bool? = nil
    
    @IBOutlet weak var blankImage: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if workImported.isTicking {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(TimerViewController.updateTimerLabel), userInfo: nil, repeats: true)
        }
                
        self.dayImageView.image = UIImage(named: (workImported.getDay?.name)! + "Inv")
        workNameLabel.text = workImported.name ?? "N/A"
        if workImported.isTicking {
            timerButton.setTitle("Stop", for: UIControlState.normal)
        } else {
            timerButton.setTitle("Start", for: UIControlState.normal)
        }
        
        var timeIntervalLeft = Int(workImported.hoursLeft * 3600)
        
        let hours = Int(timeIntervalLeft / 3600)
        timeIntervalLeft -= hours * 3600
        let minutes = Int(timeIntervalLeft / 60)
        timeIntervalLeft -= minutes * 60
        let seconds = timeIntervalLeft
        
        timerLabel.text = String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
        
        let dayNameList = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        let todayIndex = MainViewController().getDayOfWeek()
        if dayNameList[todayIndex] == workImported.getDay?.name {
            isToday = true
        } else {
            isToday = false
        }
    }
    
    @IBAction func timerButtonTouched(_ sender: Any) {
        if !(isToday ?? false) {
            let alert = UIAlertController(title: "Not today", message: "This work is meant for some other day", preferredStyle: UIAlertControllerStyle.alert)
            alert.addAction(UIAlertAction(title: "Okay", style: .default, handler: { action in
                alert.dismiss(animated: true, completion: nil)
            }))
            
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        if workImported.isTicking {
            timer.invalidate()
            
            let elapseTime = -(workImported.startTickingDate?.timeIntervalSinceNow ?? 0)
            let subtractedHours = workImported.hoursLeft - Float(elapseTime / 3600)
            
            if subtractedHours <= 0 {
                workImported.hoursLeft = 0
            } else {
                workImported.hoursLeft = subtractedHours
            }
            
            workImported.startTickingDate = Date(timeIntervalSince1970: 0)
            workImported.isTicking = false
        } else {
            timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(TimerViewController.updateTimerLabel), userInfo: nil, repeats: true)
            workImported.startTickingDate = Date(timeIntervalSinceNow: 0)
            workImported.isTicking = true
        }
        
        if workImported.isTicking {
            timerButton.setTitle("Stop", for: UIControlState.normal)
        } else {
            timerButton.setTitle("Start", for: UIControlState.normal)
            blankImage.stopAnimating()
            blankImage.image = UIImage(named: "Blank")
        }
        
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        do {
            try appDelegate.persistentContainer.viewContext.save()
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    @objc func updateTimerLabel() {
        let elapseTime = -(workImported.startTickingDate?.timeIntervalSinceNow ?? 0)
        let subtractedHours = workImported.hoursLeft - Float(elapseTime / 3600)

        
        var timeIntervalLeft = Int(subtractedHours * 3600)
        
        if timeIntervalLeft <= 0 {
            timeIntervalLeft = 0
        }
        
        let hours = Int(timeIntervalLeft / 3600)
        timeIntervalLeft -= hours * 3600
        let minutes = Int(timeIntervalLeft / 60)
        timeIntervalLeft -= minutes * 60
        let seconds = timeIntervalLeft
        
        // This is for displaying clock animation.
        // Since its a count down from 59 - 00 we need to have 11 - seconds % 2
        blankImage.image = UIImage(named: String(11 - seconds % 12))
        
        timerLabel.text = String(format: "%0.2d:%0.2d:%0.2d", hours, minutes, seconds)
    }
}
