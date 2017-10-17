//
//  LessonLoader.swift
//  HTWcampus
//
//  Created by Benjamin Herzog on 13.09.17.
//  Copyright © 2017 Benjamin Herzog. All rights reserved.
//

import Foundation
import RxSwift

class LessonLoader: NSObject {
    
    private static let network = Network()
    
    static let disposeBag = DisposeBag()
    
    private static let errorMessage = "Da ist leider etwas schief gelaufen. Wir arbeiten bereits daran!"
    
    private static var currentDataSource: ScheduleDataSource?
    
    @objc class func loadLessons(context: NSManagedObjectContext, key: String, completion: @escaping (String?) -> Void) {
        guard self.currentDataSource == nil else { return }
        
        let components = key.components(separatedBy: "/")
        guard components.count == 3 else {
            return completion("Leider ist nur noch die Eingabe einer Studiengruppe möglich. Bitte nutze das Format Jahr/Studiengang/Gruppe. Folgende Eingabe war nicht korrekt: \(key)")
        }
        
        let year = components[0]
        let gng = components[1]
        let grp = components[2]
        
        
        SemesterInformation.get(network: self.network).subscribe(onNext: { infos in
            
            guard let information = SemesterInformation.information(date: Date(), input: infos) else {
                currentDataSource = nil
                return completion(errorMessage)
            }
            let start = information.period.begin.date
            
            let dataSource = ScheduleDataSource(originDate: start, numberOfDays: 183, auth: ScheduleDataSource.Auth(year: year, major: gng, group: grp))
            dataSource.load { lectures in
                
                guard let lectures = lectures else {
                    currentDataSource = nil
                    return completion(errorMessage)
                }

                let req = NSFetchRequest<User>(entityName: "User")
                req.predicate = NSPredicate(format: "(matrnr = %@)", key)
                if let res = try? context.fetch(req), let existingUser = res.first {
                    context.delete(existingUser)
                    try? context.save()
                }
                
                let newUser = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as! User
                newUser.matrnr = key
                newUser.letzteAktualisierung = Date()
                newUser.raum = false
                
                for (n, e) in lectures.enumerated() {
                    let date = start.addingTimeInterval(TimeInterval(n).days)
                    for l in e {
                        guard let entity = NSEntityDescription.entity(forEntityName: "Stunde", in: context) else {
                            continue
                        }
                        let newStunde = Stunde(entity: entity, insertInto: context)
                        newStunde.anzeigen = true
                        newStunde.dozent = l.professor
                        newStunde.kurzel = l.tag ?? l.name
                        newStunde.raum = l.rooms.first ?? ""
                        newStunde.titel = l.name
						newStunde.type = l.type
                        newStunde.semester = information.semester.description
                        let start = date.addingTimeInterval(TimeInterval(l.begin.hour ?? 0).hours).addingTimeInterval(TimeInterval(l.begin.minute ?? 0).minutes)
                        let end = date.addingTimeInterval(TimeInterval(l.end.hour ?? 0).hours).addingTimeInterval(TimeInterval(l.end.minute ?? 0).minutes)
                        newStunde.anfang = start
                        newStunde.ende = end

                        let zeitAsString = "\(l.begin.hour ?? 0):\(l.begin.minute ?? 0)"
                        
                        newStunde.id = "\(newStunde.kurzel)\(newStunde.anfang.weekday)\(zeitAsString)"
                        
                        newUser.addStundenObject(newStunde)
                    }
                }
                guard let _ = try? context.save() else {
                    currentDataSource = nil
                    return completion(errorMessage)
                }
                currentDataSource = nil
                completion(nil)
            }
            currentDataSource = dataSource
            
        }, onError: { _ in
            completion(errorMessage)
        }).addDisposableTo(self.disposeBag)
    }
    
}
