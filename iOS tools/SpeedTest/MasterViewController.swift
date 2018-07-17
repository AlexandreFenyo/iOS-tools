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
    // weak var device : Device?
    
    init(_ device : Device, style: UITableViewCellStyle, reuseIdentifier: String?) {
        // self.device = device
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        // self.device = nil
        super.init(style: .default, reuseIdentifier: "DeviceCell")
    }
}

// The MasterViewController instance is the delegate for the UITableView
class MasterViewController: UITableViewController {
    @IBOutlet weak var update_button: UIBarButtonItem!
    @IBOutlet weak var stop_button: UIBarButtonItem!
    @IBOutlet weak var add_button: UIBarButtonItem!

    enum TableSection: Int {
        case iOSDevice = 0, chargenDevice, discardDevice, localGateway, internet, END
    }

    var detail_view_controller : DetailViewController?
    var detail_navigation_controller : UINavigationController?
    var split_view_controller : SplitViewController?
    
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

    @IBAction func update_pressed(_ sender: Any) {
        let frame = navigationController!.navigationBar.frame
        tableView.setContentOffset(CGPoint(x: 0, y: -(frame.height + frame.origin.y + refreshControl!.frame.size.height)), animated: true)

        refreshControl!.beginRefreshing()
        userRefresh(self)
    }

    @IBAction func stop_pressed(_ sender: Any) {
        refreshControl!.endRefreshing()
        stop_button!.isEnabled = false
        update_button!.isEnabled = true
        add_button!.isEnabled = true

        // Scroll to top
        tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: true)
    }

    @IBAction func debug_pressed(_ sender: Any) {
        print("debug pressed")
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
    }
    
    @objc
    private func userRefresh(_ sender: Any) {
        update_button!.isEnabled = false
        stop_button!.isEnabled = true
        add_button!.isEnabled = false

//        devices[.iOSDevice]!.append(Device(name: "salut"))
//        tableView.reloadData()
    }

    // Disable other actions while editing
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        if editing {
            refreshControl!.endRefreshing()
            stop_button!.isEnabled = false
            update_button!.isEnabled = false
            add_button!.isEnabled = false
        } else {
            refreshControl!.endRefreshing()
            stop_button!.isEnabled = false
            update_button!.isEnabled = true
            add_button!.isEnabled = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
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

    //    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    //        print("SALUT")
    //        return []
    //    }

    // Useful when not using tableView(...titleForHeaderInSection...) but directly building a UIView
//    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: section_header_height))
//        view.backgroundColor = UIColor(red: 253.0/255.0, green: 240.0/255.0, blue: 196.0/255.0, alpha: 1)
//        let label = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.bounds.width - 30, height: section_header_height))
//        label.font = UIFont.boldSystemFont(ofSize: 30)
//        label.textColor = UIColor.black
//        if let tableSection = TableSection(rawValue: section) {
//            switch tableSection {
//            case .iOSDevice:
//                label.text = "iOS device"
//            case .localGateway:
//                label.text = "local gateway"
//            case .chargenDevice:
//                label.text = "chargen service"
//            case .discardDevice:
//                label.text = "discard service"
//            default:
//                label.text = "default"
//            }
//        }
//        view.addSubview(label)
//        return view
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

    // Local gateway can not be removed
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section != TableSection.localGateway.rawValue && indexPath.section != TableSection.internet.rawValue
    }

    // Delete a row
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { fatalError("editingStyle invalid") }
        devices[TableSection.init(rawValue: indexPath.section)!]!.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("MasterViewController.prepare(for segue)")
    }

}
