//
//  CTHelpView.swift
//  CTHelp
//
//  Created by Stewart Lynch on 11/24/17.
//  Copyright © 2017 CreaTECH Solutiions. All rights reserved.
//

import UIKit


class CTHelpView: UIView {
    @IBOutlet weak var bgView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var helpTextView: UITextView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightConstraint: NSLayoutConstraint!
    @IBOutlet weak var actionButtonTopConstraint: NSLayoutConstraint!
    
    
    var webSite:String?
    var contactEmail:String?
    var data:Data?
    var contactButtonTitle:String?
    var webButtonTitle:String?
    
    @IBOutlet weak var actionBtn: UIButton!
    weak var delegate: CTHelpViewController!

    @IBAction func closeWindowTapped(_ sender: Any) {
        delegate?.dismissVC()
    }
    
    
    func configureView(ctHelpItem:CTHelpItem,bgViewColor:UIColor?,titleColor:UIColor?,helpTextColor:UIColor?,actionButtonBGColor:UIColor?, actionButtonTextColor:UIColor?, ctString:CTString) {
        var imageViewHeightConstraintConstant:CGFloat = 0
        // Set up colors
        if let color = bgViewColor {
            bgView.backgroundColor = color
        }
        if let webButtonTitle = ctString.webButtonTitle {
            self.webButtonTitle = webButtonTitle
        } else {
            self.webButtonTitle = "Visit Web Site"
        }
        
        if let contactButtonTitle = ctString.contactButtonTitle {
            self.contactButtonTitle = contactButtonTitle
        } else {
            self.contactButtonTitle = "Contact Developer"
        }
        
        if let color = titleColor {
            titleLabel.textColor = color
        }
        if let color = helpTextColor {
            helpTextView.textColor = color
        }
        
        if let color = actionButtonBGColor {
            actionBtn.backgroundColor = color
        }
        
        if let color = actionButtonTextColor {
            actionBtn.setTitleColor(color, for: .normal)
        }
        titleLabel.text = ctHelpItem.title
        helpTextView.text = ctHelpItem.helpText
        if let webSite = ctHelpItem.webSite {
            self.webSite = webSite
        }
        if let contactEmail = ctHelpItem.contactEmail {
            self.contactEmail = contactEmail
        }
        if let data = ctHelpItem.data {
            self.data = data
        }
        
        if ctHelpItem.imageName != "" {
            imageView.image = UIImage(named: ctHelpItem.imageName)
            if let height = UIImage(named: ctHelpItem.imageName)?.size.height {
                imageViewHeightConstraintConstant = height
            }
        }
        
        imageHeightConstraint.constant = min(imageViewHeightConstraintConstant, 230.0)
        
        if let btn = ctHelpItem.btn {
            switch btn {
            case .Web:
                actionButtonTopConstraint.constant = 43
                actionBtn.isHidden = false
                actionBtn.setTitle(webButtonTitle, for: .normal)
            case .Email:
                actionButtonTopConstraint.constant = 43
                actionBtn.isHidden = false
                actionBtn.setTitle(contactButtonTitle, for: .normal)
            }
        } else {
            actionButtonTopConstraint.constant = 0
            actionBtn.isHidden = true
        }
        
    }
    
    @IBAction func actionRequest(_ sender: UIButton) {
        if actionBtn.title(for: .normal) == webButtonTitle {
            if let webSite = webSite {
                guard let url = URL(string: webSite) else {return}
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        } else {
            if let contactEmail = contactEmail {
                delegate?.emailDeveloper(withAddress: contactEmail, withData: data)
            }
        }
    }
    
    

    override func awakeFromNib() {
        actionBtn.isHidden = true
        actionButtonTopConstraint.constant = 0
        
    }
}

