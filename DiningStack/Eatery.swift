//
//  Eatery.swift
//  Eatery
//
//  Created by Alexander Zielenski on 10/4/15.
//  Copyright © 2015 CUAppDev. All rights reserved.
//

import UIKit
import SwiftyJSON
import CoreLocation

public enum PaymentType: String {
    case BRB         = "Meal Plan - Debit"
    case Swipes      = "Meal Plan - Swipe"
    case Cash        = "Cash"
    case CornellCard = "Cornell Card"
    case CreditCard  = "Major Credit Cards"
    case NFC         = "Mobile Payments"
    case Other       = ""
}

public enum Area: String {
    case Unknown = ""
    case West    = "West"
    case North   = "North"
    case Central = "Central"
}

private func makeFormatter () -> NSDateFormatter {
    let formatter = NSDateFormatter()
    formatter.dateFormat = "YYYY-MM-dd"
    return formatter
}

public class Eatery: NSObject {
    private static let dateFormatter = makeFormatter()

    public let id: Int
    public let name: String
    public let slug: String
    public let about: String // actually "aboutshort"
    public let phone: String
    public let area: Area
    public let address: String
    public let image: UIImage?
    public let photo: UIImage?
    public let paymentMethods: [PaymentType]
    
    public let hardcodedMenu: [String: [MenuItem]]?
    
    let location: CLLocation
    
    var favorite = false
    
    // Maps 2015-03-01 to [Event]
    // Thought about using just an array, but
    // for many events, this is much faster for lookups
    private(set) var events: [String: [String: Event]] = [:]
    
    // Gives a string full of all the menus for this eatery today
    // this is used for searching.
    private var _todaysEventsString: String? = nil
    override public var description: String {
        get {
            if let _todaysEventsString = _todaysEventsString {
                return _todaysEventsString
            }
            let ar = Array(eventsOnDate(NSDate()).values)
            let strings = ar.map { (ev: Event) -> String in
                ev.menu.description
            }
            
            _todaysEventsString = strings.joinWithSeparator("\n")
            return _todaysEventsString!
        }
    }
    
    internal init(json: JSON) {
        id    = json[APIKey.Identifier.rawValue].intValue
        name  = json[APIKey.Name.rawValue].stringValue
        slug  = json[APIKey.Slug.rawValue].stringValue
        about = json[APIKey.AboutShort.rawValue].stringValue
        phone = json[APIKey.PhoneNumber.rawValue].stringValue
        image = UIImage(named: slug + "+logo.jpg", inBundle: kFrameworkBundle, compatibleWithTraitCollection: nil)
        photo = UIImage(named: slug + ".jpg", inBundle: kFrameworkBundle, compatibleWithTraitCollection: nil)
        
        //TODO: make the below line safe
        area     = Area(rawValue: json[APIKey.CampusArea.rawValue][APIKey.ShortDescription.rawValue].stringValue)!
        address  = json[APIKey.Address.rawValue].stringValue
        location = CLLocation(latitude: json[APIKey.Latitude.rawValue].doubleValue, longitude: json[APIKey.Longitude.rawValue].doubleValue)
        
        paymentMethods = json[APIKey.Payment.rawValue].arrayValue.map({ (j) in
            return PaymentType(rawValue: j.stringValue) ?? PaymentType.Other
        })
        
        if let d = kEateryGeneralMenus[slug] {
            hardcodedMenu = Event.menuFromJSON(d)
        } else {
            hardcodedMenu = nil
        }
        
        let hoursJSON = json[APIKey.Hours.rawValue]
        
        for (_, hour) in hoursJSON {
            let eventsJSON = hour[APIKey.Events.rawValue]
            let key        = hour[APIKey.Date.rawValue].stringValue
            
            var currentEvents: [String: Event] = [:]
            for (_, eventJSON) in eventsJSON {
                let event = Event(json: eventJSON)
                currentEvents[event.desc] = event
            }
            
            events[key] = currentEvents
        }
        
        // there is an array called diningItems in it
        
    }
    
    // Tells if open at a specific time
    // Where onDate means including time
    public func isOpenOnDate(date: NSDate) -> Bool {
        let yesterday = NSDate(timeInterval: -1 * 24 * 60 * 60, sinceDate: date)
        
        for now in [date, yesterday] {
            let events = eventsOnDate(now)
            for (_, event) in events {
                if event.occurringOnDate(date) {
                    return true
                }
            }
        }
        
        return false
    }
    
    // Tells if eatery is open within the calendary date given
    public func isOpenForDate(date: NSDate) -> Bool {
        let events = eventsOnDate(date)
        return events.count != 0
    }
    
    // Tells if eatery is open now
    public func isOpenNow() -> Bool {
        return isOpenOnDate(NSDate())
    }
    
    // Tells if eatery is open at some point today
    public func isOpenToday() -> Bool {
        return isOpenForDate(NSDate())
    }
    
    // Retrieves event instances for a specific day
    public func eventsOnDate(date: NSDate) -> [String: Event] {
        let dateString = Eatery.dateFormatter.stringFromDate(date)
        return events[dateString] ?? [:]
    }

    // Retrieves the currently active event or the next event for a day/time
    public func activeEventForDate(date: NSDate) -> Event? {
        let tomorrow = NSDate(timeInterval: 24 * 60 * 60, sinceDate: date)
        
        var timeDifference = DBL_MAX
        var next: Event? = nil
                
        for now in [date, tomorrow] {
            let events = eventsOnDate(now)
            
            for (_, event) in events {
                let diff = event.startDate.timeIntervalSince1970 - date.timeIntervalSince1970
                if event.occurringOnDate(date) {
                    return event
                } else if diff < timeDifference && diff > 0 {
                    timeDifference = diff
                    next = event
                }
            }
        }
        
        return next
    }
    
 }
