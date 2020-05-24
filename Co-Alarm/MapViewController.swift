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
    var bookmarkedStores: [Store] = []

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var adviceButton: UIButton!
    @IBOutlet weak var adviceImageView: UIImageView!
    @IBOutlet weak var bookmarkTableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bookmarkTableView.rowHeight = 70
        bookmarkTableView.refreshControl = UIRefreshControl()
        bookmarkTableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        adviceImageView.layer.cornerRadius = 5
        bookmarkTableView.layer.cornerRadius = 5
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    @objc func handleRefreshControl() {
        print("Refresh")
        let group = DispatchGroup()
        if let tempBookmarkedStores = FileController.loadBookmarkedStores() {
            for var tempBookmarkedStore in tempBookmarkedStores {
                group.enter() //작업을 group에 추가
                NetworkController.sharedInstance.fetchStores(lat: tempBookmarkedStore.lat, lng: tempBookmarkedStore.lng, delta: 10) { (stores) in
                    if let fetchedStores = stores, let fetchedStore = fetchedStores.first(where: {$0.code == tempBookmarkedStore.code}) {
                        tempBookmarkedStore.remain = fetchedStore.remain
                    }
                    group.leave() //작업을 group에서 삭제
                }
            }
            group.notify(queue: .main) {
                print("reload")
                self.bookmarkedStores = tempBookmarkedStores
                self.bookmarkTableView.reloadData()
                self.bookmarkTableView.refreshControl?.endRefreshing()
            }
            group.notify(queue: .global()) {
                print("save")
                FileController.saveBookmarkedStores(self.bookmarkedStores)
            }
        }
    }
    
    //mapView의 region을 현위치로 설정하는 함수
    func myLocation(lat: CLLocationDegrees, lng: CLLocationDegrees, delta: Double) {
        let coordinateLocation = CLLocationCoordinate2DMake(lat, lng)
        let spanValue = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        let locationRegion = MKCoordinateRegion(center: coordinateLocation, span: spanValue)
        mapView.setRegion(locationRegion, animated: true)
        mapView.showsUserLocation = true
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
            annotation.code = store.code
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
    
    //view를 숨기고 보여줄 때 animation 동작하도록 하는 함수
    func animateHideShow(view: UIView) {
        if view.isHidden {
            view.alpha = 0.0
            view.isHidden = !view.isHidden
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {view.alpha = 1.0}) { (isCompleted) in
            }
        } else {
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {view.alpha = 0.0}) { (isCompleted) in
                view.isHidden = !view.isHidden
            }
        }
    }
    // MARK: - @IBAction(ButtonTapped)
    
    //검색 버튼이 눌러졌을 때 실행되는 함수
    @IBAction func searchButtonTapped(_ sender: Any) {
        animateHideShow(view: self.searchTextField)
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
    //도움말 버튼이 눌러졌을 때 실행되는 함수
    @IBAction func adviceButtonTapped(_ sender: Any) {
        animateHideShow(view: adviceImageView)
    }
    //즐겨찾기 버튼이 눌러졌을 때 실행되는 함수
    @IBAction func bookmarkButtonTapped(_ sender: Any) {
        if let tempBookmarkedStores = FileController.loadBookmarkedStores() {
                       self.bookmarkedStores = tempBookmarkedStores
                       DispatchQueue.main.async {
                           self.bookmarkTableView.reloadData()
                       }
                   }
        animateHideShow(view: bookmarkTableView)
    }
}

// MARK: - CLLocationManagerDelegate

extension MapViewController: CLLocationManagerDelegate {
    //현위치가 업데이트 되면 실행하는 CLLocationManagerDelegate 함수
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLocation = locations.last
        let lat = (lastLocation?.coordinate.latitude)!, lng = (lastLocation?.coordinate.longitude)!
        presentStores(lat: lat, lng: lng)
    }
}

// MARK: - MKMapViewDelegate

extension MapViewController: MKMapViewDelegate {
    
    //custom annotationView를 생성하는 MKMapViewDelegate 함수
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "anno") ?? MKAnnotationView(annotation: annotation, reuseIdentifier: "anno")
        let rightButton = UIButton(type: .contactAdd)
        if let existBookmarks = FileController.loadBookmarkedStores() {
            let hadSame = existBookmarks.contains{$0.name == annotation.title}
            let btnImgName = hadSame ? "filledStar" : "unfilledStar"
            rightButton.setImage(UIImage(imageLiteralResourceName: btnImgName), for: .normal)
        } else { //documentDirectory에 처음 저장할 때
            rightButton.setImage(UIImage(imageLiteralResourceName: "unfilledStar"), for: .normal)
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
        
        let bookmarkStore = Store(code: anno.code, name: anno.title!, addr: anno.addr, lat: anno.coordinate.latitude, lng: anno.coordinate.longitude, stockAt: anno.stockAt, remain: anno.remain, createdAt: anno.createdAt)
        
        if var existBookmarks = FileController.loadBookmarkedStores() {
            
            let hadSame = existBookmarks.contains{$0.name == bookmarkStore.name}
            
            if hadSame {
                annoButton.setImage(UIImage(imageLiteralResourceName: "unfilledStar"), for: .normal)
                let deletedBookmarks = existBookmarks.filter{$0.name != bookmarkStore.name}
                FileController.saveBookmarkedStores(deletedBookmarks)
            } else {
                if existBookmarks.count >= 5 {
                    let tooManyBookmarksAlert = UIAlertController(title:"", message: "즐겨찾기는 5개까지 등록 가능합니다", preferredStyle: .alert)
                    tooManyBookmarksAlert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(tooManyBookmarksAlert, animated: true, completion: nil)
                } else {
                    annoButton.setImage(UIImage(imageLiteralResourceName: "filledStar"), for: .normal)
                    existBookmarks.append(bookmarkStore)
                    FileController.saveBookmarkedStores(existBookmarks)
                }
            }
        } else { //documentDirectory에 처음 저장할 때
            annoButton.setImage(UIImage(imageLiteralResourceName: "filledStar"), for: .normal)
            let newBookmakrs: [Store] = [bookmarkStore]
            FileController.saveBookmarkedStores(newBookmakrs)
        }
    }
}

// MARK: - UITextFieldDelegate

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

// MARK: - UITableViewDelegate & UITableViewDataSource
extension MapViewController : UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.bookmarkedStores.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bookmark", for: indexPath)
        cell.textLabel?.text = self.bookmarkedStores[indexPath.row].name
        switch bookmarkedStores[indexPath.row].remain {
        case "plenty":
            cell.detailTextLabel?.text = "100개 이상"
        case "some":
            cell.detailTextLabel?.text = "30개 이상 100개 미만"
        case "few":
            cell.detailTextLabel?.text = "2개 이상 30개 미만"
        case "empty":
            cell.detailTextLabel?.text = "1개 이하"
        case "break":
            cell.detailTextLabel?.text = "판매중지"
        case "null":
            cell.detailTextLabel?.text = "정보 없음"
        default:
            break
        }
        return cell
    }
    // Override to support conditional editing of the table view.
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    
    // Override to support editing the table view.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            
            // Delete the row from the data source
            let deletedStore = bookmarkedStores[indexPath.row]
            bookmarkedStores.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
            FileController.saveBookmarkedStores(bookmarkedStores)
            
            //삭제된 약국의 annotationView에서 채워진 별표를 빈 별표로 만든다
            for a in self.mapView.annotations {
                if a.title == deletedStore.name {
                    let v = mapView.view(for: a)
                    let btn = v?.rightCalloutAccessoryView as! UIButton
                    btn.setImage(UIImage(imageLiteralResourceName: "unfilledStar"), for: .normal)
                }
            }
        }
    }
    
    
}
