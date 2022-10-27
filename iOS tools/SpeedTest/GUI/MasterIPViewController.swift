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
    public var auto_select: String?
    
    @IBOutlet weak var stop_button: UIBarButtonItem!
    private var stop_button_toggle = false
    
    @IBOutlet weak var info_button: UIBarButtonItem!
    
    @IBOutlet weak var heatmap_button: UIBarButtonItem!

    @IBAction func settings_button(_ sender: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func launch_heatmap(_ sender: Any) {
        let heatmap_view_controller = HeatMapViewController()
        heatmap_view_controller.master_view_controller = master_view_controller
        present(heatmap_view_controller, animated: true)
    }
    
    public func applicationWillResignActive() {
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.auto_select != nil {
            info_button.isEnabled = false

            var found = false
            var cnt = 0
            for n in self.node!.v4_addresses.sorted() {
                if n.toNumericString() == self.auto_select! {
                    found = true
                    break
                }
                cnt += 1
            }
            if found == false {
                for n in self.node!.v6_addresses.sorted() {
                    if n.toNumericString() == self.auto_select! {
                        found = true
                        break
                    }
                    cnt += 1
                }
            }
            if found {
                let indexPath = IndexPath(row: cnt, section: 0)
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
                let addr = toIpAddress(self.auto_select!)
                self.master_view_controller!.addressSelected(address: addr)
            }
            self.auto_select = nil
        } else {
            info_button.isEnabled = true

            if self.node!.v4_addresses.count + self.node!.v6_addresses.count > 0 && self.tableView.indexPathForSelectedRow == nil {
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
                let ips = Array(self.node!.v4_addresses.sorted()) + Array(self.node!.v6_addresses.sorted())
                if !ips.isEmpty {
                    self.master_view_controller!.addressSelected(address: ips.first!)
                }
            }
        }
        /*
         Task.detached(priority: .userInitiated) {
         await self.master_view_controller?.detail_view_controller?.ts.setUnits(units: .BANDWIDTH)
         await self.master_view_controller?.detail_view_controller?.ts.removeAll()
         }
         */
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        clearsSelectionOnViewWillAppear = false
        
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { (timer) in
            self.stop_button_toggle.toggle()
            if self.stop_button.isEnabled {
                self.stop_button.tintColor = self.stop_button_toggle ? COLORS.leftpannel_bottombar_buttons : COLORS.leftpannel_bottombar_buttons.lighter().lighter().lighter().lighter().lighter().lighter().lighter().lighter().lighter()
            } else {
                self.stop_button.tintColor = COLORS.leftpannel_bottombar_buttons
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        master_view_controller?.detail_view_controller?.setButtonMasterIPHiddenState(false)
        tableView.backgroundColor = COLORS.leftpannel_bg
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)
        master_view_controller?.detail_view_controller?.setButtonMasterIPHiddenState(true)
        if isMovingFromParent {
            master_view_controller!.addressDeselected()
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // Since we highlight the default selected row in MasterViewController.prepare(), we need to unhighlight this row when another cell is selected
    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        // commenté car la contrepartie dans prepare() est commentée
        //        tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.setHighlighted(false, animated: false)
        
        return indexPath
    }
    
    @IBAction func help_pressed(_ sender: Any) {
        master_view_controller?.popUp("IP List", "You can select another IP or launch an action on the current IP (scan TCP ports, TCP flood discard, TCP flood chargen, UDP flood or ICMP ping).", "OK")
    }
    
    @IBAction func stop_pressed(_ sender: Any) {
        master_view_controller?.stop_pressed(sender)
    }
    
    // MARK: - UIScrollViewDelegate
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
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
        
        cell.textLabel!.textColor = COLORS.leftpannel_ip_text //.black
        cell.textLabel!.layer.opacity = COLORS.leftpannel_ip_text_opacity
        cell.textLabel!.highlightedTextColor = COLORS.leftpannel_ip_text_selected
        
        cell.backgroundColor = COLORS.standard_background
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = COLORS.chart_bg
        cell.selectedBackgroundView = bgColorView
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = (Array(node!.v4_addresses.sorted()) + Array(node!.v6_addresses.sorted()))[indexPath.item]
        master_view_controller!.addressSelected(address: address)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
}
