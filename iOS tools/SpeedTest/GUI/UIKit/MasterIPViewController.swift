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
// Since we do not want to declare viewDidLoad() as @MainActor, and since it would not work declaring it nonisolated (calling super.viewDidLoad() would generate a warning), we have to declare each var and func as @MainActor.
@MainActor
class MasterIPViewController: UITableViewController {
    var master_view_controller: MasterViewController?
    var node : Node?
    var auto_select: String?

    private var loop_task: Task<(), Never>?
    
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
    
    func applicationWillResignActive() {
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.auto_select != nil {
            info_button.isEnabled = false

            var found = false
            var cnt = 0
            for n in self.node!.getV4Addresses().sorted() {
                if n.toNumericString() == self.auto_select! {
                    found = true
                    break
                }
                cnt += 1
            }
            if found == false {
                for n in self.node!.getV6Addresses().sorted() {
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
                self.master_view_controller!.addressSelected(address: addr, node: node!)
            }
            self.auto_select = nil
        } else {
            info_button.isEnabled = true

            if self.node!.getV4Addresses().count + self.node!.getV6Addresses().count > 0 && self.tableView.indexPathForSelectedRow == nil {
                let indexPath = IndexPath(row: 0, section: 0)
                self.tableView.selectRow(at: indexPath, animated: true, scrollPosition: .bottom)
                let ips = Array(self.node!.getV4Addresses().sorted()) + Array(self.node!.getV6Addresses().sorted())
                if !ips.isEmpty {
                    self.master_view_controller!.addressSelected(address: ips.first!, node: node!)
                }
            }
        }
        /*
         Task.detached(priority: .userInitiated) {
         await self.master_view_controller?.detail_view_controller?.ts.setUnits(units: .BANDWIDTH)
         await self.master_view_controller?.detail_view_controller?.ts.removeAll()
         }
         */

        loop_task?.cancel()
        loop_task = Task.detached { @MainActor in
            repeat {
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
    }
    
    // We do not use Timer.scheduledTimer() anymore but a detached task with a loop. Using scheduledTimer() would forbid us to declare viewDidLoad() as @MainActor:
    // we already know that the closure launched by Timer.scheduledTimer() will be run on the calling queue, so on the main actor, and if we were declaring viewDidLoad() as @MainActor, we would have warnings about accessing self properties incorrectly: the compiler does not know that the closure launched by Timer.scheduledTimer will be run on the main queue.
    override func viewDidLoad() {
        super.viewDidLoad()
        print("MasterIPViewController.viewDidLoad() called")
        
        // Les séparateurs par défaut sont remplacés par le double liseré (2 px + 2 px)
        // de la liste des cibles, dessiné dans cellForRowAt
        tableView.separatorStyle = .none
        
        // Uncomment the following line to preserve selection between presentations
        clearsSelectionOnViewWillAppear = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        master_view_controller?.detail_view_controller?.setButtonMasterIPHiddenState(false)
        tableView.backgroundColor = COLORS.leftpannel_bg
        // Titre par défaut tant qu'aucune activité n'a fourni de titre (setTitle)
        if navigationItem.titleView == nil {
            navigationItem.titleView = MasterViewController.makeTwoLevelTitleView(NSLocalizedString("IP List", comment: "IP List"))
        }
    }
    
    override func viewWillDisappear(_ animated : Bool) {
        super.viewWillDisappear(animated)
        master_view_controller?.detail_view_controller?.setButtonMasterIPHiddenState(true)
        if isMovingFromParent {
            master_view_controller!.addressDeselected()
        }

        loop_task?.cancel()
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
        master_view_controller?.popUp(NSLocalizedString("IP List", comment: "IP List"), NSLocalizedString("You can select another IP or launch an action on the current IP (scan TCP ports, TCP flood discard, TCP flood chargen, UDP flood or ICMP ping).", comment: "You can select another IP or launch an action on the current IP (scan TCP ports, TCP flood discard, TCP flood chargen, UDP flood or ICMP ping)."), "OK")
    }
    
    @IBAction func stop_pressed(_ sender: Any) {
        master_view_controller?.stop_pressed(sender)
    }
    
    // MARK: - UIScrollViewDelegate
    
    override func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return node!.getV4Addresses().count + node!.getV6Addresses().count
    }
    
    // Description du type d'adresse, affichée sous l'adresse elle-même
    private static func addressDescription(_ address: IPAddress) -> String {
        if let v4 = address as? IPv4Address {
            if v4.isLocal() { return NSLocalizedString("IPv4 · loopback", comment: "IP type") }
            if v4.isPrivate() { return NSLocalizedString("IPv4 · private (RFC 1918)", comment: "IP type") }
            if v4.isAutoConfig() { return NSLocalizedString("IPv4 · link-local (APIPA)", comment: "IP type") }
            if !v4.isUnicast() { return NSLocalizedString("IPv4 · multicast", comment: "IP type") }
            return NSLocalizedString("IPv4 · public", comment: "IP type")
        }
        if let v6 = address as? IPv6Address {
            if v6.toNumericString() == "::1" { return NSLocalizedString("IPv6 · loopback", comment: "IP type") }
            if v6.isLLA() { return NSLocalizedString("IPv6 · link-local", comment: "IP type") }
            if v6.isULA() { return NSLocalizedString("IPv6 · unique local (ULA)", comment: "IP type") }
            if v6.isMulticastPublic() { return NSLocalizedString("IPv6 · multicast", comment: "IP type") }
            if v6.isUnicastPublic() { return NSLocalizedString("IPv6 · global", comment: "IP type") }
            return "IPv6"
        }
        return ""
    }
    
    // cellForRowAt
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let address = (Array(node!.getV4Addresses().sorted()) + Array(node!.getV6Addresses().sorted()))[indexPath.item]
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceAddressCell", for: indexPath) as! DeviceAddressCell
        
        // Adresse en fonte à chasse fixe + type d'adresse en dessous ; les couleurs
        // suivent l'état de sélection (beige/indigo comme auparavant).
        // Le nom d'interface (scope "%en0") est retiré de l'adresse affichée et reporté
        // dans la ligne de description ("IPv6 · lien local · en0") ; la copie par le
        // menu contextuel restitue l'adresse complète, scope inclus.
        let address_str = address.toNumericString() ?? ""
        let address_parts = address_str.split(separator: "%", maxSplits: 1)
        let display_str = String(address_parts.first ?? "")
        var subtitle = MasterIPViewController.addressDescription(address)
        if address_parts.count > 1 { subtitle += " · " + String(address_parts[1]) }
        cell.configurationUpdateHandler = { cell, state in
            var content = cell.defaultContentConfiguration()
            content.text = display_str
            content.secondaryText = subtitle
            // Même police que les IPs de la liste des cibles (système 15 pt, cf. detail1
            // de DeviceCell dans le storyboard) ; semi-gras sur la ligne sélectionnée
            content.textProperties.font = UIFont.systemFont(ofSize: 15, weight: state.isSelected ? .semibold : .regular)
            content.textProperties.color = state.isSelected ? COLORS.leftpannel_ip_text_selected
                : COLORS.leftpannel_ip_text.withAlphaComponent(CGFloat(COLORS.leftpannel_ip_text_opacity))
            content.secondaryTextProperties.font = UIFont.systemFont(ofSize: 11)
            content.secondaryTextProperties.color = state.isSelected ? COLORS.standard_background
                : COLORS.leftpannel_ip_text.withAlphaComponent(0.55)
            content.textToSecondaryTextVerticalPadding = 2
            cell.contentConfiguration = content
        }
        
        cell.backgroundColor = COLORS.standard_background
        
        let bgColorView = UIView()
        bgColorView.backgroundColor = COLORS.chart_bg
        cell.selectedBackgroundView = bgColorView
        
        // Séparateur identique à celui de la liste des cibles : deux liserés de 2 px
        // (mêmes couleurs que rect1/rect2 de DeviceCell), ajoutés une seule fois par cellule.
        // Attachés à la cellule elle-même et non à contentView : l'application de
        // contentConfiguration REMPLACE la contentView (UIListContentView), ce qui
        // supprimerait des vues qui y seraient ajoutées.
        if cell.viewWithTag(1001) == nil {
            let sep1 = UIView()
            sep1.tag = 1001
            sep1.backgroundColor = COLORS.leftpannel_node_rect1_bg
            let sep2 = UIView()
            sep2.tag = 1002
            sep2.backgroundColor = COLORS.leftpannel_node_rect2_bg
            for sep in [sep1, sep2] {
                sep.translatesAutoresizingMaskIntoConstraints = false
                sep.isUserInteractionEnabled = false
                // Toujours au-dessus de la UIListContentView, quel que soit l'ordre des sous-vues
                sep.layer.zPosition = 1
                cell.addSubview(sep)
            }
            NSLayoutConstraint.activate([
                sep1.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
                sep1.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                sep1.heightAnchor.constraint(equalToConstant: 2),
                sep1.bottomAnchor.constraint(equalTo: sep2.topAnchor),
                sep2.leadingAnchor.constraint(equalTo: cell.leadingAnchor),
                sep2.trailingAnchor.constraint(equalTo: cell.trailingAnchor),
                sep2.heightAnchor.constraint(equalToConstant: 2),
                sep2.bottomAnchor.constraint(equalTo: cell.bottomAnchor)
            ])
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let address = (Array(node!.getV4Addresses().sorted()) + Array(node!.getV6Addresses().sorted()))[indexPath.item]
        master_view_controller!.addressSelected(address: address, node: node!)
    }
    
    // Appui long (iOS) ou clic droit (Mac) sur une ligne : menu proposant de copier l'adresse IP
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let address = (Array(node!.getV4Addresses().sorted()) + Array(node!.getV6Addresses().sorted()))[indexPath.item]
        guard let address_str = address.toNumericString() else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { _ in
            UIMenu(children: [
                UIAction(title: NSLocalizedString("Copy", comment: "Copy"), image: UIImage(systemName: "doc.on.doc")) { _ in
                    UIPasteboard.general.string = address_str
                }
            ])
        }
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
}
