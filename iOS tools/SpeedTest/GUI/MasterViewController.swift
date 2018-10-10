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

// let frame = navigationController!.navigationBar.frame
// tableView.setContentOffset(CGPoint(x: 0, y: -(frame.height + frame.origin.y + refreshControl!.frame.size.height)), animated: true)
// tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
// tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: true)

import UIKit

class Device {
    public var name : String
    public var addresses : [IPAddress] = []
    
    public init(name: String, addresses: [IPAddress]) {
        self.name = name
        self.addresses = addresses
    }

    public convenience init(name: String) {
        self.init(name: name, addresses: [])
    }
}

// MasterViewController is a DeviceManager
protocol DeviceManager {
    func addDevice(name: String, addresses: [IPAddress])
}

class DeviceCell : UITableViewCell {

//    init(_ device : Device, style: UITableViewCellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//    }
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(style: .default, reuseIdentifier: "DeviceCell")
//    }
}

// The MasterViewController instance is the delegate for the UITableView
class MasterViewController: UITableViewController, DeviceManager {
    @IBOutlet weak var update_button: UIBarButtonItem!
    @IBOutlet weak var stop_button: UIBarButtonItem!
    @IBOutlet weak var add_button: UIBarButtonItem!

    enum TableSection: Int {
        case iOSDevice = 0, chargenDevice, discardDevice, localGateway, internet, END
    }

    public var detail_view_controller : DetailViewController?
    public var detail_navigation_controller : UINavigationController?
    public var split_view_controller : SplitViewController?
    public weak var browser_chargen : ServiceBrowser?
    public weak var browser_discard : ServiceBrowser?

    var devices : [TableSection: [Device]] = [
        .iOSDevice: [
            Device(name: "iOS device 1", addresses: [IPv4Address("1.2.3.4")!, IPv4Address("1.2.3.5")!]),
            Device(name: "iOS device 2")
        ],
        .chargenDevice: [Device(name: "chargen device 1")],
        .discardDevice: [],
        .localGateway: [Device(name: "Local gateway")],
        .internet: [
            Device(name: "IPv4 Internet"), Device(name: "IPv6 Internet")
        ]
    ]

    private func startBrowsing() {
        Timer.scheduledTimer(withTimeInterval: TimeInterval(0.5), repeats: false) {
        _ in
        self.stop_button!.isEnabled = true
        self.add_button!.isEnabled = false
        self.update_button!.isEnabled = false
        self.browser_chargen?.search()
        self.browser_discard?.search()
      }
    }

    private func stopBrowsing() {
        refreshControl!.endRefreshing()
        stop_button!.isEnabled = false
        add_button!.isEnabled = true
        update_button!.isEnabled = true

        browser_discard?.stop()
        browser_chargen?.stop()
    }

    @IBAction func stop_pressed(_ sender: Any) {
        stopBrowsing()
        // Scroll to top - will call scrollViewDidEndScrollingAnimation when finished
        tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: true)
    }

    @IBAction func update_pressed(_ sender: Any) {
        refreshControl!.beginRefreshing()
//        tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: true)
        tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
        stop_button!.isEnabled = false
        add_button!.isEnabled = false
        update_button!.isEnabled = false
        startBrowsing()
    }

    @IBAction func debug_pressed(_ sender: Any) {
        print("debug pressed")
//        addDevice("test")

//print(traitCollection.horizontalSizeClass.rawValue)
    }

    // Refresh started with gesture
    @objc
    private func userRefresh(_ sender: Any) {
        stop_button!.isEnabled = false
        add_button!.isEnabled = false
        update_button!.isEnabled = false
        startBrowsing()
    }

    public func applicationWillResignActive() {
        stopBrowsing()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Display an Edit button in the navigation bar for this view controller.
        navigationItem.rightBarButtonItem = editButtonItem

        // Add a refresh control
        refreshControl = UIRefreshControl()
        // Call userRefresh() when refreshing with gesture
        refreshControl!.addTarget(self, action: #selector(userRefresh(_:)), for: .valueChanged)

        // Prepare the section headers
        let nib = UINib(nibName: "MasterSectionHeader", bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: "MasterSectionHeader")
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        // Here, we use NSFetchedResultsController
        // And we simply use the section name as title
//        let currSection = fetchedResultsController.sections?[section]
//        let title = currSection!.name
        
        // Dequeue with the reuse identifier
        let cell = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "MasterSectionHeader")
        let header = cell as! MasterSectionHeader
        
        if let tableSection = TableSection(rawValue: section) {
            switch tableSection {
            case .iOSDevice:
                header.titleLabel.text = "iOS devices"
                header.subTitleLabel.text = "other devices running this app"
                header.imageView.image = UIImage(named: "netmon7")
            case .localGateway:
                header.titleLabel.text = "Local gateway"
                header.subTitleLabel.text = "other devices running this app"
            case .chargenDevice:
                header.titleLabel.text = "Chargen service"
                header.subTitleLabel.text = "other devices running this app"
            case .discardDevice:
                header.titleLabel.text = "Discard service"
                header.subTitleLabel.text = "other devices running this app"
            case .internet:
                header.titleLabel.text = "Internet"
                header.subTitleLabel.text = "other devices running this app"
            default:
                header.titleLabel.text = "Default"
                header.subTitleLabel.text = "Default"
            }
        }

        return cell
    }
    
    // Disable other actions while editing
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            refreshControl!.endRefreshing()
            stop_button!.isEnabled = false
            add_button!.isEnabled = false
            update_button!.isEnabled = false
        } else {
            refreshControl!.endRefreshing()
            stop_button!.isEnabled = false
            add_button!.isEnabled = true
            update_button!.isEnabled = true
        }
    }

    // Called by MasterIPViewController when an address is selected
    public func addressSelected(address: IPAddress) {
        print(address.toNumericString(), "selected")
        detail_view_controller!.address = address
    }

    // Called by MasterIPViewController when an address is deselected and no other address is selected
    public func addressDeselected() {
        print("address deselected")
        detail_view_controller!.address = nil
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - DeviceManager protocol

    private var c : Int = 0
    public func addDevice(name: String, addresses: [IPAddress]) {
        c = c + 1
        devices[.iOSDevice]!.append(Device(name: name, addresses: addresses))
        tableView.insertRows(at: [IndexPath(row: devices[.iOSDevice]!.count - 1, section: TableSection.iOSDevice.rawValue)], with: .automatic)

        // Very important call: without it, the refresh control may not be displayed in some situations (few rows when a device is added)
        tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("fin de scroll")
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

//    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        let header = view as! UITableViewHeaderFooterView
//        header.backgroundView?.backgroundColor = UIColor(red: 253.0/255.0, green: 240.0/255.0, blue: 196.0/255.0, alpha: 1)
//        header.textLabel?.textColor = .black
//        header.textLabel?.font = UIFont(name: "Helvetica-Bold", size: 19)
//    }

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
        cell.textLabel!.text = device.name
        print("XXXXX cell.lab.text")
//        cell.lab.text = "SALUT"

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let table_section = TableSection(rawValue: indexPath.section), let device_list = devices[table_section]
        else { fatalError() }

        stopBrowsing()
        let device = device_list[indexPath.item]
        detail_view_controller!.device = device
        
        // for iPhone, make the detail view controller visible
        splitViewController?.showDetailViewController(detail_navigation_controller!, sender: nil)
    }

    // Local gateway and Internet rows can not be removed
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != TableSection.localGateway.rawValue && indexPath.section != TableSection.internet.rawValue
    }

    // Delete a row
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { fatalError("editingStyle invalid") }
        devices[TableSection.init(rawValue: indexPath.section)!]!.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let master_ip_view_controller = segue.destination as? MasterIPViewController,
            let index_path = tableView.indexPathForSelectedRow,
            let table_section = TableSection(rawValue: index_path.section),
            let device_list = devices[table_section]
        else { fatalError() }
        let device = device_list[index_path.item]
        master_ip_view_controller.device = device
        master_ip_view_controller.master_view_controller = self
        if !device.addresses.isEmpty {
            let indexPath = IndexPath(row: 0, section: 0), table_view = master_ip_view_controller.tableView!
            table_view.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
            table_view.cellForRow(at: indexPath)!.setHighlighted(true, animated: true)
            addressSelected(address: device.addresses.first!)
        }
    }

}
