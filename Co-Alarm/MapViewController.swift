//
//  MapViewController.swift
//  Co-Alarm
//
//  Created by woogie on 2020/04/04.
//  Copyright © 2020 SodaCoffee. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {
    
    let locationManager = CLLocationManager()
    var searchTextFieldIsHidden = true

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.isHidden = searchTextFieldIsHidden
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    //mapView의 region을 현위치로 설정하는 함수
    func myLocation(lat: CLLocationDegrees, lng: CLLocationDegrees, delta: Double) {
        let coordinateLocation = CLLocationCoordinate2DMake(lat, lng)
        let spanValue = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        let locationRegion = MKCoordinateRegion(center: coordinateLocation, span: spanValue)
        mapView.setRegion(locationRegion, animated: true)
    }
    
    //약국을 mapView에 나타내는 함수
    func presentStores(lat: Double, lng: Double) {
        DispatchQueue.main.async {
            for annotation in self.mapView.annotations {
                self.mapView.removeAnnotation(annotation)
            }
        }
        myLocation(lat: lat, lng: lng, delta: 0.01)
        NetworkController.sharedInstance.fetchStores(lat: lat, lng: lng, delta: 1000) { (stores) in
            if let stores = stores {
                for store in stores {
                    DispatchQueue.main.async {
                        self.setAnnotation(lat: store.lat, lng: store.lng, name: store.name, remain: store.remain ?? "null")
                    }
                }
            } else {
                let storeErrorAlert = UIAlertController(title:"오류", message: "약국 데이터 수집 오류", preferredStyle: .alert)
                storeErrorAlert.addAction(UIAlertAction(title: "확인", style: .default))
                DispatchQueue.main.async {
                    self.present(storeErrorAlert, animated: true, completion: nil)
                    print("parsing store error")
                }
            }
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    //mapView에 annotation을 추가하는 함수
    func setAnnotation(lat: CLLocationDegrees, lng: CLLocationDegrees, name: String, remain: String) {
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = lat
        annotation.coordinate.longitude = lng
        annotation.title = name
        switch remain {
        case "plenty":
            annotation.subtitle = "100개 이상"
        case "some":
            annotation.subtitle = "30개 이상 100개 미만"
        case "few":
            annotation.subtitle = "2개 이상 30개 미만"
        case "empty":
            annotation.subtitle = "1개 이하"
        case "break":
            annotation.subtitle = "판매중지"
        case "null":
            annotation.subtitle = "정보 없음"
        default:
            break
        }
        mapView.addAnnotation(annotation)
    }
    
    @IBAction func searchButtonTapped(_ sender: Any) {
        if searchTextFieldIsHidden {
            self.searchTextField.alpha = 0.0
            self.searchTextField.isHidden = false
            searchTextFieldIsHidden = false
            
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {self.searchTextField.alpha = 1.0}) { (isCompleted) in
            }
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {self.searchTextField.alpha = 0.0}) { (isCompleted) in
                self.searchTextField.isHidden = true
                self.searchTextFieldIsHidden = true
            }
        }
    }
    
    @IBAction func refreshButtonTapped(_ sender: Any) {
        searchTextField.text = ""
        self.locationManager.startUpdatingLocation()
    }
    @IBAction func researchButtonTapped(_ sender: Any) {
        self.presentStores(lat: mapView.centerCoordinate.latitude, lng: mapView.centerCoordinate.longitude)
    }
}


extension MapViewController: CLLocationManagerDelegate {
    //현위치가 업데이트 되면 실행하는 CLLocationManagerDelegate 함수
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last
        let lat = (lastLocation?.coordinate.latitude)!, lng = (lastLocation?.coordinate.longitude)!
        presentStores(lat: lat, lng: lng)
    }
}

extension MapViewController: MKMapViewDelegate {
    //custom annotationView를 생성하는 MKMapViewDelegate 함수
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "anno") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "anno")
        annotationView.canShowCallout = true
        if annotation is MKUserLocation {
            return nil
        } else if annotation is MKPointAnnotation{
            switch annotation.subtitle {
            case "100개 이상":
                annotationView.image = UIImage(imageLiteralResourceName: "green")
            case "30개 이상 100개 미만":
                annotationView.image = UIImage(imageLiteralResourceName: "yellow")
            case "2개 이상 30개 미만":
                annotationView.image = UIImage(imageLiteralResourceName: "red")
            case "1개 이하":
                annotationView.image = UIImage(imageLiteralResourceName: "gray")
            case "판매중지":
                annotationView.image = UIImage(imageLiteralResourceName: "gray")
            default:
                break
            }
            
            return annotationView
        } else {
            return nil
        }
    }
}


extension MapViewController: UITextFieldDelegate {
    //searchTextField에서 return 키가 눌러졌을 때 실행하는 UITextFieldDelegate 함수
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let addr = textField.text, addr != "" {
            NetworkController.sharedInstance.fetchGeoCode(addr: addr) { (addr) in
                if let addr = addr {
                    print(Double(addr.y)!)
                    print(Double(addr.x)!)
                    DispatchQueue.main.async {
                        self.presentStores(lat: Double(addr.y)!, lng:  Double(addr.x)!)
                    }
                } else {
                    let geocodeErrorAlert = UIAlertController(title: "오류", message: "지역명이 잘못되었습니다.", preferredStyle: .alert)
                    geocodeErrorAlert.addAction(UIAlertAction(title: "확인", style: .default))
                    DispatchQueue.main.async {
                        self.present(geocodeErrorAlert, animated: true, completion: nil)
                        print("parsing geocode error")
                    }
                }
            }
        }
        textField.text = ""
        self.view.endEditing(true)
        return true
    }

}
