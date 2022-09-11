
import UIKit
import SpriteKit
import SwiftUI

@MainActor
class DetailViewController: UIViewController {
    public var master_view_controller: MasterViewController?
    
//    private var chart_node : SKChartNode?
//    private var scene_delegate : MySKSceneDelegate?

    public let ts = TimeSeries()
    
    @IBOutlet weak var view1: SKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    // called by MasterViewController when the user selects an address
    public func addressSelected(_ address: IPAddress, _ buttons_enabled: Bool) {
    }
    
    public func enableButtons(_ state: Bool) {
    }

    public func updateDetailsIfNodeDisplayed(_ node: Node, _ buttons_enabled: Bool) {
    }

    public func findNodeFromAddress(_ address: IPAddress) -> Node? {
        return nil
    }
    
    override func viewDidAppear(_ animated: Bool) {
    }

    override func viewDidDisappear(_ animated: Bool) {
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    }
    
    
    
}
