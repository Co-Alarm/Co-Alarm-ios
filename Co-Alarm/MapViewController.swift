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
        
        //BookmarkTableViewController에서 즐겨찾기된 약국을 지우는 걸 보고있는 옵저버 생성
        NotificationCenter.default.addObserver(self, selector: #selector(notificationReceived(notification:)), name: Notification.Name("deleteBookmark"), object: nil)
    }
    
    //옵저버가 약국이 지워진 걸 확인하고 실행하는 selector 함수
    @objc func notificationReceived(notification: Notification) {
        guard let userInfo = notification.userInfo as? [String : Store], let deletedStore = userInfo["deletedStore"] else {return}
        for a in mapView.annotations {
            if a.title == deletedStore.name {
                let v = mapView.view(for: a)
                let btn = v?.rightCalloutAccessoryView as! UIButton
                btn.setImage(UIImage(imageLiteralResourceName: "unfilledStar"), for: .normal)
            }
        }
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
                        self.setAnnotation(store: store)
                        if store.name == "소망약국"{
                            print(store)
                        }
                    }
                }
            } else {
                DispatchQueue.main.async {
                    let storeErrorAlert = UIAlertController(title:"오류", message: "약국 데이터 수집 오류", preferredStyle: .alert)
                    storeErrorAlert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(storeErrorAlert, animated: true, completion: nil)
                    print("parsing store error")
                }
            }
            self.locationManager.stopUpdatingLocation()
        }
    }
    
    //mapView에 annotation을 추가하는 함수
    func setAnnotation(store: Store) {
        if let remain = store.remain {
            let annotation = CustomPointAnnotation()
            annotation.coordinate.latitude = store.lat
            annotation.coordinate.longitude = store.lng
            annotation.title = store.name
            annotation.addr = store.addr
            annotation.stockAt = store.stockAt
            annotation.createdAt = store.createdAt
            annotation.remain = remain
            switch remain {
            case "plenty":
                annotation.subtitle = "100개 이상"
                annotation.imageName = "green"
            case "some":
                annotation.subtitle = "30개 이상 100개 미만"
                annotation.imageName = "yellow"
            case "few":
                annotation.subtitle = "2개 이상 30개 미만"
                annotation.imageName = "red"
            case "empty":
                annotation.subtitle = "1개 이하"
                annotation.imageName = "gray"
            case "break":
                annotation.subtitle = "판매중지"
                annotation.imageName = "gray"
            case "null":
                annotation.subtitle = "정보 없음"
                annotation.imageName = "gray"
            default:
                break
            }
            mapView.addAnnotation(annotation)

        }
    }
    //검색 버튼이 눌러졌을 때 실행되는 함수
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
    //새로고침 버튼이 눌러졌을 때 실행되는 함수
    @IBAction func refreshButtonTapped(_ sender: Any) {
        searchTextField.text = ""
        self.locationManager.startUpdatingLocation()
    }
    //이 지역에서 재검색 버튼이 눌러졌을 때 실행되는 함수
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
        let rightButton = UIButton(type: .contactAdd)
        if let existBookmarks = FileController.loadBookmarkedStores() {
            let hadSame = existBookmarks.contains{$0.name == annotation.title}
            let btnImgName = hadSame ? "filledStar" : "unfilledStar"
            rightButton.setImage(UIImage(imageLiteralResourceName: btnImgName), for: .normal)
        }
        annotationView.canShowCallout = true
        annotationView.rightCalloutAccessoryView = rightButton
        if annotation is MKUserLocation {
            return nil
        } else if annotation is MKPointAnnotation{
            //CustomPointAnnotation 인스턴스로 currentAnno 만듬
            let currentAnno = annotation as! CustomPointAnnotation
            if(currentAnno.imageName != "") {
                annotationView.image = UIImage(imageLiteralResourceName: currentAnno.imageName)
            }
            return annotationView
        } else {
            return nil
        }
    }
    //annotationView안의 버튼이 눌러졌을 때 실행되는 함수
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let anno = view.annotation! as! CustomPointAnnotation
        let annoButton = view.rightCalloutAccessoryView as! UIButton
        
        let bookmarkStore = Store(name: anno.title!, addr: anno.addr, lat: anno.coordinate.latitude, lng: anno.coordinate.longitude, stockAt: anno.stockAt, remain: anno.remain, createdAt: anno.createdAt)
        
        if var existBookmarks = FileController.loadBookmarkedStores() {
            
            let hadSame = existBookmarks.contains{$0.name == bookmarkStore.name}
            
            if hadSame {
                annoButton.setImage(UIImage(imageLiteralResourceName: "unfilledStar"), for: .normal)
                let deletedBookmarks = existBookmarks.filter{$0.name != bookmarkStore.name}
                FileController.saveBookmarkedStores(deletedBookmarks)
            } else {
                annoButton.setImage(UIImage(imageLiteralResourceName: "filledStar"), for: .normal)
                existBookmarks.append(bookmarkStore)
                FileController.saveBookmarkedStores(existBookmarks)
            }
        }
    }
}


extension MapViewController: UITextFieldDelegate {
    //searchTextField에서 return 키가 눌러졌을 때 실행하는 UITextFieldDelegate 함수
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let addr = textField.text, addr != "" {
            NetworkController.sharedInstance.fetchGeoCode(addr: addr) { (addr) in
                if let addr = addr {
                    DispatchQueue.main.async {
                        self.presentStores(lat: Double(addr.y)!, lng:  Double(addr.x)!)
                    }
                } else {
                    DispatchQueue.main.async {
                        let geocodeErrorAlert = UIAlertController(title: "오류", message: "지역명이 잘못되었습니다.", preferredStyle: .alert)
                        geocodeErrorAlert.addAction(UIAlertAction(title: "확인", style: .default))
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

//MKPointAnnotation 객체에 주소와 이미지 파일 이름을 담기 위해 자식클래스를 만듬
class CustomPointAnnotation: MKPointAnnotation {
    var addr: String = ""
    var imageName: String = ""
    var stockAt: String? = ""
    var createdAt: String? = ""
    var remain: String? = ""
}
