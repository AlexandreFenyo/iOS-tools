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
    public weak var master_view_controller: MasterViewController?
    
    private var camera_start_angle: Float = 0
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
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(IntermanViewController.handlePan(_:))))
        // This creates a strong ref to the target
        view.addGestureRecognizer(UIPinchGestureRecognizer(target: self, action: #selector(IntermanViewController.handlePinch(_:))))
    }
    
    @objc
    func handleTap(_ gesture: UITapGestureRecognizer) {
        print("\(#function)")
        
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

        let angle: Float
        switch point.x {
        case -Double.infinity..<0:
            angle = Float(atan(-point.y / -point.x) + .pi)
        case 0:
            angle = 0
        default:
            angle = Float(atan(point.y / point.x))
        }

        if gesture.state == .began {
            camera_start_angle = hostingViewController.rootView.getCameraAngle() + angle
        } else {
            hostingViewController.rootView.rotateCamera(camera_start_angle - angle)
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
