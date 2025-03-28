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

/* Introduction de la dépendance à CTHelp :
  sudo gem install cocoapods
  sudo arch -arm64e gem install ffi
  arch -x86_64 pod install
  
 fenyo@mac iOS-tools-help % cat Podfile
 platform :ios, '11.0'
 workspace 'iOS tools.xcodeproj'

 #pod 'CTHelp'

 def available_pods
     pod 'CTHelp'
 end

 target 'iOS tools' do
   available_pods
 end

 ET ouvrir comme ceci xcode :
 fenyo@mac iOS-tools-help % open iOS\ tools.xcodeproj.xcworkspace
  
  masterviewcontroller :
  let ctHelp = CTHelp()
  ctHelp.new(CTHelpItem(title:"No Image-Text Only",
                           helpText: "Eu tempor suscipit dis sed. Tortor velit orci bibendum mattis non metus ornare consequat. Condimentum habitasse dictumst eros nibh rhoncus non pulvinar fermentum. Maecenas convallis gravida facilisis. Interdum, conubia lacinia magnis duis nec quisque.Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.",
                           imageName:""))
  ctHelp.appendDefaults(companyName: "Your Company Name", emailAddress: "yourContactEmail@somewhere.com", data: nil, webSite: "https://www.yourWebsite.com", companyImageName: "CompanyLogo")
  ctHelp.presentHelp(from: self)
*/

import UIKit
import CTHelp
import iOSToolsMacros

enum NewRunAction {
    case SCAN_TCP
    case FLOOD_UDP
    case FLOOD_TCP
    case CHARGEN_TCP
    case LOOP_ICMP
    case OTHER_ACTION
}

// MasterViewController is a DeviceManager
@MainActor
protocol DeviceManager {
    func addNode(_ node: Node)
    func addNode(_ node: Node, resolve_ipv4_addresses: Set<IPv4Address>)
    func addNode(_ node: Node, resolve_ipv6_addresses: Set<IPv6Address>)
    func setInformation(_ info: String)
    func addTrace(_ content: String, level: LogLevel)
    func addTrace(_ content: String, level: LogLevel, date: Date)
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
    @IBOutlet weak var rect1: UIView!
    @IBOutlet weak var rect2: UIView!
}

@MainActor
class DelaySync {
    private var delay: useconds_t = 1000000

    func setDelay(_ delay: useconds_t) {
        self.delay = delay
    }

    func getDelay() -> useconds_t {
        return delay
    }
}

// The MasterViewController instance is the delegate for the main UITableView
@MainActor
class MasterViewController: UITableViewController, DeviceManager {
    func addTrace(_ content: String, level: LogLevel = .ALL) {
        traces_view_controller?.addTrace(content, level: level)
    }

    func addTrace(_ content: String, level: LogLevel = .ALL, date: Date) {
        traces_view_controller?.addTrace(content, level: level, date: date)
    }

    @IBOutlet weak var update_button: UIBarButtonItem!
    @IBOutlet weak var stop_button: UIBarButtonItem!
    @IBOutlet weak var add_button: UIBarButtonItem!
    @IBOutlet weak var heatmap_button: UIBarButtonItem!
    @IBOutlet weak var remove_button: UIBarButtonItem!

    private var stop_button_toggle = false
    
    var detail_view_controller: DetailViewController?
    var detail_navigation_controller: UINavigationController?
    var split_view_controller: SplitViewController?
    var traces_view_controller: TracesViewController?
    var master_ip_view_controller: MasterIPViewController?
    var interman_view_controller: IntermanViewController?

    // public weak var browser_chargen : ServiceBrowser?
    // public weak var browser_discard : ServiceBrowser?
    var browser_app: ServiceBrowser?
    var browsers = [ ServiceBrowser ]()
    
    private var browser_network: NetworkBrowser?
    private var browser_tcp: TCPPortBrowser?

    private var local_ping_client: LocalPingClient?
    private var local_ping_task: Task<(), any Error>?

    private var local_flood_client: LocalFloodClient?
    private var local_flood_sync: LocalFloodSync?
    
    private var local_chargen_client: LocalChargenClient?
    private var local_chargen_sync: LocalChargenSync?

    private var local_discard_client: LocalDiscardClient?
    private var local_discard_sync: LocalDiscardSync?

    private var delay = DelaySync()

    private var loop_task: Task<(), Never>?
    
    // Get the first indexPath corresponding to a node
    func getIndexPath(_ node: Node) -> IndexPath? {
        return DBMaster.shared.getIndexPath(node)
    }
    
    // Get the node corresponding to an indexPath in the table
    private func getNode(indexPath index_path: IndexPath) -> Node {
        guard let type = SectionType(rawValue: index_path.section), let section = DBMaster.shared.sections[type] else {
            #fatalError("getNode")
            return Node()
        }
        return section.nodes[index_path.item]
    }

    func resetToDefaultHosts() async {
        addTrace("main: remove previously discovered hosts", level: LogLevel.INFO)

        // Remove every nodes
        DBMaster.shared.removeAllNodes()
        tableView.reloadData()

        // Supprimer les réseaux
        DBMaster.shared.resetNetworks()

        // Ajouter les noeuds par défaut
        await DBMaster.shared.addDefaultNodes()
    }

    // Update nodes and find new nodes
    private func startBrowsing() async {
        // Supprimer tous les noeuds
        await resetToDefaultHosts()

        // Ce délai pour laisser le temps à l'IHM de se rafraichir de manière fluide, sinon l'animation n'est pas fluide
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        addTrace("network browsing: start browsing the network", level: .INFO)

        stop_button!.isEnabled = true
        detail_view_controller?.enableButtons(false)
        master_ip_view_controller?.stop_button.isEnabled = true
        add_button!.isEnabled = false
        remove_button!.isEnabled = false
        update_button!.isEnabled = false

        // forcer une nouvelle recherche multicast
        browser_app!.stop()
        browser_app!.search()
        for browser in self.browsers {
            browser.stop()
            browser.search()
        }

        updateLocalNodeAndGateways()

        // Use ICMP to find new nodes
        let tb = TCPPortBrowser(device_manager: self)
        browser_tcp = tb

        let nb = await NetworkBrowser(networks: DBMaster.shared.networks, device_manager: self, browser_tcp: tb)
        // let nb = NetworkBrowser(networks: DBMaster.shared.networks, device_manager: self)

        browser_network = nb
        await nb.browseAsync() {
            await self.stopBrowsingAsync(.OTHER_ACTION)
        }
    }

    // Stop looking for new nodes
    func stopBrowsing(_ action: NewRunAction) async {
        if stop_button!.isEnabled { self.addTrace("network browsing: stop browsing the network", level: .INFO) }

        detail_view_controller?.ts.clearAverage()

        refreshControl!.endRefreshing()
        stop_button!.isEnabled = false
        detail_view_controller?.enableButtons(true)
        master_ip_view_controller?.stop_button.isEnabled = false
        add_button!.isEnabled = true
        remove_button!.isEnabled = true
        update_button!.isEnabled = true

        // browser_discard?.stop()
        // browser_chargen?.stop()
        // browser_app?.stop()
        
        await browser_network?.stop()
        await browser_tcp?.stop()
        browser_network = nil
        browser_tcp = nil
        
        if action != .LOOP_ICMP {
            local_ping_client?.stop()
            local_ping_client?.close()
            local_ping_client = nil
        }
        
        if action != .FLOOD_UDP {
            Task {
                await local_flood_sync?.stop()
                await local_flood_sync?.close()
                local_flood_sync = nil
                local_flood_client = nil
            }
        }
        
        if action != .CHARGEN_TCP {
            Task {
                await local_chargen_sync?.stop()
                await local_chargen_sync?.close()
                local_chargen_sync = nil
                local_chargen_client = nil
            }
        }
        
        if action != .FLOOD_TCP {
            Task {
                await local_discard_sync?.stop()
                await local_discard_sync?.close()
                local_discard_sync = nil
                local_discard_client = nil
            }
        }

        setTitle(NSLocalizedString("Target List", comment: "Target List"))
    }
    
    func stopBrowsingAsync(_ action: NewRunAction) async {
        if stop_button!.isEnabled { self.addTrace("network browsing: stop browsing the network", level: .INFO) }

        detail_view_controller?.ts.clearAverage()

        refreshControl!.endRefreshing()
        stop_button!.isEnabled = false
        detail_view_controller?.enableButtons(true)
        master_ip_view_controller?.stop_button.isEnabled = false
        add_button!.isEnabled = true
        remove_button!.isEnabled = true
        update_button!.isEnabled = true

        // browser_discard?.stop()
        // browser_chargen?.stop()
        // browser_app?.stop()
        
        await browser_network?.stop()
        await browser_tcp?.stop()
        browser_network = nil
        browser_tcp = nil
        
        if action != .LOOP_ICMP {
            local_ping_client?.stop()
            local_ping_client?.close()
            local_ping_client = nil
        }
        
        if action != .FLOOD_UDP {
            Task {
                await local_flood_sync?.stop()
                await local_flood_sync?.close()
                local_flood_sync = nil
                local_flood_client = nil
            }
        }
        
        if action != .CHARGEN_TCP {
            Task {
                await local_chargen_sync?.stop()
                await local_chargen_sync?.close()
                local_chargen_sync = nil
                local_chargen_client = nil
            }
        }
        
        if action != .FLOOD_TCP {
            Task {
                await local_discard_sync?.stop()
                await local_discard_sync?.close()
                local_discard_sync = nil
                local_discard_client = nil
            }
        }

        setTitle(NSLocalizedString("Target List", comment: "Target List"))
    }

    func setTitle(_ title: String) {
        navigationItem.title = title

        // changer la couleur du texte qui est en noir par défaut

//        navigationController!.navigationBar.barStyle = .default
//        navigationController?.navigationBar.barTintColor = .blue
//        print(navigationController?.navigationBar.barTintColor)
//        navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.red]
    }
    
    @IBAction func remove_pressed(_ sender: Any) {
        popUpHelp(.remove_nodes, "This button will remove every node automatically discovered during the current session. It will not affect local host, local gateway, static default nodes nor nodes you added manually. To remove a node you added manually, swipe left on this node.") {
            Task.detached { @MainActor in
                await self.resetToDefaultHosts()
                await DBMaster.shared.addDefaultNodes()
                self.updateLocalNodeAndGateways()
            }
        }
    }
    
    @IBAction func add_pressed(_ sender: Any) {
        let add_view_controller = AddViewController()
        add_view_controller.master_view_controller = self
        present(add_view_controller, animated: true)
    }

    @IBAction func help_pressed(_ sender: Any) {
        let ctHelp = CTHelp()
        ctHelp.new(CTHelpItem(title: "Actions 1/2",
                                 helpText: "",
                                 imageName: "docs-actions"))
        ctHelp.new(CTHelpItem(title: "Actions 2/2",
                                 helpText: "",
                                 imageName: "docs-actions-2"))
        ctHelp.new(CTHelpItem(title: NSLocalizedString("Scan local network", comment: "Scan local network"),
                                 helpText: "",
                                 imageName: "docs-browse-stop"))
        ctHelp.new(CTHelpItem(title: NSLocalizedString("Advanced actions", comment: "Advanced actions"),
                                 helpText: "",
                                 imageName: "docs-action-bar"))
        ctHelp.new(CTHelpItem(title: NSLocalizedString("Chart usage", comment: "Chart usage"),
                                 helpText: "",
                                 imageName: "docs-chart"))
        ctHelp.new(CTHelpItem(title: NSLocalizedString("Internet speed test", comment: "Internet speed test"),
                                 helpText: "",
                                 imageName: "docs-hosts"))
        ctHelp.new(CTHelpItem(title: NSLocalizedString("Open ports explorer", comment: "Open ports explorer"),
                                 helpText: "",
                                 imageName: "docs-ports"))
        ctHelp.new(CTHelpItem(title: NSLocalizedString("App settings", comment: "App settings"),
                              helpText: NSLocalizedString("You can reset this app, for instance to display again each help pop-up you have previously dismissed. To reset this app or update its parameters, you need to open the iOS Configuration app and select the name of this app in the app list.", comment: "You can reset this app, for instance to display again each help pop-up you have previously dismissed. To reset this app or update its parameters, you need to open the iOS Configuration app and select the name of this app in the app list."),
                                         imageName: ""))
        ctHelp.new(CTHelpItem(title: NSLocalizedString("Licensing", comment: "Licensing"),
                              helpText: NSLocalizedString("This tool makes use of CTHelp by Stewart Lynch\nhttps://github.com/StewartLynch/CTHelp/blob/master/LICENSE\n3D model credits available at https://fenyo.net/network3dwifitools/credits.html\nEven if I often publish free software open-source code (see https://github.com/AlexandreFenyo), this specific software is not free, however it is open-source, but you must not redistribute the sources.", comment: "This tool makes use of CTHelp by Stewart Lynch\nprinter 3D model: https://sketchfab.com/3d-models/printer-household-props-8-39c75da7fbd34187acd1750d7ac41142\nhttps://github.com/StewartLynch/CTHelp/blob/master/LICENSE\n\nEven if I often publish free software open-source code (see https://github.com/AlexandreFenyo), this specific software is not free, however it is open-source, but you must not redistribute the sources."),
                                         imageName: ""))
        ctHelp.appendDefaults(companyName: "Alexandre Fenyo", emailAddress: "alexandre.fenyo@gmail.com", data: nil, webSite: "https://fenyo.net/network3dwifitools/index.html?lang=\(NSLocalizedString("parameter-lang", comment: "parameter-lang"))", companyImageName: "")
        ctHelp.presentHelp(from: self)

        // UIApplication.shared.open(URL(string: "http://wifimapexplorer.com/new-manual.html?lang=\(NSLocalizedString("parameter-lang", comment: "parameter-lang"))")!)
    }

    func stop_pressed() async {
        await stopBrowsing(.OTHER_ACTION)
        // Scroll to top - will call scrollViewDidEndScrollingAnimation when finished
        tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: true)
    }
    
    @IBAction func stop_pressed(_ sender: Any) {
        Task {
            await stop_pressed()
        }
    }

    @IBAction func update_pressed(_ sender: Any) {
        popUpHelp(.update_nodes, "This button starts browsing the network for nodes on connected LANs. Then it scans each node to find open TCP ports. When needed, press the stop button to cancel this task. Traces panel will provide you with progress information if needed.")

        Task.detached { @MainActor in
            self.refreshControl!.beginRefreshing()
            //        tableView.scrollToRow(at: IndexPath(row: NSNotFound, section: 0), at: .top, animated: true)
            self.tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)
            self.stop_button!.isEnabled = false
            self.detail_view_controller?.enableButtons(true)
            self.master_ip_view_controller?.stop_button.isEnabled = false
            self.add_button!.isEnabled = false
            self.remove_button!.isEnabled = false
            self.update_button!.isEnabled = false
            
            await self.startBrowsing()
        }
    }

    func update_pressed() {
        stop_pressed(self)
        update_pressed(self)
    }

    @IBAction func home_pressed(_ sender: Any) {
        let step_by_step_view_controller = StepByStepViewController()
        step_by_step_view_controller.master_view_controller = self
        step_by_step_view_controller.modalPresentationStyle = .fullScreen
        step_by_step_view_controller.isModalInPresentation = true
        present(step_by_step_view_controller, animated: true)
    }
    
    // var _x: Int = 0
    @IBAction func debug_pressed(_ sender: Any) {
        // pour tester les traces des fatal errors
        // let x = self._x
        // let y = 5 / x
        // if x == 0 { fatalError(Traces.addMessage("ici", fct: #function, path: #file, line: #line)) }
        // #fatalError("division by zero")

        popUp(NSLocalizedString("Target List", comment: "Target List"), NSLocalizedString("Welcome on the main page of this app. Either pull down the node list or click on the reload button, to scan the local network for new nodes. You can also select a node to display its IP addresses, then launch actions on the selected target. For instance, to estimate the average incoming and outgoing speed of your Internet connection, select the target flood.eowyn.eu.org that is a host on the Internet that supports both TCP Chargen and Discard services. Then launch one of the following action: TCP flood discard to estimate outgoing speed to the Internet, or TCP flood chargen to estimate incoming speed from the Internet.", comment: "Welcome on the main page of this app. Either pull down the node list or click on the reload button, to scan the local network for new nodes. You can also select a node to display its IP addresses, then launch actions on the selected target. For instance, to estimate the average incoming and outgoing speed of your Internet connection, select the target flood.eowyn.eu.org that is a host on the Internet that supports both TCP Chargen and Discard services. Then launch one of the following action: TCP flood discard to estimate outgoing speed to the Internet, or TCP flood chargen to estimate incoming speed from the Internet."), "OK")

        
//        let node = Node()
//        node.v4_addresses.insert(IPv4Address("1.2.3.4")!)
//        node.v4_addresses.insert(IPv4Address("8.8.8.8")!)
//        node.v4_addresses.insert(IPv4Address("192.168.0.6")!)
//        node.types.insert(.ios)
//        node.types.insert(.chargen)
//        node.types.insert(.gateway)
//        node.v4_addresses.insert(IPv4Address("192.168.0.12")!)
//        node.v4_addresses.insert(IPv4Address("192.168.1.12")!)
//        node.v4_addresses.insert(IPv4Address("192.168.0.85")!)
//        addNode(node, resolve_ipv4_addresses: node.v4_addresses)
    }

    @IBAction func settings_button(_ sender: Any) {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }

    @IBAction func launch_heatmap(_ sender: Any) {
        launch_heatmap()
    }

    func launch_heatmap() {
        let heatmap_view_controller = HeatMapViewController()
        heatmap_view_controller.master_view_controller = self
        present(heatmap_view_controller, animated: true)
    }

    // Refresh started with gesture
    @objc
    private func userRefresh(_ sender: Any) {
        Task.detached { @MainActor in
            self.stop_button!.isEnabled = false
            self.detail_view_controller?.enableButtons(true)
            self.master_ip_view_controller?.stop_button.isEnabled = false
            self.add_button!.isEnabled = false
            self.remove_button!.isEnabled = false
            self.update_button!.isEnabled = false

            await self.startBrowsing()
        }
    }

    func applicationWillResignActive() {
        // on ne stoppe plus l'action en cours quand on revient d'un changement d'appli ou d'une fermeture de l'iPad
        // ce stop permettait : de ne pas avoir une courbe qui n'est pas une fonction pour une action sur le chart, de ne pas avoir un blocage de la roue qui tourne pour une action de recherche de nœuds ou de ports.
        
        // le problème avec ce stop: ça complique la production de la heat map pour l'utilisateur
        // stopBrowsing(.OTHER_ACTION)
    }

    override func viewWillAppear(_ animated: Bool) {
        // Astuce personnelle :
        // Sur iPhone, quand on démarre l'app et qu'on clique sur un noeud pour aller jusqu'au graphique des RTT, puis qu'on revient en arrière d'un cran pour voir la liste des IPs, le fond de la toolbar n'est plus transparent. C'est dû à un bug d'iOS qui recrée une subview de la toolmar de type _UIBarBackground. Pour détecter ce cas, il suffit de décompter le nombre de subviews. Si on est dans ce cas, on cache alors cette subview, car l'enlever n'a pas d'effet visuel.
        // si on liste les subviews de toolbar, on s'aperçoit
        let toolbar = self.navigationController?.toolbar
        if toolbar?.subviews.count == 3 {
            toolbar?.subviews.first?.isHidden = true
        }
        
        super.viewWillAppear(animated)
        detail_view_controller?.clearChartAndNode()
        tableView.backgroundColor = COLORS.leftpannel_bg
        // Le refresh control ne se rafraichit plus quand on revient sur cette vue depuis une autre vue, donc on force un arrêt / relance
        if refreshControl!.isRefreshing {
            refreshControl!.endRefreshing()
            refreshControl!.beginRefreshing()
        }

        detail_view_controller?.setButtonMasterHiddenState(false)
    }
        
    // Called once at app start
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)

        loop_task?.cancel()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        print("MasterViewController.viewDidLoad() called")

        Traces.getMessages { (messages: [XTrace]?) in
            guard let messages else { return }
            for message in (messages.sorted { $0.creation! <= $1.creation! }) {
                self.addTrace("persistent trace: \(message.message!)", date: message.creation!)
            }
        }
        
        // No more useful since a persistent trace is addded at the start of AppDelegate.application()
        // addTrace("main: application launched", level: .INFO)

        // Couleur du Edit
        navigationController?.navigationBar.tintColor = COLORS.leftpannel_topbar_buttons
        // Couleur des boutons en bas (reload par ex.)
        navigationController?.toolbar.tintColor = COLORS.leftpannel_bottombar_buttons

        // TESTING c'était commenté
view.backgroundColor = .red
        // Uncomment the following line to preserve selection between presentations
// TESTING
        self.clearsSelectionOnViewWillAppear = false

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
            UITableView.appearance().sectionHeaderTopPadding = 0
        }

        //self.browser_chargen?.search()
        //self.browser_discard?.search()
         self.browser_app?.search()
        for browser in self.browsers { browser.search() }

        // Launch the step-by-step process
        let step_by_step_view_controller = StepByStepViewController()
        step_by_step_view_controller.master_view_controller = self
        step_by_step_view_controller.modalPresentationStyle = .fullScreen
        step_by_step_view_controller.isModalInPresentation = true
        present(step_by_step_view_controller, animated: true)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "MasterSectionHeader")
        let header = cell as! MasterSectionHeader
        
        if let type = SectionType(rawValue: section), let section = DBMaster.shared.sections[type] {
            header.titleLabel.text = section.description
            header.titleLabel.textColor = COLORS.leftpannel_section_title
            header.subTitleLabel.text = section.detailed_description
            header.subTitleLabel.textColor = COLORS.leftpannel_section_subtitle
            header.imageView.image = UIImage(named: section.icon_description.replacingOccurrences(of: "/", with: ""))
            header.mainView.backgroundColor = COLORS.leftpannel_section_bg
        }
        
        return cell
    }
    
    func updateLocalNodeAndGateways() {
        // Update local node
        let node = DBMaster.shared.getLocalNode()
        addNode(node, resolve_ipv4_addresses: node.getV4Addresses())
        
        // Update local gateways
        for gw in DBMaster.shared.getLocalGateways() {
            addNode(gw, resolve_ipv4_addresses: gw.getV4Addresses())
        }
    }
    
    // Reload data without deselecting the selected cell
    private func reloadData() {
        let foo = tableView.indexPathForSelectedRow
        tableView.reloadData()
        tableView.selectRow(at: foo, animated: false, scrollPosition: UITableView.ScrollPosition.none)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        reloadData()
        
        updateLocalNodeAndGateways()

        navigationController!.tabBarController?.tabBar.barTintColor = COLORS.tabbar_bg
        navigationController!.tabBarController?.tabBar.backgroundColor = COLORS.tabbar_bg

        // Pour changement des couleurs du texte
        // navigationController!.navigationBar.largeTitleTextAttributes = [ .foregroundColor: UIColor.orange ]
        // navigationController!.navigationBar.titleTextAttributes = [ .foregroundColor: UIColor.orange ]
        // Titres dans la tab bar
        tabBarController?.tabBar.tintColor = COLORS.tabbar_title

        // A SUPPRIMER - pour faciliter DEBUG
        // add_pressed("")

        loop_task?.cancel()
        loop_task = Task.detached { @MainActor in
            repeat {
                // TESTS à enlever
//                self.navigationController?.toolbar.backgroundColor = .red

                
                
                self.stop_button_toggle.toggle()
                if self.stop_button.isEnabled {
                    self.stop_button.tintColor = self.stop_button_toggle ? COLORS.leftpannel_bottombar_buttons : COLORS.leftpannel_bottombar_buttons.lighter().lighter().lighter().lighter().lighter().lighter().lighter().lighter().lighter()
                } else {
                    self.stop_button.tintColor = COLORS.leftpannel_bottombar_buttons
                }
                try? await Task.sleep(nanoseconds: 500_000_000)
            } while Task.isCancelled == false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        detail_view_controller?.setButtonMasterHiddenState(true)
    }

    // Disable other actions while editing
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        refreshControl!.endRefreshing()
        if editing {
            stop_button!.isEnabled = false
            detail_view_controller?.enableButtons(true)
            master_ip_view_controller?.stop_button.isEnabled = false
            add_button!.isEnabled = false
            remove_button!.isEnabled = false
            update_button!.isEnabled = false
        } else {
            stop_button!.isEnabled = false
            detail_view_controller?.enableButtons(true)
            master_ip_view_controller?.stop_button.isEnabled = false
            add_button!.isEnabled = true
            remove_button!.isEnabled = true
            update_button!.isEnabled = true
        }
    }

    // Called by MasterIPViewController when an address is selected
    func addressSelected(address: IPAddress) {
        detail_view_controller?.scrollToTop()
  
        detail_view_controller!.addressSelected(address, !stop_button!.isEnabled)

        // for iPhone (no effect on iPad), make the detail view controller visible
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 500_000_000)
            if self.detail_view_controller?.can_be_launched == true {
                if self.detail_view_controller?.view.window == nil {
                    self.detail_view_controller?.can_be_launched = false
                }
                
                self.splitViewController?.showDetailViewController(self.detail_navigation_controller!, sender: nil)

                self.master_ip_view_controller?.info_button.isEnabled = true
            }
        }
    }

    // Called by MasterIPViewController when an address is deselected and no other address is selected
    func addressDeselected() {
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // Main thread
    func setDelay(_ delay: useconds_t) async {
        self.delay.setDelay(delay)
    }
    
    // Main thread
    func addNode(_ node: Node, resolve_ipv4_addresses: Set<IPv4Address>) {
        addNode(node)
        for address in resolve_ipv4_addresses {
            // A Task may sometimes be executed on the Main thread, therefore it would block the main thread because of the system call to getnameinfo(). This occurred, this is why we use a DispatchQueue and not a Task here.
            // Task(priority: .background) {
            DispatchQueue.global(qos: .background).async {
                
                guard let name = address.resolveHostName() else { return }
                
                Task { @MainActor in
                    // Reverse IPv4 résolue
                    // On ne doit pas modifier un noeud qui est déjà enregistré dans la BDD DBMaster donc on crée un nouveau noeud
                    let node = Node()
                    node.addV4Address(address)
                    guard let domain_name = DomainName(name) else { return }
                    node.addDnsName(domain_name)
                    self.addNode(node)
                }
            }
        }
    }
    
    // Main thread
    func addNode(_ node: Node, resolve_ipv6_addresses: Set<IPv6Address>) {
        addNode(node)
        for address in resolve_ipv6_addresses {
            // A Task may sometimes be executed on the Main thread, therefore it would block the main thread because of the system call to getnameinfo(). This occurred, this is why we use a DispatchQueue and not a Task here.
            // Task(priority: .background) {
            DispatchQueue.global(qos: .background).async {
                
                guard let name = address.resolveHostName() else { return }
                Task { @MainActor in
                    // Reverse IPv6 résolue
                    // On ne doit pas modifier un noeud qui est déjà enregistré dans la BDD DBMaster donc on crée un nouveau noeud
                    let node = Node()
                    node.addV6Address(address)
                    guard let domain_name = DomainName(name) else { return }
                    node.addDnsName(domain_name)
                    self.addNode(node)
                }
            }
        }
    }

    // Main thread
    func addNode(_ node: Node) {
//        tableView.beginUpdates()
//        let (index_paths_removed, index_paths_inserted) = DBMaster.shared.addNode(node)
//        tableView.deleteRows(at: index_paths_removed, with: .automatic)
//        tableView.insertRows(at: index_paths_inserted, with: .automatic)
//        tableView.endUpdates()

        // comme on a supprimé le bloc plus bas (à partir de `if tableView.window...'), on n'a plus besoin de récupérer les valeurs renvoyées
//        let (index_paths_removed, index_paths_inserted) = DBMaster.shared.addNode(node)
        _ = DBMaster.shared.addNode(node)
        
        // Si on faire un refresh et qu'on bascule tout de suite sur onglet Traces, puis qu'on revient un peu après, on a une erreur fatale du type :
        // Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Invalid update: invalid number of rows in section 5. The number of rows contained in an existing section after the update (38) must be equal to the number of rows contained in that section before the update (19), plus or minus the number of rows inserted or deleted from that section (1 inserted, 0 deleted) and plus or minus the number of rows moved into or out of that section (0 moved in, 0 moved out). Table view: <UITableView: 0x10104b800; frame = (0 0; 359 834); clipsToBounds = YES; autoresize = W+H; gestureRecognizers = <NSArray: 0x283241980>; layer = <CALayer: 0x283c975a0>; contentOffset: {0, -50}; contentSize: {359, 2113.5}; adjustedContentInset: {110, 0, 115, 0}; dataSource: <iOS_tools.MasterViewController: 0x101022c00>>'
        // solution semble-t-il : on remplace le bloc suivant par un simple tableView.reloadData()
        /*
        if tableView.window != nil {
            // la liste des noeuds est affichée à gauche (et non pas la liste des IP d'un noeud)

            tableView.performBatchUpdates {
                tableView.deleteRows(at: index_paths_removed, with: .automatic)
                tableView.insertRows(at: index_paths_inserted, with: .automatic)
            }
            // Very important call: without it, the refresh control may not be displayed in some situations (few rows when a device is added)
            tableView.scrollRectToVisible(CGRect(x: 0, y: 0, width: 1, height: 1), animated: true)

            reloadData()
        }
        */
        reloadData()

        // si le noeud a une IP qui est affichée à droite, il faut mettre à jour ce qui est affiché à droite
        detail_view_controller!.updateDetailsIfNodeDisplayed(node, !stop_button!.isEnabled)
    }

    // MARK: - Calls from DetailSwiftUIView
    func scanTCP(_ address: IPAddress) async {
        await stopBrowsing(.SCAN_TCP)
        stop_button!.isEnabled = true
        detail_view_controller?.enableButtons(false)
        master_ip_view_controller?.stop_button.isEnabled = true
        add_button!.isEnabled = false
        remove_button!.isEnabled = false
        update_button!.isEnabled = false

        let tb = TCPPortBrowser(device_manager: self)
        browser_tcp = tb

        Task.detached(priority: .userInitiated) {
            await self.browser_tcp?.browseAsync(address: address) {
                Task {
                    await self.stopBrowsing(.OTHER_ACTION)
                }
            }
        }
    }

    func loopICMP(_ address: IPAddress, display_timeout: Bool = true) async {
        if local_ping_task != nil {
            local_ping_task!.cancel()
            local_ping_task = nil
        }
        
        await stopBrowsing(.LOOP_ICMP)
        stop_button!.isEnabled = true

        if display_timeout {
            detail_view_controller?.enableButtons(false)
        }

        master_ip_view_controller?.stop_button.isEnabled = true
        add_button!.isEnabled = false
        remove_button!.isEnabled = false
        update_button!.isEnabled = false

        let current_delay = delay.getDelay()
        
        // WARNING: we should implement an infinite loop (not 0 to 10000), in a further release
        local_ping_client = LocalPingClient(address: address, count: 10000, initial_delay: current_delay)
        
        local_ping_task = Task.detached(priority: .userInitiated) {
            // This code added after a _local_ping_client crash log certainly due to self.local_ping_client!
            guard let _local_ping_client = await self.local_ping_client else {
                _ = #saveTrace("local_ping_client is nil")
                return
            }
            while _local_ping_client.isInsideLoop() == 1 {
                _local_ping_client.stop()
                try? await Task.sleep(nanoseconds: 200_000_000)
            }
            
            _local_ping_client.start()

            Task { @MainActor in
                self.addTrace("ICMP loop: starting for target \(address.toNumericString() ?? "")", level: .INFO)
                DBMaster.shared.notifyICMPSent(address: address)
            }

            var has_answered = false
            var nloop = 0
            await self.detail_view_controller?.ts.setUnits(units: .RTT)
            await self.detail_view_controller?.ts.removeAll()
            while Task.isCancelled == false {
                if let rtt = await self.local_ping_client?.getRTT() {
                    if rtt > 0 {
                        has_answered = true
                        Task { @MainActor in
                            DetailViewModel.shared.setCurrentMeasurementUnit("µs")
                            DetailViewModel.shared.setMeasurementValue(Double(rtt))
                            self.addTrace("ICMP loop: received answer from \(address.toNumericString() ?? "") after \(rtt) µs", level: .INFO)
                            DBMaster.shared.notifyICMPReceived(address: address)
                        }
                        await self.detail_view_controller?.ts.add(TimeSeriesElement(date: Date(), value: Float(rtt)))
                    }
                } else { break }

                let delay = await self.delay.getDelay()
                await self.local_ping_client?.setDelay(delay: delay)
                
                try? await Task.sleep(nanoseconds: NSEC_PER_SEC / 10)
                nloop += 1
                if has_answered == false && nloop > 50 {
                    await self.stopBrowsing(.OTHER_ACTION)
                    if display_timeout {
                        await self.popUp("ICMP", "timeout occurred, no answer from target", "continue")
                    }
                    break
                }
            }
            // objectif : arrivé ici, la boucle de ping est terminée
            Task { @MainActor in
                DetailViewModel.shared.setCurrentMeasurementUnit("")
                DetailViewModel.shared.setMeasurementValue(0)
                self.addTrace("ICMP loop: stopped with target \(address.toNumericString() ?? "")", level: .INFO)
            }
        }
    }

    func floodUDP(_ address: IPAddress) async {
        await stopBrowsing(.FLOOD_UDP)
        self.stop_button!.isEnabled = true
        detail_view_controller?.enableButtons(false)
        self.master_ip_view_controller?.stop_button.isEnabled = true
        self.add_button!.isEnabled = false
        self.remove_button!.isEnabled = false
        self.update_button!.isEnabled = false

        local_flood_client = LocalFloodClient(address: address)
        local_flood_sync = LocalFloodSync(local_flood_client!)
        local_flood_client!.start()

        Task.detached(priority: .userInitiated) {
            Task { @MainActor in
                self.addTrace("flood UDP port 8888 starting for target \(address.toNumericString() ?? "")", level: .INFO)
                DBMaster.shared.notifyFloodUDP(address: address)
            }

            await self.popUp(NSLocalizedString("UDP flood", comment: "UDP flood"), NSLocalizedString("UDP flooding sends packets asynchronously to UDP port 8888 of the target at a maximum rate, but many packets can be lost at software, hardware or network layers. Note that the throughput that is displayed on this chart is the one achieved at the software layer of your device. Therefore, it certainly is above the one at which data is sent over the network: you must use a tool to estimate the reached bandwitdh. Either sniff the network or count packets on the target, for instance.", comment: "UDP flooding sends packets asynchronously to UDP port 8888 of the target at a maximum rate, but many packets can be lost at software, hardware or network layers. Note that the throughput that is displayed on this chart is the one achieved at the software layer of your device. Therefore, it certainly is above the one at which data is sent over the network: you must use a tool to estimate the reached bandwitdh. Either sniff the network or count packets on the target, for instance."), NSLocalizedString("I understand", comment: "I understand"))
            await self.detail_view_controller?.ts.setUnits(units: .BANDWIDTH)
            await self.detail_view_controller?.ts.removeAll()
            var first_skipped = false
            while true {
                if let throughput = await self.local_flood_client?.getThroughput() {
                    if throughput > 0 {
                        if first_skipped == false {
                            first_skipped = true
                        } else {
                            Task { @MainActor in
                                DetailViewModel.shared.setCurrentMeasurementUnit("bit/s")
                                DetailViewModel.shared.setMeasurementValue(throughput)
                                self.addTrace("flood UDP port 8888: target \(address.toNumericString() ?? "") throughput \(String(describing: GenericTools.convertDoubleToInt(throughput)))", level: .INFO)
                            }
                            await self.detail_view_controller?.ts.add(TimeSeriesElement(date: Date(), value: Float(throughput)))
                        }
                    }
                } else { break }
                let delay = await self.delay.getDelay()
                try? await Task.sleep(nanoseconds: UInt64(delay) * 1000)
            }
            // objectif : arrivé ici, la boucle de flood est terminée
            Task { @MainActor in
                DetailViewModel.shared.setCurrentMeasurementUnit("")
                DetailViewModel.shared.setMeasurementValue(0)
                self.addTrace("flood UDP port 8888: stopped with target \(address.toNumericString() ?? "")", level: .INFO)
                DBMaster.shared.notifyFloodUDPFinished(address: address)
            }
        }
    }
    
    // connect to discard service
    func floodTCP(_ address: IPAddress) async {
        await stopBrowsing(.FLOOD_TCP)
        self.stop_button!.isEnabled = true
        detail_view_controller?.enableButtons(false)
        self.master_ip_view_controller?.stop_button.isEnabled = true
        self.add_button!.isEnabled = false
        self.remove_button!.isEnabled = false
        self.update_button!.isEnabled = false

        local_discard_client = LocalDiscardClient(address: address)
        local_discard_sync = LocalDiscardSync(local_discard_client!)
        local_discard_client!.start()

        Task.detached(priority: .userInitiated) {
            Task { @MainActor in
                self.addTrace("flood TCP discard port: starting for target \(address.toNumericString() ?? "")", level: .INFO)
            }

            var is_connected = false
            var nsec = 0.0
            await self.detail_view_controller?.ts.setUnits(units: .BANDWIDTH)
            await self.detail_view_controller?.ts.removeAll()
            while true {
                if let throughput = await self.local_discard_client?.getThroughput() {
                    if throughput > 0 {
                        is_connected = true
                        Task { @MainActor in
                            DetailViewModel.shared.setCurrentMeasurementUnit("bit/s")
                            DetailViewModel.shared.setMeasurementValue(throughput)
                            self.addTrace("flood TCP discard port: target \(address.toNumericString() ?? "") throughput \(Int(throughput)) bit/s", level: .INFO)
                            DBMaster.shared.notifyFloodTCP(address: address)
                        }
                        await self.detail_view_controller?.ts.add(TimeSeriesElement(date: Date(), value: Float(throughput)))
                    }
                    if throughput < 0 {
                        let errno = await self.local_discard_client?.getLastErrno()
                        if errno != 0 {
                            if errno == ECONNREFUSED || errno == ECONNABORTED {
                                let str = errno == ECONNABORTED ? "connection aborted" : "connection refused"
                                var message = str
                                let is_public_default_service = await DBMaster.shared.isPublicDefaultService(address.toNumericString()!)
                                if address.toNumericString() != nil && is_public_default_service {
                                    message = "connection \(str) - public DNS services do not offer Discard service support - you can use the target named flood.eowyn.eu.org that supports the Discard service"
                                }
                                await self.popUp("TCP discard", message, "continue")
                            } else {
                                if errno == ENETUNREACH || errno == EHOSTUNREACH || errno == EIO {
                                    await self.popUp("TCP discard", "network unreachable - check your Internet connection", "continue")
                                } else {
                                    if errno == ECONNRESET {
                                        await self.popUp("TCP discard", "Connection reset by peer", "continue")
                                    } else {
                                        if errno == nil || errno == EBADF {
                                            await self.popUp("TCP discard", "Connection closed", "continue")
                                        } else {
                                            await self.popUp("TCP discard", "error (errno = \(String(describing: errno)))", "continue")
                                        }
                                    }
                                }
                            }
                            break
                        }
                    }
                } else {
                    print("\(#function) error: break")
                    break
                }
                let delay = await self.delay.getDelay()
                try? await Task.sleep(nanoseconds: UInt64(delay) * 1000)
                nsec += Double(delay) / 1000000
                if is_connected == false && nsec > 5 {
                    var message = "timeout occurred"
                    let is_public_default_service = await DBMaster.shared.isPublicDefaultService(address.toNumericString()!)
                    if address.toNumericString() != nil && is_public_default_service {
                        message = "timeout occurred - public DNS services do not offer Discard service support - you can use the target named flood.eowyn.eu.org that supports the Discard service"
                    }
                    await self.popUp("TCP discard", message, "continue")
                    break
                }
            }
            await self.stopBrowsing(.OTHER_ACTION)
            // objectif : arrivé ici, la boucle de chargen est terminée
            await self.detail_view_controller?.removeMapButton()
            Task { @MainActor in
                DetailViewModel.shared.setCurrentMeasurementUnit("")
                DetailViewModel.shared.setMeasurementValue(0)
                self.addTrace("flood TCP discard port: stopped with target \(address.toNumericString() ?? "")", level: .INFO)
                DBMaster.shared.notifyFloodTCPFinished(address: address)
            }
        }
    }

    func chargenTCP(_ address: IPAddress) async {
        await stopBrowsing(.CHARGEN_TCP)
        self.stop_button!.isEnabled = true
        detail_view_controller?.enableButtons(false)
        self.master_ip_view_controller?.stop_button.isEnabled = true
        self.add_button!.isEnabled = false
        self.remove_button!.isEnabled = false
        self.update_button!.isEnabled = false

        local_chargen_client = LocalChargenClient(address: address)
        local_chargen_sync = LocalChargenSync(local_chargen_client!)
        local_chargen_client!.start()

        Task.detached(priority: .userInitiated) {
            Task { @MainActor in
                self.addTrace("flood TCP chargen port: starting for target \(address.toNumericString() ?? "")", level: .INFO)
                DBMaster.shared.notifyChargenTCP(address: address)
            }

            var is_connected = false
            var nsec = 0.0
            await self.detail_view_controller?.ts.setUnits(units: .BANDWIDTH)
            await self.detail_view_controller?.ts.removeAll()
            while true {
                if let throughput = await self.local_chargen_client?.getThroughput() {
                    if throughput > 0 {
                        is_connected = true
                        Task { @MainActor in
                            DetailViewModel.shared.setCurrentMeasurementUnit("bit/s")
                            DetailViewModel.shared.setMeasurementValue(throughput)
                            self.addTrace("flood TCP chargen port: target \(address.toNumericString() ?? "") throughput \(String(describing: GenericTools.convertDoubleToInt(throughput))) bit/s", level: .INFO)
                        }
                        await self.detail_view_controller?.ts.add(TimeSeriesElement(date: Date(), value: Float(throughput)))
                    }
                    if throughput < 0 {
                        let errno = await self.local_chargen_client?.getLastErrno()
                        if errno != 0 {
                            if errno == ECONNREFUSED || errno == ECONNABORTED {
                                let str = errno == ECONNABORTED ? "connection aborted" : "connection refused"
                                var message = str
                                let is_public_default_service = await DBMaster.shared.isPublicDefaultService(address.toNumericString()!)
                                if address.toNumericString() != nil && is_public_default_service {
                                    message = "connection \(str) - public DNS services do not offer Chargen service support - you can use the target named flood.eowyn.eu.org that supports the Chargen service"
                                }
                                await self.popUp("TCP chargen", message, "continue")
                            } else {
                                if errno == ENETUNREACH || errno == EHOSTUNREACH || errno == EIO {
                                    await self.popUp("TCP chargen", "network unreachable - check your Internet connection", "continue")
                                } else {
                                    if errno == ECONNRESET {
                                        await self.popUp("TCP chargen", "Connection reset by peer", "continue")
                                    } else {
                                        if errno == nil || errno == EBADF {
                                            await self.popUp("TCP chargen", "Connection closed", "continue")
                                        } else {
                                            await self.popUp("TCP chargen", "error (errno = \(String(describing: errno)))", "continue")
                                        }
                                    }
                                }
                            }
                        }
                        break
                    }
                } else {
                    break
                }
                let delay = await self.delay.getDelay()
                try? await Task.sleep(nanoseconds: UInt64(delay) * 1000)
                nsec += Double(delay) / 1000000
                if is_connected == false && nsec > 5 {
                    var message = "timeout occurred"
                    
                    let is_public_default_service = await DBMaster.shared.isPublicDefaultService(address.toNumericString()!)
                    if address.toNumericString() != nil && is_public_default_service {
                        message = "timeout occurred - public DNS services do not offer Chargen service support - you can use the target named flood.eowyn.eu.org that supports the Chargen service"
                    }
                    await self.popUp("TCP chargen", message, "continue")
                    break
                }
            }
            await self.stopBrowsing(.OTHER_ACTION)
            // objectif : arrivé ici, la boucle de chargen est terminée
            await self.detail_view_controller?.removeMapButton()
            Task { @MainActor in
                DetailViewModel.shared.setCurrentMeasurementUnit("")
                DetailViewModel.shared.setMeasurementValue(0)
                self.addTrace("flood TCP chargen port: stopped with target \(address.toNumericString() ?? "")", level: .INFO)
                DBMaster.shared.notifyChargenTCPFinished(address: address)
            }
        }
    }

    func popUpHelp(_ title: PopUpMessages, _ message: String, completion: (() -> Void)? = nil) {
        let key = "help." + title.rawValue
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: key) == false {
            let alert = UIAlertController(title: NSLocalizedString("Help: ", comment: "Help: ") + NSLocalizedString(title.rawValue, comment: "titre"), message: NSLocalizedString(message, comment: "message"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Don't show this message again", comment: "Don't show this message again"), style: .default, handler: { _ in
                defaults.set(true, forKey: key)
                completion?()
            }))
            alert.addAction(UIAlertAction(title: NSLocalizedString("Dismiss further help messages", comment: "Dismiss further help messages"), style: .default, handler: { _ in
                for msg in (PopUpMessages.allCases.map { $0 }) {
                    defaults.set(true, forKey: "help." + msg.rawValue)
                }
                completion?()
            }))
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_: UIAlertAction!) in
                completion?()
            }))
            parent!.present(alert, animated: true, completion: nil)
        } else {
            completion?()
        }
    }
    
    func popUp(_ title: String, _ message: String, _ ok: String) {
        Task { @MainActor in
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let action = UIAlertAction(title: ok, style: .default)
            alert.addAction(action)
            // self.parent!.present au lieu de self.present pour éviter le message d'erreur "Presenting view controllers on detached view controllers is discouraged"
            self.parent!.present(alert, animated: true)
        }
    }
    
    // MARK: - DeviceManager protocol

    func setInformation(_ info: String) {
        setTitle(info)
    }
    
    // MARK: - UIScrollViewDelegate

    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
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
        #fatalError("tableView")
        return 0
    }

    // cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let node = getNode(indexPath: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceCell

        // apparemment aucun effet de ce positionnement de couleur
//        cell.layer.shadowColor = UIColor.clear.cgColor
//        cell.layer.shadowColor = UIColor.red.cgColor

        // Create some sort of shadow
        cell.rect1.backgroundColor = COLORS.leftpannel_node_rect1_bg
        cell.rect2.backgroundColor = COLORS.leftpannel_node_rect2_bg

        // Couleur de fond quand on clique sur éditer pour supprimer une cellule
        cell.backgroundColor = COLORS.leftpannel_node_edit_bg

        // Specific background color for the dedicated flooding node on the Interner
        if node.getMcastDnsNames().contains(FQDN("flood", "eowyn.eu.org")) {
            cell.backgroundColor =  COLORS.leftpannel_bg.lighter().lighter().lighter()
        }
        
        // Host cell Background color when selected
        let bgColorView = UIView()
        bgColorView.backgroundColor = COLORS.leftpannel_bg.darker().darker().darker()
        cell.selectedBackgroundView = bgColorView

        // On supprime le changement de couleur de fond en cas de sélection via le positionnement d'une couleur de fond
// TESTING
        //        cell.contentView.backgroundColor = COLORS.leftpannel_node_select_bg
        
        // Not used since the cell style is 'custom' (style set from the storyboard):
        // cell.textLabel!.text = ...

        cell.name.text = (node.getMcastDnsNames().map { $0.toString() } + node.getDnsNames().map { $0.toString() }).first ?? "no name"
        
        if let best = (Array(node.getV4Addresses().filter { (address) -> Bool in
            // 1st choice: public (not autoconfig) && unicast
            !address.isPrivate() && !address.isAutoConfig() && address.isUnicast()
        }) + Array(node.getV4Addresses().filter { (address) -> Bool in
            // 2nd choice: private && not autoconfig
            address.isPrivate() && !address.isAutoConfig()
        }) + Array(node.getV4Addresses().filter { (address) -> Bool in
            // 3rd choice: autoconfig
            address.isAutoConfig()
        })).first { cell.detail1.text = best.toNumericString() }
        else { cell.detail1.text = "no IPv4 address" }

        if let best = (Array(node.getV6Addresses().filter { (address) -> Bool in
            // 1st choice: unicast public
            address.isUnicastPublic()
        }) + Array(node.getV6Addresses().filter { (address) -> Bool in
            // 2nd choice: ULA
            address.isULA()
        }) + Array(node.getV6Addresses().filter { (address) -> Bool in
            // 3rd choice: LLA
            address.isLLA()
        })).first { cell.detail2.text = best.toNumericString() ?? "invalid IPv6 address" }
        else { cell.detail2.text = "no IPv6 address" }

        cell.nIPs.text = String(node.getV4Addresses().count + node.getV6Addresses().count) + " IP" + (node.getV4Addresses().count + node.getV6Addresses().count > 1 ? "s" : "")
        cell.nPorts.text = String(node.getTcpPorts().count + node.getUdpPorts().count) + " port" + (node.getTcpPorts().count + node.getUdpPorts().count > 1 ? "s" : "")

       return cell
    }

    // didSelectRowAt
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let node = getNode(indexPath: indexPath)
        let node1 = Node()
        node1.addMcastFQDN(FQDN("dns", "google"))
        let node2 = Node()
        node2.addMcastFQDN(FQDN("dns9", "quad9.net"))
        let node3 = Node()
        node3.addMcastFQDN(FQDN("flood", "eowyn.eu.org"))
        if node.isSimilar(with: node1) || node.isSimilar(with: node2) {
            popUpHelp(.node_info_public_host, "This kind of public node on the Internet should only be used for running an ICMP (ping) action, to estimate the network average round trip time (RTT). Other services are not supported by those remote hosts.")
        } else if node.isLocalHost() {
            popUpHelp(.localhost, "This node corresponds to your Apple device. You can see displayed its many IPv4 and IPv6 addresses. Select one of these IPs and start a local loop action.")
        } else if node.isSimilar(with: node3) {
            popUpHelp(.internet_speed, "On this node, the TCP Chargen and Discard services are activated. This node, dedicated to this app and deployed in a cloud on the Internet, lets you estimate your maximum outgoing and incoming throughput. Start the action TCP Flood Discard to connect to the discard service and send outgoing data to it, this will allow you to evaluate your outgoing/upload bandwidth. Start the action TCP Flood Chargen to connect to the chargen service and receive incoming data from it, this will allow you to evaluate your incoming/download bandwidth.")
        }

        interman_view_controller!.setSelectedNode(node)
        
        Task {
            await stopBrowsing(.OTHER_ACTION)
        }
    }

    // Local gateway and Internet rows can not be removed
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return !getNode(indexPath: indexPath).isLocalHost()
    }

    // Delete every rows corresponding to a node
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle != .delete { #fatalError("editingStyle invalid") }
        let node = getNode(indexPath: indexPath)

        var new_persistent_node_list = [String]()
        let config = UserDefaults.standard.stringArray(forKey: "nodes") ?? [ ]
        for str in config {
            let str_fields = str.split(separator: ";", maxSplits: 2)
            let target_name = String(str_fields[0])
            if !node.getDnsNames().map({ $0.toString() }).contains(target_name) {
                new_persistent_node_list.insert(str, at: new_persistent_node_list.endIndex)
            }
        }
        UserDefaults.standard.set(new_persistent_node_list, forKey: "nodes")
            
        tableView.beginUpdates()
        let index_paths_removed = DBMaster.shared.removeNode(node)
        tableView.deleteRows(at: index_paths_removed, with: .automatic)
        tableView.endUpdates()
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        master_ip_view_controller = segue.destination as? MasterIPViewController
        let index_path = tableView.indexPathForSelectedRow!
        let type = SectionType(rawValue: index_path.section)
        let section = DBMaster.shared.sections[type!]
        let node = section!.nodes[index_path.item]
        master_ip_view_controller!.node = node
        master_ip_view_controller!.master_view_controller = self

        /* si on voulait sélectionner une adresse, on pourrait le faire comme ceci mais pas ici car la première fois où prepare est appelé, on n'a pas le droit d'appeler selectRow ou cellForRow : on a alors un warning pour signaler que ça peut conduire à des bugs
        if node.v4_addresses.count > 0 || node.v6_addresses.count > 0 {
            let indexPath = IndexPath(row: 0, section: 0), table_view = master_ip_view_controller.tableView!
            table_view.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
            table_view.cellForRow(at: indexPath)!.setHighlighted(true, animated: true)
            print("prepare()")
            addressSelected(address: node.v4_addresses.count > 0 ? node.v4_addresses.first! : node.v6_addresses.first!)
        }
       */
    }
}
