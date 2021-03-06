//
//  Calendars.swift
//  Eatery
//
//  Created by Eric Appel on 5/5/15.
//  Copyright (c) 2015 CUAppDev. All rights reserved.
//

import Foundation
import SwiftyJSON

internal let kFrameworkBundle = NSBundle(identifier: "org.cuappdev.DiningStack")!

/// Hardcoded menus for those which would not normally have them
internal let kEateryGeneralMenus = JSON(data: NSData(contentsOfURL: kFrameworkBundle.URLForResource("hardcodedMenus", withExtension: "json")!) ?? NSData()).dictionaryValue