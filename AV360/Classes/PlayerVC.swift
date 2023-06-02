//
//  PlayerVC.swift
//  AV360
//
//  Created by Sajid Nawaz
//  sajidnawaz993@gmail.com

import UIKit
import AVKit

public class PlayerVC: UIViewController {

    // ------------------------------------------------
    // MARK: outlets
    // ------------------------------------------------
    
    @IBOutlet weak var upperView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var arrowbtn: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    @IBOutlet weak var bottomDropDown: UIView!
    @IBOutlet weak var dropDwonIndicator: UIView!
    @IBOutlet weak var bottomdropDownSafeArea: UIView!
    @IBOutlet weak var collectionVIewHeight: NSLayoutConstraint!
    
    // ------------------------------------------------
    // MARK: variable
    // ------------------------------------------------
    
    var spinner = UIActivityIndicatorView(activityIndicatorStyle: .large)
    var aV360ViewController: AV360ViewController!
    var avatar = Array<Any>()
    var player :AVPlayer?
    var playerItem: AVPlayerItem?
    var eventId:String = ""
    var isMuteVolume:Bool = false
    var isPlay:Bool = true
    var selectIndex:Int = 0
    var bearerToken:String = ""
    
    // ------------------------------------------------
    // MARK: View life cycle method
    // ------------------------------------------------
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        upperView.backgroundColor = UIColor.black
        arrowbtn.layer.cornerRadius = 25
        dropDwonIndicator.layer.cornerRadius = 2
        bottomDropDown.layer.cornerRadius = 10
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.downSwiped))
        swipeDown.direction = .down
        self.bottomDropDown.addGestureRecognizer(swipeDown)
        let bundle = Bundle(for: AvatarCollectionViewCell.classForCoder())
        let nib = UINib(nibName: "AvatarCollectionViewCell", bundle: bundle)
        self.collectionView.register(nib, forCellWithReuseIdentifier: "avatar")
        self.apiCall()
    }
    
    public class func getPlayerVC(eventId:String, bearerToken:String)->PlayerVC{
      let bundle = Bundle(for: PlayerVC.classForCoder())
        let playerVC = PlayerVC(nibName: "PlayerVC", bundle: bundle)
        playerVC.eventId = eventId
        playerVC.bearerToken = bearerToken
        return playerVC
    }
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if let currentPlayer = player , let playerObject = object as? AVPlayerItem, playerObject == currentPlayer.currentItem, keyPath == "status"
            {
                if ( currentPlayer.currentItem!.status == .readyToPlay)
                {
                    self.hideActivityIndicator()
                    currentPlayer.playImmediately(atRate: 1.0)
                }
            }
        }

    // ------------------------------------------------
    // MARK: Custom method
    // ------------------------------------------------
    
    @objc func downSwiped()
    {
        self.arrowbtn.isHidden = false
        self.collectionVIewHeight.constant = 0
        bottomdropDownSafeArea.isHidden = true
    }
    
    func loadPlayer(){
        player = AVPlayer.init(playerItem: nil)
        player?.allowsExternalPlayback = false
        player?.automaticallyWaitsToMinimizeStalling = false
        player?.volume = volumeSlider.value
        let motionManager = AV360MotionManager.shared
        // set motionManager nil to skip motion changes
        aV360ViewController = AV360ViewController(withAVPlayer: player!, motionManager: motionManager)
        addChildViewController(aV360ViewController)
        upperView.addSubview(aV360ViewController.view)
        aV360ViewController.didMove(toParentViewController: self)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(reorientVerticalCameraAngle))
        aV360ViewController.view.addGestureRecognizer(tapGestureRecognizer)
    }

    func hexStringToUIColor (hex:String) -> UIColor {
         var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

         if (cString.hasPrefix("#")) {
             cString.remove(at: cString.startIndex)
         }

         if ((cString.count) != 6) {
             return UIColor.gray
         }

         var rgbValue:UInt64 = 0
         Scanner(string: cString).scanHexInt64(&rgbValue)

         return UIColor(
             red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
             green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
             blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
             alpha: CGFloat(1.0)
         )
     }
    
    func showActivityIndicator() {
        DispatchQueue.main.async {
            self.spinner.frame = CGRect(x: 0.0, y: 0.0, width: 80.0, height: 80.0)
            self.spinner.color = UIColor.white
            self.spinner.center = self.view.center
            self.view.addSubview(self.spinner)
            self.spinner.startAnimating()
        }
    }

    func hideActivityIndicator() {
        DispatchQueue.main.async {
            self.spinner.stopAnimating()
            self.spinner.removeFromSuperview()
        }
    }
    
    func loadUrlInPlayer(_ index:Int){
        let dic = self.avatar[index] as? NSDictionary
        if let mediaUrl = URL(string: dic?["stream"] as? String ?? "") {
            self.playerItem =  AVPlayerItem.init(url: mediaUrl)
            self.player?.replaceCurrentItem(with: self.playerItem)
            player?.currentItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions(rawValue: 0), context: nil)
        }
    }
    
    
    
    @objc func reorientVerticalCameraAngle() {
        aV360ViewController.reorientVerticalCameraAngleToHorizon(animated: true)
    }
    
    // ------------------------------------------------
    // MARK: IBAction method
    // ------------------------------------------------
    
    @IBAction func backbtntpd(_ sender: Any) {
        if(self.navigationController != nil){
            self.navigationController?.popViewController(animated: true)
        }else{
            self.dismiss(animated: true)
        }
    }
    
    @IBAction func volumeChange(_ sender: Any) {
        player?.volume = volumeSlider.value
    }
    
    @IBAction func arrowbtntpd(_ sender: UIButton) {
        self.collectionVIewHeight.constant = 150
        self.arrowbtn.isHidden = true
        bottomdropDownSafeArea.isHidden = false
    }
    
    @IBAction func playPuasebtntpd(_ sender: UIButton) {
        isPlay = !isPlay
        if(isPlay){
            sender.setImage(UIImage(named: "ic_pause",
                                    in: Bundle(for: type(of:self)),compatibleWith: nil), for: .normal)
            player?.play()
        }else{
            sender.setImage(UIImage(named: "ic_play",
                                    in: Bundle(for: type(of:self)),compatibleWith: nil), for: .normal)
            player?.pause()
        }
    }
    
    @IBAction func muteUnmutebtnpd(_ sender: UIButton) {
        isMuteVolume = !isMuteVolume
        if(isMuteVolume){
            sender.setImage(UIImage(named: "ic_sound_mute",
                                    in: Bundle(for: type(of:self)),compatibleWith: nil), for: .normal)
            player?.isMuted = true
        }else{
            sender.setImage(UIImage(named: "ic_sound",
                                    in: Bundle(for: type(of:self)),compatibleWith: nil), for: .normal)
            player?.isMuted = false
        }
    }
    
    // ------------------------------------------------
    // MARK: Api Call method
    // ------------------------------------------------
    
    func apiCall(){
        var request = URLRequest(url: URL(string: "https://7k67ed7acrzp3725sijxq3fedm0xaowa.lambda-url.eu-central-1.on.aws/events/\(eventId)")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Authorization", forHTTPHeaderField: "\(bearerToken)")
        self.showActivityIndicator()
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
                let data = json["data"] as? NSDictionary
                self.avatar = data?["avatars"] as? [Any] ?? []
                DispatchQueue.main.async {
                    self.loadPlayer()
                    self.loadUrlInPlayer(0)
                    self.collectionView.reloadData()
                }
            } catch {
                if let returnData = String(data: data!, encoding: .utf8) {
                         print(returnData)
                       }
                print("error \(error.localizedDescription)")
            }
        })
        task.resume()
    }
}

// ------------------------------------------------
// MARK: Delegate method
// ------------------------------------------------
extension PlayerVC:UICollectionViewDataSource, UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.avatar.count
    }
    
    // make a cell for each cell index path
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "avatar", for: indexPath as IndexPath) as! AvatarCollectionViewCell
        let dic = self.avatar[indexPath.row] as? NSDictionary
        cell.avatarLabel.text = (dic?["name"] as? String ?? "").first?.uppercased()
        cell.avatarLabel.layer.cornerRadius = 25
        cell.avatarLabel.clipsToBounds = true
        if(indexPath.row == self.selectIndex){
            cell.avatarLabel.layer.borderWidth = 2
            cell.avatarLabel.layer.borderColor = hexStringToUIColor(hex: "#DBDBDB").cgColor
        }else{
            cell.avatarLabel.layer.borderWidth = 0
        }
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.showActivityIndicator()
        self.loadUrlInPlayer(indexPath.row)
        self.selectIndex = indexPath.row
        self.collectionView.reloadData()
    }
    
    // MARK: - UICollectionViewDelegateFlowLayout protocol
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 50)
    }
}


