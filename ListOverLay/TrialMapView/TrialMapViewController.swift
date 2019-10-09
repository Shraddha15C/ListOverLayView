//  Home.swift
//  EZPlant
//  Created by Shraddha Choubey on 24/09/19.
//  Copyright © 2019 Syngenta. All rights reserved.
//
import MapKit
import CoreLocation

class TrialMapViewController: UIViewController {
    
    enum ListLayOverState {
        case expanded
        case collapse
    }
    // MARK: Outlets
    
    @IBOutlet private weak var mapView: MKMapView!
    
    // MARK: - Properties
    
    private var locationManager = CLLocationManager()
    private let regionInMeters: Double = 10000
    private var listOverlayView: ListOverlayView!
    private var visualEffectView: UIVisualEffectView!
    private let listOverViewHeight: CGFloat = 500
    private let layOverHandleAreaHeight: CGFloat = 65
    private var listVisible = false
    private var nextState: ListLayOverState {
        return listVisible ? .expanded: .collapse
    }
    private var runningAnimations = [UIViewPropertyAnimator]()
    private var animationPRogressWhenInterrupted: CGFloat = 0
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.mapType = .satellite
        mapView.showsUserLocation = true
        setupCard()
        checkLocationServices()
    }
   
    // MARK: - PopLayOverViewSetUP
    
    private func setupCard() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = self.view.frame
        self.view.addSubview(visualEffectView)
        listOverlayView = ListOverlayView(nibName: "ListOverlayView", bundle: nil)
        self.addChild(listOverlayView)
        self.view.addSubview(listOverlayView.view)
        listOverlayView.view.frame = CGRect(x: 0, y: self.view.frame.height - layOverHandleAreaHeight, width: self.view.bounds.width, height: listOverViewHeight)
        listOverlayView.view.clipsToBounds = true
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(TrialMapViewController.handleOverlayViewTap(recognzier:)))
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(TrialMapViewController.handleOverlayViewPan(recognzier:)))
        
        listOverlayView.handleArea.addGestureRecognizer(tapGestureRecognizer)
        listOverlayView.handleArea.addGestureRecognizer(panGestureRecognizer)
    }
    @objc
    private func handleOverlayViewTap(recognzier: UITapGestureRecognizer) {
        switch recognzier.state {
        case .ended:
            animateTransitionIfNeeded(state: nextState, duration: 0.9)
        default:
            break
        }
    }
    @objc
    private  func handleOverlayViewPan(recognzier: UIPanGestureRecognizer) {
        switch recognzier.state {
        case .began:
            startInterativeTransition(state: nextState, duration: 0.9)
        case .changed:
            let translation = recognzier.translation(in: self.listOverlayView.handleArea)
            var fractionComplete = translation.y / listOverViewHeight
            fractionComplete = listVisible ? fractionComplete : -fractionComplete
            updateInteractiveTransition(fractionCompleted: fractionComplete)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
    }
    private func animateTransitionIfNeeded(state: ListLayOverState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            let  frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case .expanded:
                    self.listOverlayView.view.frame.origin.y = self.view.frame.height - self.listOverViewHeight
                case .collapse:
                    self.listOverlayView.view.frame.origin.y = self.view.frame.height - self.layOverHandleAreaHeight
                }
            }
            frameAnimator.addCompletion { _ in
                self.listVisible = !self.listVisible
                self.runningAnimations.removeAll()
            }
            frameAnimator.startAnimation()
            runningAnimations.append(frameAnimator)
            let cornerRadiusAnimator = UIViewPropertyAnimator(duration: duration, curve: .linear ) {
                switch state {
                case . expanded:
                    self.listOverlayView.view.layer.cornerRadius = 12
                case .collapse:
                    self.listOverlayView.view.layer.cornerRadius = 0
                }
            }
            cornerRadiusAnimator.startAnimation()
            runningAnimations.append(cornerRadiusAnimator)
            let blurAminator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) {
                switch state {
                case . expanded:
                    self.visualEffectView.effect = UIBlurEffect(style: .dark)
                case .collapse:
                    self.visualEffectView.effect = nil
                }
            }
            blurAminator.startAnimation()
            runningAnimations.append(blurAminator)
        }
    }
    private  func startInterativeTransition(state: ListLayOverState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            animateTransitionIfNeeded(state: state, duration: duration)
        }
        for animator in runningAnimations {
            animator.pauseAnimation()
            animationPRogressWhenInterrupted = animator.fractionComplete
            print("login")
        }
    }
    
    private func updateInteractiveTransition(fractionCompleted: CGFloat) {
        for animator in runningAnimations {
            animator.fractionComplete = fractionCompleted + animationPRogressWhenInterrupted
        }
    }
    
    private  func continueInteractiveTransition() {
        for animator in runningAnimations {
            animator.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        }
    }
    
    // MARK: - CLLocationManager
    
    private   func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            setupLocationManager()
            checkLocationAuthorizationStatus()
        } else {
            //show alert
        }
    }
    
    private  func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    private   func checkLocationAuthorizationStatus() {
        if  CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    private   func centerViewOnUserLocation() {
        if let location = locationManager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
            mapView.setRegion(region, animated: true)
        }
    }
    
    // Temperory code for prompting alert.
    private  func promptToSettingAlert() {
        let alertController = UIAlertController(title: "Alert", message: "Please go to Settings and turn on the location permission", preferredStyle: .alert)
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        alertController.addAction(settingsAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

// MARK: CLLocationManager Delegate

extension TrialMapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return}
        let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        let region = MKCoordinateRegion.init(center: center, latitudinalMeters: regionInMeters, longitudinalMeters: regionInMeters)
        mapView.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        checkLocationAuthorizationStatus()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
            locationManager.requestLocation()
        case .denied, .restricted:
            promptToSettingAlert()
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        default:
            print("alert")
        }
    }
    
}
extension TrialMapViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
