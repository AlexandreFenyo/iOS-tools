# DataModels

## Network nodes

@MainActor
class DBMaster {
    static let shared = DBMaster()
    var sections: [SectionType : ModelSection]
    private(set) var nodes: Set<Node>
    private(set) var networks: Set<IPNetwork>
...

## DiscoveredPortsModel

@MainActor
class DiscoveredPortsModel: ObservableObject {
    static let shared = DiscoveredPortsModel()
    @Published var discovered_ports = [DiscoveredPort]()
...



## Interman3DModel

@MainActor
public class Interman3DModel: ObservableObject {
    static let shared = Interman3DModel()
    public var scene = SCNScene(named: "Interman 3D Scene.scn")!
    private var broadcasts = Set<Broadcast3D>()
    private var b3d_hosts: [B3DHost]
    private var node_to_b3d_host = [Node : B3DHost]()
    private var scanned_IPs = Set<IPAddress>()
    private var scheduled_text_update_counter = 0
...

