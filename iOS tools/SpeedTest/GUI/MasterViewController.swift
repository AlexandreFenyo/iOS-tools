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

// MasterViewController is a DeviceManager
protocol DeviceManager {
    func addNode(_ node: Node)
    func addNode(_ node: Node, resolve_ipv4_addresses: Set<IPv4Address>)
    func addNode(_ node: Node, resolve_ipv6_addresses: Set<IPv6Address>)
    func setInformation(_ info: String)
}

// foncé: 70 80 91
// clair: 152 171 173
// fond: 104 117 134
class DeviceCell : UITableViewCell {
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var detail1: UILabel!
    @IBOutlet weak var detail2: UILabel!
    @IBOutlet weak var nIPs: UILabel!
    @IBOutlet weak var nPorts: UILabel!
}

// The MasterViewController instance is the delegate for the UITableView
class MasterViewController: UITableViewController, DeviceManager {
    @IBOutlet weak var update_button: UIBarButtonItem!
    @IBOutlet weak var stop_button: UIBarButtonItem!
    @IBOutlet weak var add_button: UIBarButtonItem!

    public var detail_view_controller : DetailViewController?
    public var detail_navigation_controller : UINavigationController?
    public var split_view_controller : SplitViewController?

    public weak var browser_chargen : ServiceBrowser?
    public weak var browser_discard : ServiceBrowser?
    
    private var browser_network : NetworkBrowser?
    private var browser_tcp : TCPPortBrowser?

    // Get the node corresponding to an indexPath in the table
    private func getNode(indexPath index_path: IndexPath) -> Node {
        guard let type = SectionType(rawValue: index_path.section), let section = DBMaster.shared.sections[type] else { fatalError() }
        return section.nodes[index_path.item]
    }

    // Update nodes and find new nodes
    // Main thread
    private func startBrowsing() {
        Timer.scheduledTimer(withTimeInterval: TimeInterval(0.5), repeats: false) {
            _ in
            self.stop_button!.isEnabled = true
            self.add_button!.isEnabled = false
            self.update_button!.isEnabled = false
            self.browser_chargen?.search()
            self.browser_discard?.search()

            // ceci déclenche de temps en temps Duplicate elements of type 'IPv6Address' were found in a Set avant même qu'il n'y ait un NetworkBrowser
            self.updateLocalNodeAndGateways()
            
            // Use ICMP to find new nodes
            let tb = TCPPortBrowser(device_manager: self)
            self.browser_tcp = tb
            let nb = NetworkBrowser(networks: DBMaster.shared.networks, device_manager: self, browser_tcp: tb)
            self.browser_network = nb
            nb.browse()
        }
    }

    // Stop looking for new nodes
    // Main thread
    private func stopBrowsing() {
        refreshControl!.endRefreshing()
        stop_button!.isEnabled = false
        add_button!.isEnabled = true
        update_button!.isEnabled = true

        browser_discard?.stop()
        browser_chargen?.stop()
        browser_network?.stop()
        browser_tcp?.stop()
        browser_network = nil
        browser_tcp = nil

        setTitle("Target List")
    }
    
    public func setTitle(_ title: String) {
        navigationItem.title = title
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
        let node = Node()
        node.v4_addresses.insert(IPv4Address("1.2.3.4")!)
        node.v4_addresses.insert(IPv4Address("1.2.3.6")!)
        addNode(node, resolve_ipv4_addresses: node.v4_addresses)
        
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
        
        // remove the section heading on iOS 15
        if #available(iOS 15.0, *) {
            // à remettre : ça pose pb avec MacCatalyst
            // UITableView.appearance().sectionHeaderTopPadding = 0
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "MasterSectionHeader")
        let header = cell as! MasterSectionHeader

        if let type = SectionType(rawValue: section), let section = DBMaster.shared.sections[type] {
            header.titleLabel.text = section.description
            header.subTitleLabel.text = section.detailed_description
            header.imageView.image = UIImage(named: section.description.replacingOccurrences(of: "/", with: ""))
        }

        return cell
    }

    private func updateLocalNodeAndGateways() {
        // Update local node
        let node = DBMaster.shared.getLocalNode()
        self.addNode(node, resolve_ipv4_addresses: node.v4_addresses)
        
        // Update local gateways
        for gw in DBMaster.shared.getLocalGateways() { self.addNode(gw, resolve_ipv4_addresses: gw.v4_addresses) }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        updateLocalNodeAndGateways()
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
        print(address.toNumericString()!, "selected")
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

    // Main thread
    func addNode(_ node: Node, resolve_ipv4_addresses: Set<IPv4Address>) {
        addNode(node)
        for address in resolve_ipv4_addresses {
            DispatchQueue.global(qos: .background).async {
                guard let name = address.resolveHostName() else { return }
                DispatchQueue.main.async {
//                    print("reverse IPv4 résolue:", name)
                    // On ne doit pas modifier un noeud qui est déjà enregistré dans la BDD DBMaster donc on crée un nouveau noeud
                    let node = Node()
                    node.v4_addresses.insert(address)
                    guard let domain_name = DomainName(name) else { return }
                    node.dns_names.insert(domain_name)
                    self.addNode(node)
                }
            }
        }
    }

    // Main thread
    func addNode(_ node: Node, resolve_ipv6_addresses: Set<IPv6Address>) {
        addNode(node)
        for address in resolve_ipv6_addresses {
            DispatchQueue.global(qos: .background).async {
                guard let name = address.resolveHostName() else { return }
                DispatchQueue.main.async {
//                    print("reverse IPv6 résolue:", name)
                    // On ne doit pas modifier un noeud qui est déjà enregistré dans la BDD DBMaster donc on crée un nouveau noeud
                    let node = Node()
                    node.v6_addresses.insert(address)
                    guard let domain_name = DomainName(name) else { return }
                    node.dns_names.insert(domain_name)
                    self.addNode(node)
                }
            }
        }
    }

    // Main thread
    func addNode(_ node: Node) {
        tableView.beginUpdates()
        let (index_paths_removed, index_paths_inserted) = DBMaster.shared.addNode(node)
        tableView.deleteRows(at: index_paths_removed, with: .automatic)
        tableView.insertRows(at: index_paths_inserted, with: .automatic)
        tableView.endUpdates()
        
        // Very important call: without it, the refresh control may not be displayed in some situations (few rows when a device is added)
        tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
    }

    // MARK: - DeviceManager protocol

    func setInformation(_ info: String) {
        setTitle(info)
    }
    
    // MARK: - UIScrollViewDelegate

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
//        print("fin de scroll")
    }

    // MARK: - Table view headers

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        // A section must cover the refresh control if we do not want this control to appear over a row when refreshing, so the section height must be greater or equal to the refresh control height
        return refreshControl!.frame.height
    }

//    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
//        let header = view as! UITableViewHeaderFooterView
//        header.backgroundView?.backgroundColor = UIColor(red: 253.0/255.0, green: 240.0/255.0, blue: 196.0/255.0, alpha: 1)
//        header.textLabel?.textColor = .black
//        header.textLabel?.font = UIFont(name: "Helvetica-Bold", size: 19)
//    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return DBMaster.shared.sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let type = SectionType(rawValue: section), let section = DBMaster.shared.sections[type] {
            return section.nodes.count
        }
        fatalError()
    }

    // cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let node = getNode(indexPath: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceCell
        cell.layer.shadowColor = UIColor.clear.cgColor
        // marche pas :
        // cell.layer.backgroundColor = .init(red: 1.0, green: 0, blue: 0, alpha: 0)
        // cell.backgroundColor = .red
        
        // Not used since the cell style is 'custom' (style set from the storyboard):
        // cell.textLabel!.text = ...

        cell.name.text = (node.mcast_dns_names.map { $0.toString() } + node.dns_names.map { $0.toString() }).first ?? "no name"
        
        if let best = (Array(node.v4_addresses.filter { (address) -> Bool in
            // 1st choice: public (not autoconfig) && unicast
            !address.isPrivate() && !address.isAutoConfig() && address.isUnicast()
        }) + Array(node.v4_addresses.filter { (address) -> Bool in
            // 2nd choice: private && not autoconfig
            address.isPrivate() && !address.isAutoConfig()
        }) + Array(node.v4_addresses.filter { (address) -> Bool in
            // 3rd choice: autoconfig
            address.isAutoConfig()
        })).first { cell.detail1.text = best.toNumericString() }
        else { cell.detail1.text = "no IPv4 address" }

        if let best = (Array(node.v6_addresses.filter { (address) -> Bool in
            // 1st choice: unicast public
            address.isUnicastPublic()
        }) + Array(node.v6_addresses.filter { (address) -> Bool in
            // 2nd choice: ULA
            address.isULA()
        }) + Array(node.v6_addresses.filter { (address) -> Bool in
            // 3rd choice: LLA
            address.isLLA()
        })).first { cell.detail2.text = best.toNumericString() ?? "invalid IPv6 address" }
        else { cell.detail2.text = "no IPv6 address" }

        cell.nIPs.text = String(node.v4_addresses.count + node.v6_addresses.count) + " IP" + (node.v4_addresses.count + node.v6_addresses.count > 1 ? "s" : "")
        cell.nPorts.text = String(node.tcp_ports.count) + " port" + (node.tcp_ports.count > 1 ? "s" : "")

       return cell
    }

    // didSelectRowAt
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        detail_view_controller!.node = getNode(indexPath: indexPath)
        stopBrowsing()

        // for iPhone, make the detail view controller visible
        splitViewController?.showDetailViewController(detail_navigation_controller!, sender: nil)
    }

    // Local gateway and Internet rows can not be removed
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !getNode(indexPath: indexPath).types.contains(.localhost)
    }

    // Delete every rows corresponding to a node
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { fatalError("editingStyle invalid") }
        let node = getNode(indexPath: indexPath)

        tableView.beginUpdates()
        let index_paths_removed = DBMaster.shared.removeNode(node)
        tableView.deleteRows(at: index_paths_removed, with: .automatic)
        tableView.endUpdates()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let master_ip_view_controller = segue.destination as! MasterIPViewController
        let index_path = tableView.indexPathForSelectedRow!
        let type = SectionType(rawValue: index_path.section)
        let section = DBMaster.shared.sections[type!]
        let node = section!.nodes[index_path.item]
        master_ip_view_controller.node = node
        master_ip_view_controller.master_view_controller = self
        if node.v4_addresses.count > 0 || node.v6_addresses.count > 0 {
            let indexPath = IndexPath(row: 0, section: 0), table_view = master_ip_view_controller.tableView!
            table_view.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
            table_view.cellForRow(at: indexPath)!.setHighlighted(true, animated: true)
            addressSelected(address: node.v4_addresses.count > 0 ? node.v4_addresses.first! : node.v6_addresses.first!)
        }
    }
}

// let frame = navigationController!.navigationBar.frame
// tableView.setContentOffset(CGPoint(x: 0, y: -(frame.height + frame.origin.y + refreshControl!.frame.size.height)), animated: true)
// tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
// tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: true)
