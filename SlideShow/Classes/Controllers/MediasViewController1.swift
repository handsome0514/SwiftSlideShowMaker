//
//  MediasViewController1.swift
//  SlideShow
//
//  Created by Hua Wan on 9/15/21.
//

import UIKit
import Photos
import Toast_Swift

class MediasViewController1: UIViewController {

    @IBOutlet weak var albumsCollectionView: UICollectionView!
    @IBOutlet weak var mediasCollectionView: UICollectionView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var mediasView: UIView!
    @IBOutlet weak var selectionsCollectionView: UICollectionView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var orderButton: UIButton!
    
    @IBOutlet weak var bottomMenuConstraint: NSLayoutConstraint!
    
    var editViewCtrl: EditViewController?
    fileprivate var snapshot: UIView!
    fileprivate var sourceIndexPath: IndexPath!
    fileprivate var startIndexPath: IndexPath!
    fileprivate var isLongGesture = false
    fileprivate var initMovingRow: Int = 0
    
    fileprivate var albums: [PHAssetCollection] = []
    fileprivate var assets: PHFetchResult<PHAsset>!
    fileprivate var selectedAlbumIndex = 0
    fileprivate var selectedAssets = [MediaAsset]()
    fileprivate var isFirstLayout = true
    fileprivate var mediaOrder: OrderType = .shuffle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidPurchaseNotification(_:)), name: NSNotification.Name(rawValue: "ProductPurchased"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirstLayout {
            isFirstLayout = false
            
            requestLibraryAuthorization { (authorized) in
                DispatchQueue.main.async {
                    if authorized {
                        self.loadPhotosLibrary()
                    } else {
                        self.showAlertView("Photo Library unavailable", "Please check to see if device settings doesn't allow photo library access", "Cancel", "Settings") {
                            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
                        }
                    }
                }
            }
        }
        
        mediasView.roundCorners(corners: [.topLeft, .topRight], radius: 20)
        
        self.view.layoutIfNeeded()
        
        if selectedAssets.count == 0 {
            bottomMenuConstraint.constant = -mediasView.frame.height
            nextButton.isEnabled = false
        } else {
            bottomMenuConstraint.constant = 0
            nextButton.isEnabled = true
        }
        
        updateVideoDuration()
    }
    
    func requestLibraryAuthorization(_ completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            completion(true)
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                self.requestLibraryAuthorization(completion)
            }
        } else {
            completion(false)
        }
    }
    
    func loadPhotosLibrary() {
        self.albums.removeAll()
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
        albums.enumerateObjects { (collection, index, object) in
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            if assets.count > 0 {
                self.albums.append(collection)
            }
        }
        smartAlbums.enumerateObjects { (collection, index, object) in
            let assets = PHAsset.fetchAssets(in: collection, options: nil)
            if assets.count > 0 {
                self.albums.append(collection)
            }
        }
        
        sortAlbums()
        if self.albums.count == 0 {
            return
        }
        self.assets = PHAsset.fetchAssets(in: self.albums[selectedAlbumIndex], options: options)
        
        if ProjectManager.current.medias.count > 0, ProjectManager.shared.isEditing == true {
            selectedAssets.removeAll()
            for media in ProjectManager.current.medias {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [media.localIdentifier], options: options)
                if let asset = assets.firstObject {
                    let mediaAsset = MediaAsset(asset: asset, id: media.id)
                    selectedAssets.append(mediaAsset)
                }
            }
        }
        
        albumsCollectionView.reloadData()
        mediasCollectionView.reloadData()
        selectionsCollectionView.reloadData()
    }
    
    fileprivate func sortAlbums() {
        self.albums = self.albums.sorted(by: { collection1, collection2 in
            return collection1.localizedTitle! < collection2.localizedTitle!
        })
        if let index = self.albums.firstIndex(where: { collection in
            return collection.localizedTitle!.lowercased() == "Screenshots".lowercased()
        }) {
            let asset = self.albums[index]
            self.albums.remove(at: index)
            self.albums.insert(asset, at: 0)
        }
        
        if let index = self.albums.firstIndex(where: { collection in
            return collection.localizedTitle!.lowercased() == "Selfies".lowercased()
        }) {
            let asset = self.albums[index]
            self.albums.remove(at: index)
            self.albums.insert(asset, at: 0)
        }
        
        if let index = self.albums.firstIndex(where: { collection in
            return collection.localizedTitle!.lowercased() == "Favorites".lowercased()
        }) {
            let asset = self.albums[index]
            self.albums.remove(at: index)
            self.albums.insert(asset, at: 0)
        }
        
        if let index = self.albums.firstIndex(where: { collection in
            return collection.localizedTitle!.lowercased() == "Videos".lowercased()
        }) {
            let asset = self.albums[index]
            self.albums.remove(at: index)
            self.albums.insert(asset, at: 0)
        }
        
        if let index = self.albums.firstIndex(where: { collection in
            return collection.localizedTitle!.lowercased() == "Recents".lowercased()
        }) {
            let asset = self.albums[index]
            self.albums.remove(at: index)
            self.albums.insert(asset, at: 0)
        }
    }
    
    fileprivate func showMediasMenu(_ show: Bool) {
        UIView.animate(withDuration: 0.3) {
            if show {
                self.bottomMenuConstraint.constant = 0
                self.nextButton.isEnabled = true
            } else {
                self.bottomMenuConstraint.constant = -self.mediasView.frame.height
                self.nextButton.isEnabled = false
            }
            self.view.layoutIfNeeded()
        } completion: { (finished) in
            
        }
    }
    
    fileprivate func videoDuration(_ asset: PHAsset? = nil) -> CGFloat {
        var duration: CGFloat = 0
        let project = ProjectManager.current
        for asset in selectedAssets {
            if asset.asset.mediaType == .image {
                duration += CGFloat(project.imageDuration)
            } else if asset.asset.mediaType == .video {
                duration += CGFloat(asset.asset.duration)
            }
        }
        if let asset = asset {
            if asset.mediaType == .image {
                duration += CGFloat(project.imageDuration)
            } else if asset.mediaType == .video {
                duration += CGFloat(asset.duration)
            }
        }
        return duration
    }
    
    fileprivate func updateVideoDuration() {
        let duration = Int(videoDuration())
        durationLabel.text = Utilities.timeString(duration)
    }
    
    fileprivate func updateOrderIcon() {
        var order = mediaOrder.rawValue
        order += 1
        if order > OrderType.date.rawValue {
            order = OrderType.custom.rawValue
        }
        
        mediaOrder = OrderType(rawValue: order)!
        sortSelectedMedias()
        
        let image: UIImage
        let message: String
        switch mediaOrder {
        case .custom:
            image = UIImage(named: "IconCustomBlack")!.withTintColor(.white)
            message = "Order: Custom"
        case .shuffle:
            image = UIImage(named: "IconShuffleBlack")!.withTintColor(.white)
            message = "Order: Shuffle"
        case .date:
            image = UIImage(named: "IconDateBlack")!.withTintColor(.white)
            message = "Order: Creation Date"
        }
        orderButton.setImage(image, for: .normal)
        
        var style = ToastStyle()
        style.messageColor = .white
        style.messageFont = UIFont.medium(size: 14)!
        style.maxWidthPercentage = 0.8
        self.view.hideToast()
        self.view.makeToast(message, duration: 2.0, point: CGPoint(x: self.view.frame.width / 2.0, y: mediasView.frame.origin.y - 56), title: nil, image: nil, style: style, completion: nil)
    }
    
    fileprivate func sortSelectedMedias() {
        if mediaOrder == .date {
            selectedAssets = selectedAssets.sorted(by: { asset1, asset2 in
                return asset1.asset.creationDate! < asset2.asset.creationDate!
            })
        } else if mediaOrder == .shuffle {
            selectedAssets = selectedAssets.shuffled()
        }
        
        selectionsCollectionView.reloadData()
    }
    
    fileprivate func customSnapshot(from view: UIView) -> UIView {
        // Make an image from the view.
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, 0)
        view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Create an image view.
        let snapshot = UIImageView(image: image)
        snapshot.layer.masksToBounds = false
        snapshot.layer.cornerRadius = 0.0
        snapshot.layer.shadowOffset = CGSize(width: -5.0, height: 0)
        snapshot.layer.shadowRadius = 5.0
        snapshot.layer.shadowOpacity = 0.4
        
        return snapshot
    }

    @objc fileprivate func handleDidPurchaseNotification(_ notification: Notification) {
        
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "SetupViewController" {
            let controller = segue.destination as! SetupViewController
            controller.selectedAssets = selectedAssets
            controller.orderType = mediaOrder
        }
    }
    
    // MARK: - IBAction
    @IBAction func backButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true)
    }
    
    @IBAction func createProjectPressed(_ sender: UIButton) {
        
        self.editViewCtrl?.selectedAssets = self.selectedAssets
        
        self.dismiss(animated: true)
        
        self.editViewCtrl?.addSeledtedAssets(self.selectedAssets)
        
//        if ProjectManager.shared.isEditing == true {
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let vc = storyboard.instantiateViewController(withIdentifier: "LoadingViewController")
//            vc.modalPresentationStyle = .fullScreen
//            self.present(vc, animated: true)
////            performSegue(withIdentifier: "LoadingViewController", sender: nil)
//        }
        
//        performSegue(withIdentifier: "SetupViewController", sender: nil)
    }
    
    @IBAction func showPurchaseView() {
        if PurchaseManager.sharedManager.isPurchased() == false {
            PurchaseView.show().parentViewController = self
        }
    }
    
    @IBAction func mediaOrderPressed(_ sender: UIButton) {
        updateOrderIcon()
    }
    
    // MARK: - UIGestureRecognizer Handlers
    @IBAction func handleLeftSwipeGesture(_ sender: UISwipeGestureRecognizer) {
        if self.albums.count == 0 {
            return
        }
        
        if selectedAlbumIndex == self.albums.count - 1 {
            return
        }
        
        selectedAlbumIndex += 1
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.assets = PHAsset.fetchAssets(in: self.albums[selectedAlbumIndex], options: options)
        albumsCollectionView.reloadData()
        mediasCollectionView.reloadData()
    }
    
    @IBAction func handleRightSwipeGesture(_ sender: UISwipeGestureRecognizer) {
        if self.albums.count == 0 {
            return
        }
        
        if selectedAlbumIndex == 0 {
            return
        }
        
        selectedAlbumIndex -= 1
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        self.assets = PHAsset.fetchAssets(in: self.albums[selectedAlbumIndex], options: options)
        albumsCollectionView.reloadData()
        mediasCollectionView.reloadData()
    }
    
    @IBAction func handleCollectionLongGesture(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: selectionsCollectionView)
        let indexPath = selectionsCollectionView.indexPathForItem(at: location)

        if sender.state == .began {
            if let indexPath = indexPath {
                if indexPath.item >= self.selectedAssets.count {
                    isLongGesture = false
                    return
                }
                
                selectionsCollectionView.clipsToBounds = false
                isLongGesture = true
                sourceIndexPath = indexPath
                startIndexPath = indexPath
                initMovingRow = indexPath.row
                /*if sourceIndexPath.item == selectedRow {
                    isMovingSelectedCell = true
                }*/
                
                let cell = selectionsCollectionView.cellForItem(at: indexPath)!
                // Take a snapshot of the selected row using helper method.
                if let cell = cell as? MediaViewCell {
                    cell.isMoveSelection = true
                }
                snapshot = customSnapshot(from: cell)
                if let cell = cell as? MediaViewCell {
                    cell.isMoveSelection = false
                }
                
                // Add the snapshot as subview, centered at cell's center...
                var center = cell.center
                snapshot.center = center
                snapshot.alpha = 0.0
                selectionsCollectionView.addSubview(snapshot)
                UIView.animate(withDuration: 0.25) {
                    center.x = location.x
                    center.y = location.y
                    self.snapshot.center = center
                    self.snapshot.transform = CGAffineTransform.identity.scaledBy(x: 1.2, y: 1.2)
                    self.snapshot.alpha = 0.98
                    cell.alpha = 0.0
                } completion: { finished in
                    cell.isHidden = true
                }
            }
        } else if sender.state == .changed {
            if isLongGesture == false {
                return
            }
            
            var center = snapshot.center
            center.x = location.x
            center.y = location.y
            snapshot.center = center
            
            // Is destination valid and is it different from source?
            if let indexPath = indexPath {
                if indexPath != sourceIndexPath, indexPath.item <= selectedAssets.count - 1 {
                    // ... update data source.
                    selectedAssets.swapAt(indexPath.item, sourceIndexPath.item)
                    // ... move the rows.
                    selectionsCollectionView.moveItem(at: sourceIndexPath, to: indexPath)
                    // ... and update source so it is in sync with UI changes.
                    sourceIndexPath = indexPath
                }
            }
        }
        else
        {
            if isLongGesture == false {
                return
            }
            
            selectionsCollectionView.clipsToBounds = false
            isLongGesture = false
            if sourceIndexPath == nil || selectedAssets.count == 1 {
                sourceIndexPath = IndexPath(item: 0, section: 0)
            }
            
            if sourceIndexPath != nil, startIndexPath != nil, sourceIndexPath != startIndexPath {
                let image = UIImage(named: "IconCustomBlack")!.withTintColor(.white)
                mediaOrder = .custom
                orderButton.setImage(image, for: .normal)
            }
            
            let cell = selectionsCollectionView.cellForItem(at: sourceIndexPath)!
            cell.isHidden = false
            cell.alpha = 0.0
            UIView.animate(withDuration: 0.25) {
                self.snapshot.center = cell.center
                self.snapshot.transform = .identity
                self.snapshot.alpha = 0.0
                cell.alpha = 1.0
            } completion: { finished in
                self.sourceIndexPath = nil
                self.snapshot.removeFromSuperview()
                self.snapshot = nil
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension MediasViewController1: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == albumsCollectionView {
            return albums.count
        } else if collectionView == mediasCollectionView {
            if assets == nil {
                return 0
            } else {
                return assets.count
            }
        } else {
            return selectedAssets.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == albumsCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumViewCell", for: indexPath) as! AlbumViewCell
            cell.albumNameLabel.text = albums[indexPath.item].localizedTitle
            cell.isSelection = indexPath.item == selectedAlbumIndex
            return cell
        } else if collectionView == mediasCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaViewCell", for: indexPath) as! MediaViewCell
            let asset = assets[indexPath.item]
            cell.asset = asset
            cell.isSelection = selectedAssets.contains(where: { mediaAsset in
                return mediaAsset.asset.localIdentifier == asset.localIdentifier
            })
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaViewCell", for: indexPath) as! MediaViewCell
            let asset = selectedAssets[indexPath.item]
            cell.asset = asset.asset
            cell.delegate = self
            cell.cellIndex = indexPath.item
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension MediasViewController1: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == albumsCollectionView {
            selectedAlbumIndex = indexPath.item
            let options = PHFetchOptions()
            options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            self.assets = PHAsset.fetchAssets(in: self.albums[selectedAlbumIndex], options: options)
            albumsCollectionView.reloadData()
            mediasCollectionView.reloadData()
        } else if collectionView == mediasCollectionView {
            let asset = assets[indexPath.item]
            
            if videoDuration(asset) > 15, PurchaseManager.sharedManager.isPurchased() == false {
                showPurchaseView()
                return
            }
            let cell = collectionView.cellForItem(at: indexPath) as! MediaViewCell
            
            if cell.isSelection {
                var index = 0
                for item in selectedAssets {
                    if Int(item.id) == indexPath.row {
                        selectedAssets.remove(at: index)
                    }
                    index = index + 1
                }
                cell.isSelection = false
            } else {
                let mediaAsset = MediaAsset(asset: asset, id: "\(indexPath.row)")
                selectedAssets.append(mediaAsset)
                cell.isSelection = true
            }
            
            selectionsCollectionView.insertItems(at: [IndexPath(item: selectedAssets.count - 1, section: 0)])
            
            showMediasMenu(selectedAssets.count != 0)
            updateVideoDuration()
        } else {
            
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MediasViewController1: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == albumsCollectionView {
            let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 36.0 : 72
            let title = albums[indexPath.item].localizedTitle!
            let font = UIDevice.current.userInterfaceIdiom == .phone ? UIFont.medium(size: 14) : UIFont.medium(size: 24)
            let size = title.size(.infinity, height, [NSAttributedString.Key.font: font!])
            return CGSize(width: size.width + 8.0, height: height)
        } else if collectionView == mediasCollectionView {
            let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 8.0 : 16.0
            var width = (collectionView.frame.width - offset * 5.0) / 4.0
            if UIDevice.current.userInterfaceIdiom == .pad {
                width = (collectionView.frame.width - offset * 2.0 - 16.0 * 5.0) / 6.0 - 2
            }
            return CGSize(width: width, height: width)
        } else {
            return CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == selectionsCollectionView {
            return .zero
        } else {
            let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 8.0 : 16.0
            return UIEdgeInsets(top: 0, left: offset, bottom: 0, right: offset)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == albumsCollectionView {
            return UIDevice.current.userInterfaceIdiom == .phone ? 8 : 24
        } else if collectionView == mediasCollectionView {
            return 8
        } else {
            return 4
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == albumsCollectionView {
            return UIDevice.current.userInterfaceIdiom == .phone ? 8 : 24
        } else if collectionView == mediasCollectionView {
            return 8
        } else {
            return 4
        }
    }
}

// MARK: - MediaViewCellDelegate
extension MediasViewController1: MediaViewCellDelegate {
    func didTapRemove(_ cell: MediaViewCell) {
        selectedAssets.remove(at: cell.cellIndex)
        
        mediasCollectionView.reloadData()
        selectionsCollectionView.reloadData()
        
        updateVideoDuration()
    }
}
