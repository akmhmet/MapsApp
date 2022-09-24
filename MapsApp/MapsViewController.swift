import UIKit
import MapKit
import CoreLocation
import CoreData
class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    var locationManager = CLLocationManager()
    var selectedLatitude = Double()
    var selectedLongitude = Double()
    var selectedName = ""
    var selectedId : UUID?
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double()
    var annotationLongutide = Double()
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(locationSelect(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration = 2
        mapView.addGestureRecognizer(gestureRecognizer)
        if selectedName != "" {
            if let uuidString = selectedId?.uuidString{
                let context = appDelegate.persistentContainer.viewContext
                let fectRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
                fectRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fectRequest.returnsObjectsAsFaults = false
                do{
                    let results = try context.fetch(fectRequest)
                    if results.count > 0 {
                        for result in results as! [NSManagedObject]{
                            if let name = result.value(forKey: "name") as? String{
                                annotationTitle = name
                                if let note = result.value(forKey: "note") as? String{
                                    annotationSubTitle = note
                                    if let longitude = result.value(forKey: "longitude") as? Double{
                                        annotationLongutide = longitude
                                        if let latitude = result.value(forKey: "latitude") as? Double{
                                            annotationLatitude = latitude
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubTitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongutide)
                                            annotation.coordinate = coordinate
                                            mapView.addAnnotation(annotation)
                                            titleTextField.text = annotationTitle
                                            noteTextField.text = annotationSubTitle
                                            locationManager.stopUpdatingLocation()
                                            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }catch{
                    print("hata")
                }
            }
        }
    }
    @objc func locationSelect(gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: mapView)
            let touchedCoordinate = mapView.convert(touchedPoint, toCoordinateFrom: mapView)
            selectedLatitude = touchedCoordinate.latitude
            selectedLongitude = touchedCoordinate.longitude
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinate
            annotation.title = titleTextField.text
            annotation.subtitle = noteTextField.text
            mapView.addAnnotation(annotation)
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedName == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        }
    }
    @IBAction func saveButtonClicked(_ sender: Any) {
        let context = appDelegate.persistentContainer.viewContext
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "Location", into: context)
        newLocation.setValue(UUID(), forKey: "id")
        newLocation.setValue(titleTextField.text, forKey: "name")
        newLocation.setValue(noteTextField.text, forKey: "note")
        newLocation.setValue(selectedLatitude, forKey: "latitude")
        newLocation.setValue(selectedLongitude, forKey: "longitude")
        do {
            try context.save()
        }
        catch{
            print("hata")
        }
        NotificationCenter.default.post(name: NSNotification.Name("newLocationAddet"), object: nil)
        navigationController?.popViewController(animated: true)
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation{
            return nil
        }
        let useId = "myAnnotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: useId)
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: useId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .blue
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != ""{
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongutide)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { (placemarkArray, error) in
                if let placemarks = placemarkArray {
                    if placemarks.count > 0{
                        let newPlacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: newPlacemark)
                        item.name = self.annotationTitle
                        let launchOption = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                        item.openInMaps(launchOptions: launchOption)
                    }
                }
            }
        }
    }
}

