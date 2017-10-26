//
//  ScheduleDataSource.swift
//  HTWDD
//
//  Created by Benjamin Herzog on 03/03/2017.
//  Copyright © 2017 HTW Dresden. All rights reserved.
//

import UIKit
import RxSwift

class ScheduleDataSource {

    struct Auth {
        let year: String
        let major: String
        let group: String
    }

    var originDate: Date {
        didSet {
            self.data = self.calculate()
        }
    }
    var numberOfDays: Int {
        didSet {
            self.data = self.calculate()
        }
    }
    var auth: Auth {
        didSet {
            self.data = self.calculate()
        }
    }

    private let days = ["Montag", "Dienstag", "Mittwoch", "Donnerstag", "Loca.friday", "Loca.saturday", "Loca.sunday"]

    private(set) var lectures = [Day: [Lecture]]()
    private var semesterInformations = [SemesterInformation]() {
        didSet {
            self.semesterInformation = SemesterInformation.information(date: self.originDate, input: self.semesterInformations)
        }
    }
    private var semesterInformation: SemesterInformation?

    private var data = [[Lecture]]()

    private let disposeBag = DisposeBag()
    private let network = Network()

    init(originDate: Date, numberOfDays: Int, auth: Auth) {
        self.originDate = originDate
        self.numberOfDays = numberOfDays
        self.auth = auth
    }

    func load(completion: @escaping ([[Lecture]]?) -> Void) {
        let lecturesObservable = Lecture.get(network: self.network, year: self.auth.year, major: self.auth.major, group: self.auth.group)
            .map(Lecture.groupByDay)

        let informationObservable = SemesterInformation.get(network: self.network)

        Observable.combineLatest(lecturesObservable, informationObservable) { ($0, $1) }
                  .observeOn(MainScheduler.instance)
            .subscribe { [weak self] (event) in
                guard case let .next((lectures, information)) = event else {
                    if case .error(_) = event {
                        completion(nil)
                    }
                    return
                }

                self?.lectures = lectures
                self?.semesterInformations = information
                self?.data = self?.calculate() ?? []
                guard let `self` = self else { return completion(nil) }
                completion(self.data)
        }.addDisposableTo(self.disposeBag)
    }

    func lecture(at indexPath: IndexPath) -> Lecture? {
        return self.data[indexPath.section][indexPath.row]
    }

    func dayName(indexPath: IndexPath) -> String {
        let index = (self.originDate.weekday.rawValue + indexPath.section) % self.days.count
        return self.days[index]
    }

    private func calculate() -> [[Lecture]] {
        guard let semesterInformation = self.semesterInformation, !self.lectures.isEmpty else {
            return []
        }

        let sections = 0..<self.numberOfDays
        let originDay = self.originDate.weekday
        let startWeek = self.originDate.weekNumber

        let a: [[Lecture]] = sections.map { section in
            let date = self.originDate.byAdding(days: TimeInterval(section + 1))

            guard semesterInformation.lecturesContains(date: date) else {
                return []
            }

            guard !semesterInformation.freeDaysContains(date: date) else {
                return []
            }

            let weekNumber = originDay.weekNumber(starting: startWeek, addingDays: section)
            return (self.lectures[originDay.dayByAdding(days: section)] ?? []).filter { lecture in
                let weekEvenOddValidation = lecture.week.validate(weekNumber: weekNumber)
                let weekOnlyValidation = lecture.weeks?.contains(weekNumber) ?? true
                return weekEvenOddValidation && weekOnlyValidation
            }
        }
        return a
    }

}
