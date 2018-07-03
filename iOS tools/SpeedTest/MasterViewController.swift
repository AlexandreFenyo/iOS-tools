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

class MasterViewController: UITableViewController {
    enum TableSection: Int {
        case iOSDevice = 0, localGateway, chargenDevice, discardDevice, END
    }

    let section_header_height: CGFloat = 25

    var detail_view_controller : DetailViewController?
    var detail_navigation_controller : UINavigationController?
    var split_view_controller : SplitViewController?

    var devices : [TableSection: [Device]] = [
        .iOSDevice: [Device(name: "iOS device 1"), Device(name: "iOS device 2")],
        .localGateway: [Device(name: "Local gateway")],
        .chargenDevice: [Device(name: "chargen device 1")],
        .discardDevice: []
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return section_header_height
        
//        // First check if there is a valid section of table.
//        // Then we check that for the section there is more than 1 row.
//        if let tableSection = TableSection(rawValue: section), let movieData = data[tableSection], movieData.count > 0 {
//            return SectionHeaderHeight
//        }
//        return 0
    }
    
    //        case iOSDevice = 0, localGateway, chargenDevice, discardDevice, END


    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: section_header_height))
        view.backgroundColor = UIColor(red: 253.0/255.0, green: 240.0/255.0, blue: 196.0/255.0, alpha: 1)
        let label = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.bounds.width - 30, height: section_header_height))
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.black
        if let tableSection = TableSection(rawValue: section) {
            switch tableSection {
            case .iOSDevice:
                label.text = "iOS device"
            case .localGateway:
                label.text = "local gateway"
            case .chargenDevice:
                label.text = "chargen service"
            case .discardDevice:
                label.text = "discard service"
            default:
                label.text = "default"
            }
        }
        view.addSubview(label)
        return view
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let table_section = TableSection(rawValue: indexPath.section), let device_list = devices[table_section]
        else { fatalError() }

        let device = device_list[indexPath.item]

        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceCell
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

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

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
