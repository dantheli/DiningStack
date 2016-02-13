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

/**
 Assorted types of payment accepted by an Eatery
 
 - BRB:         Big Red Bucks
 - Swipes:      Meal Swipes
 - Cash:        USD
 - CornellCard: CornellCard
 - CreditCard:  Major Credit Cards
 - NFC:         Mobile Payments
 - Other:       Unknown
 */
public enum PaymentType: String {
    case BRB         = "Meal Plan - Debit"
    case Swipes      = "Meal Plan - Swipe"
    case Cash        = "Cash"
    case CornellCard = "Cornell Card"
    case CreditCard  = "Major Credit Cards"
    case NFC         = "Mobile Payments"
    case Other       = ""
}

/**
 Represents a location on Cornell Campus
 
 - Unknown: Unknown
 - West:    West Campus
 - North:   North Campus
 - Central: Central Campus
 */
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

/// Represents a Cornell Dining Facility and information about it
/// such as open times, menus, location, etc.
public class Eatery: NSObject {
    private static let dateFormatter = makeFormatter()

    /// Unique Identifier
    public let id: Int
    
    /// Human Readable name
    public let name: String
    
    /// Unique internal name
    public let slug: String
    
    /// Short description
    public let about: String // actually "aboutshort"
    
    /// String representation of the phone number
    public let phone: String
    
    /// General location on Campus
    public let area: Area
    
    /// Exact Address
    public let address: String

    /// Acceptable types of payment
    public let paymentMethods: [PaymentType]
    
    /// A constant hardcoded menu if this Eatery has one.
    /// You should be using this menu for all events if it exists
    public let hardcodedMenu: [String: [MenuItem]]?
    
    /// GPS Location
    let location: CLLocation
    
    // Maps 2015-03-01 to [Event]
    // Thought about using just an array, but
    // for many events, this is much faster for lookups
    /// List of all events for this eatery
    /// Maps the date the event occurs to a list of the event name
    /// to the event itself e.g.:
    /// [ "2015-03-01": ["Lunch": Event]]
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
        
        //TODO: make the below line safe
        area     = Area(rawValue: json[APIKey.CampusArea.rawValue][APIKey.ShortDescription.rawValue].stringValue)!
        address  = json[APIKey.Address.rawValue].stringValue
        location = CLLocation(latitude: json[APIKey.Latitude.rawValue].doubleValue, longitude: json[APIKey.Longitude.rawValue].doubleValue)
        
        paymentMethods = json[APIKey.Payment.rawValue].arrayValue.map({ (j) in
            return PaymentType(rawValue: j[APIKey.ShortDescription.rawValue].stringValue) ?? PaymentType.Other
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
    
    /**
    Tells if this Eatery is open at a specific time
    
    - parameter date: Specifically the time to check for
    
    - returns: true if this eatery has an event active at the given date and time
     
    - see: `isOpenForDate`
    */
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
    
    //
    /**
    Tells if eatery is open within the calendar date given. This is distinct from `isOpenOnDate` in that it does not check a specific time, just the day, month, and year.
    
    - parameter date: The date to check
    
    - returns: true of there is an event active at some point within the given calendar day
    
    - see: `isOpenOnDate`
    */
    public func isOpenForDate(date: NSDate) -> Bool {
        let events = eventsOnDate(date)
        return events.count != 0
    }
    
    /**
    Is the eatery open now?
    
    - returns: true if the eatery is open at the present date and time
    */
    public func isOpenNow() -> Bool {
        return isOpenOnDate(NSDate())
    }
    
    /**
    Tells if eatery is open at some point today
     
    - returns: true if the eatery will be open at some point today or was already open
    */
    public func isOpenToday() -> Bool {
        return isOpenForDate(NSDate())
    }
    
    /**
    Retrieve event instances for a specific day
    
    - parameter date: The date for which you would like a list of events for
    
    - returns: A mapping from Event Name to Event for the given day.
    */
    public func eventsOnDate(date: NSDate) -> [String: Event] {
        let dateString = Eatery.dateFormatter.stringFromDate(date)
        return events[dateString] ?? [:]
    }

    /**
    Retrieve the currently active event or the next event for a day/time
    
    - parameter date: The date you would like the active event for
    
    - returns: The active event on a certain day/time, or nil if there was none.
     For our purposes, "active" means currently running or will run soon. As in, if there
     was no event running at exactly the date given but there will be one 15 minutes afterwards, that event would be returned. If the next event was over a day away, nil would be returned.
    */
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
