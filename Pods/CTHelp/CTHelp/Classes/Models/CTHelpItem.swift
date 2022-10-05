//
//  HelpItem.swift
//  CTHelp
//
//  Created by Stewart Lynch on 2019-01-16.
//  Copyright © 2019 Stewart Lynch. All rights reserved.
//

import Foundation

public struct CTHelpItem {
    let title: String
    let helpText: String
    let imageName:String
    
    let companyName:String?
    let contactEmail: String?
    let webSite: String?
    let data:Data?
    let btn:CTButtonType?
    
  public  init (title:String, helpText:String, imageName:String, btn:CTButtonType? = nil, companyName:String? = nil, contactEmail:String? = nil, data:Data? = nil, webSite:String? = nil) {
        self.title = title
        self.helpText = helpText
        self.imageName = imageName
        self.companyName = companyName
        self.contactEmail = contactEmail
        self.data = data
        self.webSite = webSite
        self.btn = btn
    }
}
