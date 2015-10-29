//
//  Calendars.swift
//  Eatery
//
//  Created by Eric Appel on 5/5/15.
//  Copyright (c) 2015 CUAppDev. All rights reserved.
//

import Foundation
import SwiftyJSON

internal let kMenuNotAvailable = "Menu not available."
internal let kGeneralMealTypeName = "Menu"
internal let kMenuCategoryName = "General"

internal let kFrameworkBundle = NSBundle(identifier: "org.cuappdev.DiningStack")!

internal let kEateryGeneralMenus = JSON(data: NSData(contentsOfURL: kFrameworkBundle.URLForResource("hardcodedMenus", withExtension: "json")!) ?? NSData()).dictionaryValue