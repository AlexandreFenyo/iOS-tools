//
//  CTEmailFunctions.swift
//  CTHelp
//
//  Created by Stewart Lynch on 2019-01-17.
//  Copyright © 2019 Stewart Lynch. All rights reserved.
//

import UIKit
import MessageUI

class CTEmailFunctions: NSObject {
    
    static func emailDeveloper(withAddress address: String, withData data:Data?, withStrings ctString: CTString, mailTintColor:UIColor?, from vc:UIViewController) {
        guard let vc = vc as? CTHelpViewController else {return}
        var alert = UIAlertController()
        if let data = data {
            alert = UIAlertController(title: ctString.dataAlertTitle ?? "Attach application data", message: ctString.dataAlertMessage ?? "Would you like to attach your application data to this message to assist the developer in troubleshooting?", preferredStyle: .alert)
            let cancelAction = UIAlertAction(title: ctString.dataAlertActionNo ?? "No", style: .cancel) { (action) in
                self.sendEmail(withAddress:address, withData: nil, withStrings: ctString, mailTintColor: mailTintColor, on: vc)
            }
            let OKAction = UIAlertAction(title: ctString.dataAlertActionYes ?? "Yes", style: .default) { (action) in
                self.sendEmail(withAddress:address, withData: data, withStrings: ctString, mailTintColor: mailTintColor, on: vc)
            }
            alert.addAction(OKAction)
            alert.addAction(cancelAction)
            if let _ = mailTintColor {
                alert.view.tintColor = mailTintColor
            }
            vc.present(alert, animated: true, completion: nil)
        } else {
            self.sendEmail(withAddress:address, withData: nil, withStrings: ctString,mailTintColor: mailTintColor, on: vc)
        }
    }
    
    static func sendEmail(withAddress address: String, withData data:Data?, withStrings ctString: CTString, mailTintColor:UIColor?, on vc:UIViewController) {
        guard let vc = vc as? CTHelpViewController else {return}
        let clientInfo = CTSourceInfo()
        var body:String = "<b>\(clientInfo.appName)</b><p>"
        body += "iOS: \(clientInfo.iOSVersion)</br>"
        body += "Device Version: \(clientInfo.deviceVersion)</br>"
        body += "App Version: \(clientInfo.appVersion)<p>"
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = vc
            // Changes Color of buttons in navBar and on alertButtons
            if let _ = mailTintColor {
                mail.view.tintColor = mailTintColor
            }
            if let data = data {
                body += ctString.emailAttachNote ?? "<b>Note:</b>\(clientInfo.appName) data is attached."
                body += "<p>"
                mail.addAttachmentData(data, mimeType: "text/plain", fileName: "\(clientInfo.appName).json")
            }
            body += ctString.emailBody ?? "Please describe the issue you are having in as much detail as possible:"
            mail.setMessageBody(body, isHTML: true)
            mail.setSubject(ctString.emailSubject ?? "\(clientInfo.appName) Issue")
            mail.setToRecipients([address])
            vc.present(mail, animated: true, completion: nil)
        } else {
            let alertController = UIAlertController(title: "Not Allowed", message:
                "This device cannot currently send email.", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default,handler: nil))
            vc.present(alertController, animated: true, completion: nil)
        }
    }
    
}
