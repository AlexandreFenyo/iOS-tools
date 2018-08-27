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
    public var master_view_controller : MasterViewController?
    public var device : Device?

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

    // Since we highlight the default selected row in MasterViewController.prepare(), we need to unhighlight this row when another cell is selected
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        tableView.cellForRow(at: IndexPath(row: 0, section: 0))!.setHighlighted(false, animated: false)
        return indexPath
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        print("fin de scroll")
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return device!.addresses.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let device_address = device!.addresses[indexPath.item]

        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceAddressCell", for: indexPath) as! DeviceAddressCell
        cell.textLabel!.text = device_address.toSockAddress()!.getNumericAddress()

        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        master_view_controller!.addressSelected(address: device!.addresses[indexPath.item])
    }

    // MARK: - Navigation

    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParentViewController {
            master_view_controller!.addressDeselected()
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        print("MasterIPViewController.prepare(for segue)")
    }

}
