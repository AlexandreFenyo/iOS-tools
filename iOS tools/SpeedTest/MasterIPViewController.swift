//
//  MasterViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 02/07/2018.
//  Copyright © 2018 Alexandre Fenyo. All rights reserved.
//

import UIKit

class DeviceAddress {
    var name : String

    init(name: String) {
        self.name = name
    }
}

class DeviceAddressCell : UITableViewCell {
    init(_ device : DeviceAddress, style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(style: .default, reuseIdentifier: "DeviceAddressCell")
    }
}

// The MasterViewController instance is the delegate for the UITableView
class MasterIPViewController: UITableViewController {

    var device_addresses : [DeviceAddress] = [
        DeviceAddress(name: "127.0.0.1"),
        DeviceAddress(name: "192.168.0.6"),
    ]

    public func applicationWillResignActive() {
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("fin de scroll")
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return device_addresses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device_address = device_addresses[indexPath.item]

        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceAddressCell", for: indexPath) as! DeviceAddressCell
        cell.textLabel!.text = device_address.name

        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        guard let table_section = TableSection(rawValue: indexPath.section), let device_list = devices[table_section]
//            else { fatalError() }
//
//        let device = device_list[indexPath.item]
//        detail_view_controller!.device = device
//
//        // for iPhone, make the detail view controller visible
//        splitViewController?.showDetailViewController(detail_navigation_controller!, sender: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("MasterIPViewController.prepare(for segue)")
    }

}
