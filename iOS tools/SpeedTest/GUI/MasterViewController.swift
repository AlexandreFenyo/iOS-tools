
import UIKit

// MasterViewController is a DeviceManager
protocol DeviceManager {
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
    @IBOutlet weak var rect1: UIView!
    @IBOutlet weak var rect2: UIView!
}

// The MasterViewController instance is the delegate for the main UITableView
class MasterViewController: UITableViewController, DeviceManager {
    @IBOutlet weak var update_button: UIBarButtonItem!
    @IBOutlet weak var stop_button: UIBarButtonItem!
    @IBOutlet weak var add_button: UIBarButtonItem!

    public var detail_view_controller: DetailViewController?
    public var detail_navigation_controller: UINavigationController?
    public var split_view_controller: SplitViewController?

    // Update nodes and find new nodes
    // Main thread
    private func startBrowsing() {
        // Ce délai pour laisser le temps à l'IHM de se rafraichir de manière fluide, sinon l'animation n'est pas fluide
        Timer.scheduledTimer(withTimeInterval: TimeInterval(0.5), repeats: false) { _ in
            self.stop_button!.isEnabled = true
            self.detail_view_controller?.enableButtons(false)
            self.add_button!.isEnabled = false
            self.update_button!.isEnabled = false
            self.updateLocalNodeAndGateways()
        }
    }

    public func setTitle(_ title: String) {
        navigationItem.title = title
    }

    @IBAction func debug_pressed(_ sender: Any) {
        print("debug pressed")
        // for iPhone (pas d'effet sur iPad), make the detail view controller visible
        splitViewController?.showDetailViewController(detail_navigation_controller!, sender: nil)
    }


    public func applicationWillResignActive() {
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        tableView.backgroundColor = COLORS.standard_background
        // Le refresh control ne se rafraichit plus quand on revient sur cette vue depuis une autre vue, donc on force un arrêt
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Display an Edit button in the navigation bar for this view controller.
        navigationItem.rightBarButtonItem = editButtonItem
        
        // Add a refresh control
        refreshControl = UIRefreshControl()
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let cell = self.tableView.dequeueReusableHeaderFooterView(withIdentifier: "MasterSectionHeader")
        return cell
    }

    private func updateLocalNodeAndGateways() {
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.reloadData()
        updateLocalNodeAndGateways()
//        navigationController!.tabBarController?.tabBar.barTintColor = COLORS.top_down_background
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

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 0
    }

    // cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath) as! DeviceCell

        cell.layer.shadowColor = UIColor.clear.cgColor
        
        // Create some sort of shadow
//        cell.rect1.backgroundColor = COLORS.section_background
//        cell.rect2.backgroundColor = COLORS.rect2_background

        // Couleur de fond quand on clique sur éditer pour supprimer une cellule
//        cell.backgroundColor = COLORS.standard_background

        // On supprime le changement de couleur de fond en cas de sélection via le positionnement d'une couleur de fond
//        cell.contentView.backgroundColor = COLORS.standard_background
        
        
        // Not used since the cell style is 'custom' (style set from the storyboard):
        // cell.textLabel!.text = ...

        cell.name.text = "truc"
        cell.nPorts.text = "troc"

       return cell
    }

    // didSelectRowAt
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        detail_view_controller!.node = getNode(indexPath: indexPath)
        // for iPhone (pas d'effet sur iPad), make the detail view controller visible
        splitViewController?.showDetailViewController(detail_navigation_controller!, sender: nil)

    }

    // Local gateway and Internet rows can not be removed
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let index_path = tableView.indexPathForSelectedRow!
    }
}

