//
//  MenuItem.swift
//  
//
//  Created by Alexander Zielenski on 10/4/15.
//  Copyright © 2015 CUAppDev. All rights reserved.
//

import UIKit
import SwiftyJSON

public struct MenuItem {
    public let name: String
    public let healthy: Bool
    
    public init(name: String, healthy: Bool) {
        self.name = name
        self.healthy = healthy
    }
    
    internal init(json: JSON) {
        name = json[APIKey.Item.rawValue].stringValue
        healthy = json[APIKey.Healthy.rawValue].boolValue
    }
}