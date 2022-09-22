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
    init(_ device : DeviceAddress, style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(style: .default, reuseIdentifier: "DeviceAddressCell")
    }
}

// The MasterIPViewController instance is the delegate for the UITableView
class MasterIPViewController: UITableViewController {
    public var master_view_controller: MasterViewController?
    public var node : Node?

    @IBOutlet weak var stop_button: UIBarButtonItem!

    public func applicationWillResignActive() {
    }

    override func viewDidAppear(_ animated: Bool) {
        master_view_controller?.stopButtonDidAppear()
    }
    override func viewDidDisappear(_ animated: Bool) {
        master_view_controller?.stopButtonDidDisappear()
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
        tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.setHighlighted(false, animated: false)
        return indexPath
    }
    
    @IBAction func help_pressed(_ sender: Any) {
        master_view_controller?.help_pressed(sender)
    }

    @IBAction func stop_pressed(_ sender: Any) {
        master_view_controller?.stop_pressed(sender)
    }

    // MARK: - UIScrollViewDelegate

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        print("fin de scroll")
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return node!.v4_addresses.count + node!.v6_addresses.count
    }

    // cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let address = (Array(node!.v4_addresses.sorted()) + Array(node!.v6_addresses.sorted()))[indexPath.item]
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceAddressCell", for: indexPath) as! DeviceAddressCell
        cell.textLabel!.text = address.toNumericString()

        cell.textLabel!.textColor = .black
        cell.textLabel!.layer.opacity = 0.7
        cell.textLabel!.highlightedTextColor = .blue

        cell.backgroundColor = COLORS.standard_background
        
        return cell
    }


    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = (Array(node!.v4_addresses.sorted()) + Array(node!.v6_addresses.sorted()))[indexPath.item]
        master_view_controller!.addressSelected(address: address)
    }

    // MARK: - Navigation

    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)

        if isMovingFromParent {
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
