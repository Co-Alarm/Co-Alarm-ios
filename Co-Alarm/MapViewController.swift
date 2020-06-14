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
    
    //위치 관련 event handler 객체
    let locationManager = CLLocationManager()
    var searchTextFieldIsHidden = true
    var bookmarkedStores: [Store] = []
    var menuViewIsHidden: Bool = true

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var adviceButton: UIButton!
    @IBOutlet weak var adviceImageView: UIImageView!
    @IBOutlet weak var bookmarkTableView: UITableView!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var reSearchButton: UIButton!
    
    // MARK: - viewDidLoad
    override func viewDidLoad() {
        
        super.viewDidLoad()
        bookmarkTableView.rowHeight = 70
        bookmarkTableView.refreshControl = UIRefreshControl()
        bookmarkTableView.refreshControl?.addTarget(self, action: #selector(handleRefreshControl), for: .valueChanged)
        bookmarkTableView.layer.cornerRadius = 10
        
        searchTextField.delegate = self
        searchTextField.returnKeyType = .search
        searchTextField.layer.cornerRadius = 6
        makeShadow(view: searchTextField)
        
        adviceImageView.layer.cornerRadius = 10
        
        refreshButton.layer.cornerRadius = 6
        makeShadow(view: refreshButton)
        
        reSearchButton.layer.cornerRadius = 6
        makeShadow(view: reSearchButton)
        
        menuView.layer.cornerRadius = 6
        menuView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        makeShadow(view: menuView)
        
        mapView.delegate = self
        mapView.showsCompass = false
        let compassButton = MKCompassButton(mapView: mapView)
        compassButton.frame.origin = CGPoint(x: 30, y: 128)
        compassButton.compassVisibility = .adaptive
        view.addSubview(compassButton)
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        //위치 업데이트 시작
        locationManager.startUpdatingLocation()
        
    }
    
    // MARK: - makeShadow
    func makeShadow(view: UIView) {
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1.0)
        view.layer.shadowOpacity = 0.2
        view.layer.shadowRadius = 4
    }
    // MARK: - myLocation
    //mapView의 region을 현위치로 설정하는 함수
    func myLocation(lat: CLLocationDegrees, lng: CLLocationDegrees, delta: Double) {
        let coordinateLocation = CLLocationCoordinate2DMake(lat, lng)
        let spanValue = MKCoordinateSpan(latitudeDelta: delta, longitudeDelta: delta)
        let locationRegion = MKCoordinateRegion(center: coordinateLocation, span: spanValue)
        mapView.setRegion(locationRegion, animated: true)
        mapView.showsUserLocation = true
    }
    
    // MARK: - presentStore
    //약국을 mapView에 나타내는 함수
    func presentStores(lat: Double, lng: Double) {
        //기존의 핀 삭제
        DispatchQueue.main.async {
            for annotation in self.mapView.annotations {
                self.mapView.removeAnnotation(annotation)
            }
        }
        //지도를 현재 사용자의 위치로 설정
        myLocation(lat: lat, lng: lng, delta: 0.01)
        //api에서 마스크 판매 정보 fetch
        NetworkController.sharedInstance.fetchStores(lat: lat, lng: lng, delta: 1000) { (stores) in
            if let stores = stores {
                for store in stores {
                    DispatchQueue.main.async {
                        //받아온 store 객체를 통해 핀 설정
                        self.setAnnotation(store: store)
                    }
                }
            } else {
                //error handling
                DispatchQueue.main.async {
                    let storeErrorAlert = UIAlertController(title:"오류", message: "약국 데이터 수집 오류", preferredStyle: .alert)
                    storeErrorAlert.addAction(UIAlertAction(title: "확인", style: .default))
                    self.present(storeErrorAlert, animated: true, completion: nil)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                        storeErrorAlert.dismiss(animated: true, completion: nil)
                    }
                }
            }
            //위치 업데이트 정지
            self.locationManager.stopUpdatingLocation()
        }
    }
    // MARK: - setAnnotation
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
    // MARK: - animateHideShow
    //view를 숨기고 보여줄 때 animation 동작하도록 하는 함수
    func animateHideShow(view: UIView) {
        if view.isHidden {
            view.alpha = 0.0
            view.isHidden = !view.isHidden
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {view.alpha = 0.8}) { (isCompleted) in
            }
        } else {
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {view.alpha = 0.0}) { (isCompleted) in
                view.isHidden = !view.isHidden
            }
        }
    }
    // MARK: - animateMenu
    //menu animation
    func animateMenuView(menuView: UIView) {
        if menuViewIsHidden {
            menuViewIsHidden = false
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseIn, animations: {
                menuView.layoutIfNeeded()
                menuView.frame = CGRect(x: menuView.frame.origin.x-190, y: menuView.frame.origin.y, width: menuView.frame.size.width, height: menuView.frame.size.height)
            }) { (isCompleted) in
            }
        } else {
            UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
                menuView.layoutIfNeeded()
                menuView.frame = CGRect(x: 315, y: 658, width: 250, height: 60)
            }) { (isCompleted) in
                self.menuViewIsHidden = true
            }
        }
    }
    
    // MARK: - @IBAction(ButtonTapped)

    //새로고침 버튼이 눌러졌을 때 실행되는 함수
    @IBAction func refreshButtonTapped(_ sender: Any) {
        searchTextField.text = ""
        //위치 업데이트 시작
        self.locationManager.startUpdatingLocation()
    }
    //이 지역에서 재검색 버튼이 눌러졌을 때 실행되는 함수
    @IBAction func researchButtonTapped(_ sender: Any) {
        //지도 상의 중앙 좌표를 기준으로 presentStores 호출
        self.presentStores(lat: mapView.centerCoordinate.latitude, lng: mapView.centerCoordinate.longitude)
    }
    
    //도움말 버튼이 눌러졌을 때 실행되는 함수
    @IBAction func adviceButtonTapped(_ sender: Any) {
        if !bookmarkTableView.isHidden {
            animateHideShow(view: bookmarkTableView)
        }
        //도움말 imageView를 animate
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
        if !adviceImageView.isHidden {
            animateHideShow(view: adviceImageView)
        }
        animateHideShow(view: bookmarkTableView)
    }
    //메뉴 버튼이 눌러졌을 때 실행되는 함수
    @IBAction func menuButtonTapped(_ sender: Any) {
        animateMenuView(menuView: self.menuView)
    }
    
    // MARK: - refreshControl Selector
    @objc func handleRefreshControl() {
        let group = DispatchGroup()
        if var tempBookmarkedStores = FileController.loadBookmarkedStores() {
            for i in 0..<tempBookmarkedStores.count {
                group.enter() //작업을 DispatchGroup에 추가
                NetworkController.sharedInstance.fetchStores(lat: tempBookmarkedStores[i].lat, lng: tempBookmarkedStores[i].lng, delta: 10) { (stores) in
                    if let fetchedStores = stores, let fetchedStore = fetchedStores.first(where: {$0.code == tempBookmarkedStores[i].code}) {
                        tempBookmarkedStores[i].remain = fetchedStore.remain
                    }
                    group.leave() //작업을 DispatchGroup에서 삭제
                }
            }
            //DispatchGroup에 더 이상 작업이 없으면 main 큐에서 실행
            group.notify(queue: .main) {
                self.bookmarkedStores = tempBookmarkedStores
                self.bookmarkTableView.reloadData()
                self.bookmarkTableView.refreshControl?.endRefreshing()
            }
            //DispatchGroup에 더 이상 작업이 없으면 global 큐에서 실행
            group.notify(queue: .global()) {
                FileController.saveBookmarkedStores(tempBookmarkedStores)
            }
        }
    }
}


// MARK: - CLLocationManagerDelegate
extension MapViewController: CLLocationManagerDelegate {
    //현위치가 업데이트 되면 실행되는 CLLocationManagerDelegate 함수
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //가장 최근의 location
        let lastLocation = locations.last
        let lat = (lastLocation?.coordinate.latitude)!, lng = (lastLocation?.coordinate.longitude)!
        //지도 위에 핀을 나타내는 함수 호출
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
    
    //annotationView안의 즐겨찾기 추가 버튼이 눌러졌을 때 실행되는 함수
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let anno = view.annotation! as! CustomPointAnnotation
        let annoButton = view.rightCalloutAccessoryView as! UIButton
        
        //annotationView 객체에 담긴 정보를 통해 즐겨찾기 테이블 뷰에 추가할 새로운 Store 객체 선언
        let bookmarkStore = Store(code: anno.code, name: anno.title!, addr: anno.addr, lat: anno.coordinate.latitude, lng: anno.coordinate.longitude, stockAt: anno.stockAt, remain: anno.remain, createdAt: anno.createdAt)
        
        //documentDirectory에 기존에 저장된 데이터가 존재하는지
        if var existBookmarks = FileController.loadBookmarkedStores() {
            //새로 저장할 Store가 기존에 저장된 데이터에 포함된다면 그것을 삭제
            if existBookmarks.contains(where: {$0.name == bookmarkStore.name}) {
                annoButton.setImage(UIImage(imageLiteralResourceName: "unfilledStar"), for: .normal)
                let deletedBookmarks = existBookmarks.filter{$0.name != bookmarkStore.name}
                FileController.saveBookmarkedStores(deletedBookmarks)
            }
            //그렇지 않다면 새로 저장할 Store 추가
            else {
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
        }
        //documentDirectory에 기존에 저장된 데이터가 존재하지 않을 경우
        else {
            annoButton.setImage(UIImage(imageLiteralResourceName: "filledStar"), for: .normal)
            let newBookmakrs: [Store] = [bookmarkStore]
            FileController.saveBookmarkedStores(newBookmakrs)
        }
    }
    
}

// MARK: - UITextFieldDelegate

extension MapViewController: UITextFieldDelegate {
    //searchTextField에서 return 키가 눌러졌을 때 실행되는 UITextFieldDelegate 함수
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let addr = textField.text, addr != "" {
            //geocode api를 통해 textField에 입력된 주소를 위도, 경도로 변환
            NetworkController.sharedInstance.fetchGeoCode(addr: addr) { (addr) in
                if let addr = addr {
                    DispatchQueue.main.async {
                        //얻어낸 위도, 경도를 기준으로 presentStores 호출
                        self.presentStores(lat: Double(addr.y)!, lng:  Double(addr.x)!)
                    }
                } else {
                    //error handling
                    DispatchQueue.main.async {
                        let geocodeErrorAlert = UIAlertController(title: "오류", message: "지역명이 잘못되었습니다.", preferredStyle: .alert)
                        geocodeErrorAlert.addAction(UIAlertAction(title: "확인", style: .default))
                        self.present(geocodeErrorAlert, animated: true, completion: nil)
                        print("parsing geocode error")
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2.0) {
                            geocodeErrorAlert.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
        }
        //textField 편집 종료
        self.view.endEditing(true)
        return true
    }
    //textField 다시 누르면 text 비우기
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        textField.text = ""
        return true
    }
    //화면을 터치하면 키보드 내려가도록
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension MapViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.bookmarkedStores.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bookmark", for: indexPath) as! BookmarkTableViewCell
        cell.storeName?.text = self.bookmarkedStores[indexPath.row].name
        switch bookmarkedStores[indexPath.row].remain {
        case "plenty":
            cell.remainLabel?.text = "100개 이상"
            cell.pinImageView.image = UIImage(imageLiteralResourceName: "green")
        case "some":
            cell.remainLabel?.text = "30개 이상 100개 미만"
            cell.pinImageView.image = UIImage(imageLiteralResourceName: "yellow")
        case "few":
            cell.remainLabel?.text = "2개 이상 30개 미만"
            cell.pinImageView.image = UIImage(imageLiteralResourceName: "red")
        case "empty":
            cell.remainLabel?.text = "1개 이하"
            cell.pinImageView.image = UIImage(imageLiteralResourceName: "gray")
        case "break":
            cell.remainLabel?.text = "판매중지"
            cell.pinImageView.image = UIImage(imageLiteralResourceName: "gray")
        case "null":
            cell.remainLabel?.text = "정보 없음"
            cell.pinImageView.image = UIImage(imageLiteralResourceName: "gray")
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

