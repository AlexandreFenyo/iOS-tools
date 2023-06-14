//
//  TracesViewController.swift
//  iOS tools
//
//  Created by Alexandre Fenyo on 26/10/2021.
//  Copyright © 2021 Alexandre Fenyo. All rights reserved.
//

import SwiftUI

// a noter : view.frame inclut la bandeau du bas, si on veut retirer le bandeau on utilise les valeurs de view.safeAreaInsets

@MainActor
class IntermanViewController : UIViewController {
    weak var master_view_controller: MasterViewController?
    
    private var camera_start_angle: Float = 0
    private var pan_start_angle: Float = 0
    private var start_scale: Float = 0

    private var hostingViewController = {
        let hostingController = UIHostingController(rootView: Interman3DSwiftUIView())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }()
    
    // Not used - in case we use Interman2DSwiftUIView
    private func make2DHostingController() -> UIHostingController<Interman2DSwiftUIView> {
        let hostingController = UIHostingController(rootView: Interman2DSwiftUIView())
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        return hostingController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addChild(hostingViewController)
        view.addSubview(hostingViewController.view)
        hostingViewController.didMove(toParent: self)
        
        NSLayoutConstraint.activate([
            hostingViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingViewController.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingViewController.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
        
        // This creates a strong ref to the target
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(IntermanViewController.handleTap(_:))))
        // This creates a strong ref to the target
        let double_tap = UITapGestureRecognizer(target: self, action: #selector(IntermanViewController.handleDoubleTap(_:)))
        double_tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(double_tap)
        // This creates a strong ref to the target
        let pan = UIPanGestureRecognizer(target: self, action: #selector(IntermanViewController.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        // This creates a strong ref to the target
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(IntermanViewController.handlePinch(_:))))
    }
    
    func setSelectedNode(_ node: Node) {
        hostingViewController.rootView.setSelectedHost(node)
    }
    
    @objc
    func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let host = hostingViewController.rootView.getTappedHost(gesture.location(in: gesture.view!)) else { return }
        guard let master_view_controller = master_view_controller else {
            print("\(#function): should not happen")
            return
        }
        
        guard let index_path = master_view_controller.getIndexPath(host.getHost()) else { return }

        print(index_path)
        
        // Simulate a tap on a TableView: https://stackoverflow.com/questions/24787098/programmatically-emulate-the-selection-in-uitableviewcontroller-in-swift
        
        // Display the Discover tab bar panel
        master_view_controller.tabBarController!.selectedIndex = 0

        // This Task lets the animation from IP target list to nodes target list been seen
        Task {
            // Simulate a tap on the node
            master_view_controller.tableView.selectRow(at: index_path, animated: true, scrollPosition: .top)
            // Useful to avoid stacking view controllers and to clear the data displayed on the right (host names, IP addresses, ...)
            master_view_controller.navigationController!.popToRootViewController(animated: true)
            // Push the MasterIPViewController
            master_view_controller.performSegue(withIdentifier: "segue to IP list", sender: nil)
        }
    }

    @objc
    func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        hostingViewController.rootView.resetCamera()
    }

    @objc
    func handlePan(_ gesture: UIPanGestureRecognizer) {
        // Note that hostingViewController.view == gesture.view!
        let _point = gesture.location(in: gesture.view!)
        let frame = gesture.view!.frame
        // Convert coordinate space (origin at the center of the screen, Ox horizontal, Oy vertical)
        let point = CGPoint(x: _point.x - frame.width / 2, y: frame.height / 2 - _point.y)

        let angle = Interman3DModel.normalizeAngle(atan2f(Float(point.y), Float(point.x)))
        
        print("handlePan(): angle: \(angle) = \(angle * 360 / (.pi * 2)) degrés")
        
        if gesture.state == .began {

//            camera_start_angle = Interman3DModel.normalizeAngle(hostingViewController.rootView.getCameraAngle() + angle)
//            print("handlePan(): camera start angle = \(camera_start_angle) = \(camera_start_angle * 360 / (.pi * 2)) degrés")
            camera_start_angle = hostingViewController.rootView.getCameraAngle()

            print("handlePan(): camera start angle = \(camera_start_angle) = \(camera_start_angle * 360 / (.pi * 2)) degrés")

            pan_start_angle = angle

        } else {
           // //            hostingViewController.rootView.rotateCamera(camera_start_angle - angle)

//            hostingViewController.rootView.rotateCamera(camera_start_angle + pan_start_angle - angle)
            print("handlePan(): get camera angle : \(hostingViewController.rootView.getCameraAngle()) = \(hostingViewController.rootView.getCameraAngle() * 360 / (.pi * 2)) degrés")
            print("handlePan(): set camera angle : \(camera_start_angle) = \(camera_start_angle * 360 / (.pi * 2)) degrés")

            hostingViewController.rootView.rotateCamera(camera_start_angle + pan_start_angle - angle)

        }
    }
    
    @objc
    func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .began {
            start_scale = hostingViewController.rootView.getCameraScaleFactor()
        }
        hostingViewController.rootView.scaleCamera(start_scale / Float(gesture.scale))
    }
}
