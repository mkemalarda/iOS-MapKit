//
//  ViewController.swift
//  MapKitApp
//
//  Created by Mustafa Kemal ARDA on 4.08.2023.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate,CLLocationManagerDelegate {

    
    @IBOutlet weak var locationsTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var MapView: MKMapView!
    
    
    var locationManager = CLLocationManager()
    var choosenLatitude = Double()
    var choosenLongitude = Double()
    
    var choosenName = ""
    var choosenId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        MapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest   // Kullanıcının en iyi konum bilgisini alma
        locationManager.requestWhenInUseAuthorization()             // Kullanıcı sadece uygulamayı kullanırken konum bilgisini alır
        locationManager.startUpdatingLocation()                     // Kullanıcının konum bilgisini güncellemeyi başlatır
        
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(selectLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        MapView.addGestureRecognizer(gestureRecognizer)
        
        
        if choosenName != "" {
            // CoreData'dan verileri çek
            
            if let uuidString = choosenId?.uuidString {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Place")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do {
                    let results = try context.fetch(fetchRequest)
                    
                    if results.count > 0 {
                        
                        for result in results as! [NSManagedObject] {
                            
                            
                            if let name = result.value(forKey: "name") as? String {
                                annotationTitle = name
                                
                                if let note = result.value(forKey: "note") as? String {
                                    annotationSubtitle = note
                                    
                                    if let latitude = result.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = result.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotaiton = MKPointAnnotation()
                                            annotaiton.title = annotationTitle
                                            annotaiton.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotaiton.coordinate = coordinate
                                            
                                            MapView.addAnnotation(annotaiton)
                                            locationsTextField.text = annotationTitle
                                            noteTextField.text = annotationSubtitle
                                            
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            MapView.setRegion(region, animated: true)
                                             
                                        }
                                    }
                                    
                                }
                                
                            }
                
                        }
                    }
                    
                } catch {
                    print("error!")
                }
                
            }
        } else {
            
            // Yeni veri eklemeye geldi
        }
        
        let KeywordGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(hideKeyword))
        view.addGestureRecognizer(KeywordGestureRecognizer)
        
    }
    
    
    
    @objc func selectLocation(gestureRecognizer : UILongPressGestureRecognizer) {
        
        if gestureRecognizer.state == .began {
            
            let touchPoint = gestureRecognizer.location(in: MapView)
            let touchLocation = MapView.convert(touchPoint, toCoordinateFrom: MapView)
            
            choosenLatitude = touchLocation.latitude
            choosenLongitude = touchLocation.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchLocation
            annotation.title = locationsTextField.text
            annotation.subtitle = noteTextField.text
            MapView.addAnnotation(annotation)
            
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //print(locations[0].coordinate.latitude)
        //print(locations[0].coordinate.longitude)
        if choosenName == "" {
            
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: location, span: span)
            MapView.setRegion(region, animated: true)
        }
      
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .blue
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
        
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if choosenName != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkArray, error) in
                    
                if let placemark = placemarkArray {
                    if placemark.count > 0 {
                        
                        
                        let newPlacemark = MKPlacemark(placemark: placemark[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
                        
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                    
                }
            }
            
        }
        
        
        }
    @objc func hideKeyword() {
        view.endEditing(true)
    }
   
    @IBAction func saveButton(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newPlace = NSEntityDescription.insertNewObject(forEntityName: "Place", into: context)
        
        newPlace.setValue(locationsTextField.text, forKey: "name")
        newPlace.setValue(noteTextField.text, forKey: "note")
        newPlace.setValue(choosenLatitude, forKey: "latitude")
        newPlace.setValue(choosenLongitude, forKey: "longitude")
        newPlace.setValue(UUID(), forKey: "id")
        
        
        do {
            try context.save()
            print("saved")
        } catch {
            print("error!")
        }
        
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "createNewPlace"), object: nil)
        
        navigationController?.popViewController(animated: true)
        
        
        
    }
    
    
}


