//
//  MasterViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 02/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

// https://www.raywenderlich.com/173753/uisplitviewcontroller-tutorial-getting-started-2
// https://medium.com/swift-programming/swift-enums-and-uitableview-sections-1806b74b8138
// http://theapplady.net/how-to-use-the-ios-8-split-view-controller-part-3/
// https://developer.apple.com/library/archive/documentation/WindowsViews/Conceptual/ViewPG_iPhoneOS/WindowsandViews/WindowsandViews.html
// https://cocoacasts.com/how-to-add-pull-to-refresh-to-a-table-view-or-collection-view

import UIKit

class Device {
    var name : String
    
    init(name: String) {
        self.name = name
    }
}

class DeviceCell : UITableViewCell {
    init(_ device : Device, style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(style: .default, reuseIdentifier: "DeviceCell")
    }
}

// The MasterViewController instance is the delegate for the UITableView
class MasterViewController: UITableViewController {
    enum TableSection: Int {
        case iOSDevice = 0, chargenDevice, discardDevice, localGateway, internet, END
    }

    public var detail_view_controller : DetailViewController?
    public var detail_navigation_controller : UINavigationController?
    public var split_view_controller : SplitViewController?

    var devices : [TableSection: [Device]] = [
        .iOSDevice: [
            Device(name: "iOS device 1"), Device(name: "iOS device 2")
        ],
        .chargenDevice: [Device(name: "chargen device 1")],
        .discardDevice: [],
        .localGateway: [Device(name: "Local gateway")],
        .internet: [
            Device(name: "IPv4 Internet"), Device(name: "IPv6 Internet")
        ]
    ]

    var r : UIRefreshControl?

    override func viewDidLoad() {
        super.viewDidLoad()
        r = UIRefreshControl()
        refreshControl = r
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("fin de scroll")
        return
    }

    // MARK: - Table view headers

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // A section must cover the refresh control if we do not want this control to appear over a row when refreshing, so the section height must be greater or equal to the refresh control height
        return refreshControl!.frame.height
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var retval : String?
        if let tableSection = TableSection(rawValue: section) {
            switch tableSection {
            case .iOSDevice:
                retval = "iOS device"
            case .localGateway:
                retval = "Local gateway"
            case .chargenDevice:
                retval = "Chargen service"
            case .discardDevice:
                retval = "Discard service"
            case .internet:
                retval = "Internet"
            default:
                retval = "Default"
            }
        }
        return retval
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.backgroundView?.backgroundColor = UIColor(red: 253.0/255.0, green: 240.0/255.0, blue: 196.0/255.0, alpha: 1)
        header.textLabel?.textColor = .black
        header.textLabel?.font = UIFont(name: "Helvetica-Bold", size: 19)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return TableSection.END.rawValue
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Swift's optional lookup, instead of devices[TableSection(rawValue: section)!]!.count
        if let table_section = TableSection(rawValue: section), let device_list = devices[table_section] {
            return device_list.count
        }
        return 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let table_section = TableSection(rawValue: indexPath.section), let device_list = devices[table_section]
        else { fatalError() }

        let device = device_list[indexPath.item]

        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceCell
        // Save a ref to the device in the cell
        // cell.device = device
        cell.textLabel!.text = device.name

        return cell
    }

    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let table_section = TableSection(rawValue: indexPath.section), let device_list = devices[table_section]
        else { fatalError() }

        let device = device_list[indexPath.item]
        detail_view_controller!.device = device
        
        // for iPhone, make the detail view controller visible
        splitViewController?.showDetailViewController(detail_navigation_controller!, sender: nil)
    }
}
