//
//  CTHelpViewController.swift
//  CreaTECH Help
//
//  Created by Stewart Lynch on 1/16/19.
//  Copyright © 2019 Stewart Lynch. All rights reserved.
//

import UIKit
import WebKit
import MessageUI


public class CTHelpViewController: UIViewController,UIScrollViewDelegate,MFMailComposeViewControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var ctHelpPageControl: UIPageControl!
    var mailTintColor:UIColor?
    var bgViewColor:UIColor?
    var helpTextColor:UIColor?
    var titleColor:UIColor?
    var actionButtonBGColor:UIColor?
    var actionButtonTextColor:UIColor?
    var ctString:CTString!
    
    var address:String!
    var ctHelpItem:[CTHelpItem] = []
    
    override public func viewDidLoad() {

        super.viewDidLoad()
        setupScrollView()
        loadCTHelp()
    }
    
    override public func viewDidDisappear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        scrollView.contentSize = CGSize(width: size.width * CGFloat(ctHelpItem.count), height: 315)
        scrollView.contentOffset.x = size.width * CGFloat(ctHelpPageControl.currentPage)
    }
    
    public func setupScrollView() {
        scrollView.isPagingEnabled = true
        scrollView.contentSize = CGSize(width: self.view.bounds.width * CGFloat(ctHelpItem.count), height: 315)
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        ctHelpPageControl.numberOfPages = ctHelpItem.count
        ctHelpPageControl.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    }
    
    public func loadCTHelp() {
        for (index,ctHelpItem) in ctHelpItem.enumerated() {
			let podBundle = Bundle(for: CTHelpViewController.self)
			let bundleURL = podBundle.url(forResource: "CTHelp", withExtension: "bundle")
			let bundle = Bundle(url: bundleURL!)!
            guard let ctHelpView = bundle.loadNibNamed("CTHelp", owner: self, options: nil)?.first as? CTHelpView else {return}
            ctHelpView.delegate = self
            ctHelpView.configureView(ctHelpItem: ctHelpItem,
                                     bgViewColor: bgViewColor,
                                     titleColor: titleColor,
                                     helpTextColor: helpTextColor,
                                     actionButtonBGColor: actionButtonBGColor,
                                     actionButtonTextColor: actionButtonTextColor,
                                     ctString:ctString
            )
            scrollView.addSubview(ctHelpView)
            ctHelpView.frame.size.width = self.view.bounds.size.width
            ctHelpView.frame.origin.x = CGFloat(index) * self.view.bounds.size.width
            ctHelpView.autoresizingMask = [.flexibleRightMargin, .flexibleLeftMargin, .flexibleWidth]
        }
    }
    
   public  func dismissVC() {
        dismiss(animated: true, completion: nil)
    }
    
   public func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
   public func emailDeveloper(withAddress emailAddress:String, withData data:Data?) {
        CTEmailFunctions.emailDeveloper(withAddress:emailAddress, withData: data,withStrings: ctString, mailTintColor: mailTintColor, from: self)
    }
    
   public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page = scrollView.contentOffset.x / scrollView.frame.size.width
        ctHelpPageControl.currentPage = Int(page)
    }
    
    @IBAction public func moveViewLeftRight(_ sender: UIPageControl) {
        let page = sender.currentPage
        var frame:CGRect = self.scrollView.frame
        frame.origin.x = frame.size.width * CGFloat(page)
        frame.origin.y = 0
        self.scrollView.scrollRectToVisible(frame, animated: true)
    }
    
    
}
