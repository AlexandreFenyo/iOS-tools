//
//  CTString.swift
//  CTHelp
//
//  Created by Stewart Lynch on 2019-05-13.
//

import Foundation

public class CTString {
    internal init(contactButtonTitle: String?, webButtonTitle: String?, dataAlertTitle: String?, dataAlertMessage: String?, dataAlertActionNo: String?, dataAlertActionYes: String?, emailSubject: String?, emailBody: String?, emailAttachNote: String?) {
        self.contactButtonTitle = contactButtonTitle
        self.webButtonTitle = webButtonTitle
        self.dataAlertTitle = dataAlertTitle
        self.dataAlertMessage = dataAlertMessage
        self.dataAlertActionNo = dataAlertActionNo
        self.dataAlertActionYes = dataAlertActionYes
        self.emailSubject = emailSubject
        self.emailBody = emailBody
        self.emailAttachNote = emailAttachNote
    }

    public  var contactButtonTitle:String?
    public  var webButtonTitle:String?
    public var dataAlertTitle:String?
    public var dataAlertMessage:String?
    public var dataAlertActionNo:String?
    public var dataAlertActionYes:String?
    public var emailSubject:String?
    public var emailBody:String?
    public var emailAttachNote:String?
    
    
    
}
