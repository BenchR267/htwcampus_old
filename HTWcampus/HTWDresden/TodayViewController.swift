//
//  TodayViewController.swift
//  HTWDresden
//
//  Created by Benjamin Herzog on 20.08.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

import UIKit
import NotificationCenter
import CoreData

class TodayViewController: UIViewController {
    
    var context: NSManagedObjectContext!
    
    @IBOutlet weak var myLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var storeURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.BenchR.TodayExtensionSharingDefaults")
        storeURL = storeURL?.URLByAppendingPathComponent("HTWcampus.sqlite")
        //        var modelURL = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.BenchR.TodayExtensionSharingDefaults")
        //        modelURL = modelURL?.URLByAppendingPathComponent("HTWcampus.momd")
        var modelURL = NSBundle.mainBundle().URLForResource("HTWcampus", withExtension: "momd")
        let model = NSManagedObjectModel(contentsOfURL: modelURL)
        
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: nil, error: nil)
        context = NSManagedObjectContext()
        context.persistentStoreCoordinator = coordinator
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)!) {
        
        let entitiyDesc = NSEntityDescription.entityForName("User", inManagedObjectContext: context)
        let request = NSFetchRequest(entityName: "User")
//            request.entity = entitiyDesc
        let array = context.executeFetchRequest(request, error: nil)
        let user1 = array[0] as User
        myLabel.text = user1.matrnr
        //        preferredContentSize = CGSize(width: 320, height: 100)
        completionHandler(NCUpdateResult.NewData)
        
    }
    
}
