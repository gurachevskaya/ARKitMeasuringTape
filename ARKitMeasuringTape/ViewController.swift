//
//  ViewController.swift
//  ARKitMeasuringTape
//
//  Created by Sai Sandeep on 17/08/17.
//  Copyright © 2017 Sai Sandeep. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

final class ViewController: UIViewController, ARSCNViewDelegate, CLLocationManagerDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var grids = [Grid]()
    
    var focusSquare = FocusSquare()
    
    var dragOnInfinitePlanesEnabled = false
    
    let distanceLabel = UILabel()
    let addressLabel = UILabel()

    var startPoint : SCNVector3? = nil
    var endPoint : SCNVector3? = nil
    
    let locationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    let locationHelper = LocationHelper()
    var userLocation = CLLocation()
    var userHeading = CLLocationDirection()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        configLocationManager()
        
        setupFocusSquare()
        addDistanceLabel()
        addAddressLabel()
    }
    
    private func configLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingHeading()
    }
    
    private func addDistanceLabel() {
        let margins = sceneView.layoutMarginsGuide
        sceneView.addSubview(distanceLabel)
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 10.0).isActive = true
        distanceLabel.topAnchor.constraint(equalTo: margins.topAnchor, constant: 10.0).isActive = true
        distanceLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        distanceLabel.textColor = UIColor.white
        distanceLabel.text = "Distance = ??"
    }
    
    private func addAddressLabel() {
        let margins = sceneView.layoutMarginsGuide
        sceneView.addSubview(addressLabel)
        addressLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: 10.0).isActive = true
        addressLabel.topAnchor.constraint(equalTo: distanceLabel.bottomAnchor, constant: 10.0).isActive = true
        addressLabel.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 10.0).isActive = true
        addressLabel.heightAnchor.constraint(equalToConstant: 50).isActive = true
        addressLabel.textColor = UIColor.white
        addressLabel.numberOfLines = 0
        addressLabel.text = "Address = ??"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        
        configuration.planeDetection = .vertical
        sceneView.showsStatistics = true
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    private func setupFocusSquare() {
        focusSquare.unhide()
        focusSquare.removeFromParentNode()
        sceneView.scene.rootNode.addChildNode(focusSquare)
    }
    
    private func updateFocusSquare() {
        let (worldPosition, planeAnchor, _) = worldPositionFromScreenPosition(view.center, objectPos: focusSquare.position)
        if let worldPosition = worldPosition {
            focusSquare.update(for: worldPosition, planeAnchor: planeAnchor, camera: sceneView.session.currentFrame?.camera)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let results = sceneView.hitTest(touch.location(in: sceneView), types: [ARHitTestResult.ResultType.featurePoint] )
            
            if let anchor = results.first {
                
                let hitPointPosition = SCNVector3.positionFromTransform(anchor.worldTransform)
                
                if endPoint == nil {
                    for child in sceneView.scene.rootNode.childNodes {
                        if child.name == "Start" || child.name == "End" {
                            child.removeFromParentNode()
                            distanceLabel.text = "Distance = ??"
                        }
                    }
                }
                
                endPoint = hitPointPosition
                let node = createCrossNode(size: 0.01, color:UIColor.red, horizontal: false)
                node.position = endPoint!
                node.name = "End"
                sceneView.scene.rootNode.addChildNode(node)
                
                if endPoint != nil, startPoint != nil {
                    setupFocusSquare()
                    let distance = self.getDistanceBetween(startPoint: startPoint!, endPoint: endPoint!)
                    distanceLabel.text = String(format: "Distance(Approx) = %.2f cm",distance! * 100)
                    endPoint = nil
                    
                    let testDistance = 180.0
//                    findAddress(distance ?? 0)
                    findAddress(testDistance)
                }
            }
        }
    }
    
    private func findAddress(_ distance: Double) {
        let coordinates = locationHelper.coordinates(startingCoordinates: userLocation.coordinate, atDistance: distance, atAngle: userHeading)
        
        let destinationLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
        
        geocoder.reverseGeocodeLocation(destinationLocation, completionHandler: { [weak self] (placemarks, error) in
            if error == nil {
                let firstLocation = placemarks?[0]
                print(firstLocation)
                self?.addressLabel.text = firstLocation?.description
            }
            else {
                // An error occurred during geocoding.
                self?.addressLabel.text = error?.localizedDescription
            }
        })
    }
  
    private func getDistanceBetween(startPoint: SCNVector3, endPoint: SCNVector3) -> Double? {
        var distance : Double? = nil
        let x = powf((endPoint.x - startPoint.x), 2.0)
        let y = powf((endPoint.y - startPoint.y), 2.0)
        let z = powf((endPoint.z - startPoint.z), 2.0)
        
        distance = sqrt(Double(x + y + z))
        return distance
    }
    
    // MARK: ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.updateFocusSquare()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, willRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let orientation = SCNVector3(-transform.m31, -transform.m32, transform.m33)
        let location = SCNVector3(transform.m41, transform.m42, transform.m43)
        let currentPositionOfCamera = orientation + location
        
        startPoint = currentPositionOfCamera
    }
    
    
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//        let grid = Grid(anchor: anchor as! ARPlaneAnchor)
//        self.grids.append(grid)
//        node.addChildNode(grid)
//    }
//
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        let grid = self.grids.filter { grid in
//            return grid.anchor.identifier == anchor.identifier
//        }.first
//
//        guard let foundGrid = grid else {
//            return
//        }
//
//        foundGrid.update(anchor: anchor as! ARPlaneAnchor)
//    }
    
    //MARK: CLLocationManager
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        userHeading = newHeading.magneticHeading
    }
       
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            userLocation = location
        }
        else {
            // No location was available.
            print("No location was available")
        }
    }
}

extension ViewController {
    
    func worldPositionFromScreenPosition(_ position: CGPoint,
                                         objectPos: SCNVector3?,
                                         infinitePlane: Bool = false) -> (position: SCNVector3?, planeAnchor: ARPlaneAnchor?, hitAPlane: Bool) {
        
        // -------------------------------------------------------------------------------
        // 1. Always do a hit test against exisiting plane anchors first.
        //    (If any such anchors exist & only within their extents.)
        
        let planeHitTestResults = sceneView.hitTest(position, types: .existingPlaneUsingExtent)
        if let result = planeHitTestResults.first {
            
            let planeHitTestPosition = SCNVector3.positionFromTransform(result.worldTransform)
            let planeAnchor = result.anchor
            
            // Return immediately - this is the best possible outcome.
            return (planeHitTestPosition, planeAnchor as? ARPlaneAnchor, true)
        }
        
        // -------------------------------------------------------------------------------
        // 2. Collect more information about the environment by hit testing against
        //    the feature point cloud, but do not return the result yet.
        
        var featureHitTestPosition: SCNVector3?
        var highQualityFeatureHitTestResult = false
        
        let highQualityfeatureHitTestResults = sceneView.hitTestWithFeatures(position, coneOpeningAngleInDegrees: 18, minDistance: 1, maxDistance: 1000)

        
        if !highQualityfeatureHitTestResults.isEmpty {
            let result = highQualityfeatureHitTestResults[0]
            featureHitTestPosition = result.position
            highQualityFeatureHitTestResult = true
        }
        
        // -------------------------------------------------------------------------------
        // 3. If desired or necessary (no good feature hit test result): Hit test
        //    against an infinite, horizontal plane (ignoring the real world).
        
        if (infinitePlane && dragOnInfinitePlanesEnabled) || !highQualityFeatureHitTestResult {
            
            let pointOnPlane = objectPos ?? SCNVector3Zero
            
            let pointOnInfinitePlane = sceneView.hitTestWithInfiniteHorizontalPlane(position, pointOnPlane)
            if pointOnInfinitePlane != nil {
                return (pointOnInfinitePlane, nil, true)
            }
        }
        
        // -------------------------------------------------------------------------------
        // 4. If available, return the result of the hit test against high quality
        //    features if the hit tests against infinite planes were skipped or no
        //    infinite plane was hit.
        
        if highQualityFeatureHitTestResult {
            return (featureHitTestPosition, nil, false)
        }
        
        // -------------------------------------------------------------------------------
        // 5. As a last resort, perform a second, unfiltered hit test against features.
        //    If there are no features in the scene, the result returned here will be nil.
        
        let unfilteredFeatureHitTestResults = sceneView.hitTestWithFeatures(position)
        if !unfilteredFeatureHitTestResults.isEmpty {
            let result = unfilteredFeatureHitTestResults[0]
            return (result.position, nil, false)
        }
        
        return (nil, nil, false)
    }
}

