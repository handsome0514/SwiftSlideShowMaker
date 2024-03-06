//
//  EditView.swift
//  SlideShow
//
//  Created by Hua Wan on 9/21/21.
//

import UIKit

protocol EditViewDelegate {
    func reloadMedias()
    func didTapNew(_ view: EditView, _ index: Int)
    func didSelectMedia(_ index: Int)
    func didTrashMedia(_ index: Int)
    func didTapOrder(_ view: EditView)
    func didStartDrag(_ view: EditView)
    func didEndDrag(_ view: EditView)
}

class EditView: UIView {

    @IBOutlet weak var mediasCollectionView: UICollectionView!
    @IBOutlet weak var orderButton: GradientButton!
    @IBOutlet weak var orderLabel: UILabel!
    @IBOutlet weak var orderImageView: UIImageView!
    @IBOutlet weak var trashView: UIView!
    @IBOutlet weak var trashButton: UIButton!
    
    fileprivate var snapshot: UIView!
    fileprivate var sourceIndexPath: IndexPath!
    fileprivate var isLongGesture = false
    fileprivate var initMovingRow: Int = 0
    fileprivate var replaceSelectedIndex: Int = -1
    
    var project: Project! {
        didSet {
            updateOrderView()
            mediasCollectionView.reloadData()
            updateAddButtons()
        }
    }
    
    var delegate: EditViewDelegate? = nil
    
    var selectedIndex: Int = 0 {
        willSet {
            if let cell = mediasCollectionView.cellForItem(at: IndexPath(item: selectedIndex + 1, section: 0)) as? EditViewCell {
                cell.isSelection = false
            }
        }
        didSet {
            if let cell = mediasCollectionView.cellForItem(at: IndexPath(item: selectedIndex + 1, section: 0)) as? EditViewCell {
                cell.isSelection = true
            }
            
            let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 8.0 : 16
            let width: CGFloat = (mediasCollectionView.frame.height - (UIDevice.current.userInterfaceIdiom == .phone ? 20 : 28)) * 0.9
            if (offset + width) * CGFloat(selectedIndex + 1) + width > mediasCollectionView.frame.width + mediasCollectionView.contentOffset.x - width {
                var coffset: CGFloat = (offset + width) * CGFloat(selectedIndex + 1) + width - mediasCollectionView.frame.width
                if coffset < 0 {
                    coffset = 0.0
                }
                mediasCollectionView.setContentOffset(CGPoint(x: coffset, y: 0), animated: true)
            } else if (offset + width) * CGFloat(selectedIndex + 1) < mediasCollectionView.contentOffset.x {
                mediasCollectionView.setContentOffset(CGPoint(x: (offset + width) * CGFloat(selectedIndex + 1), y: 0), animated: true)
            }
        }
    }
    
    class func loadFromNib() -> EditView {
        let bundles = Bundle.main.loadNibNamed("EditView", owner: self, options: nil)!.filter { bundle in
            return bundle is EditView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! EditView
        } else {
            return bundles.last as! EditView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        orderButton.colors = [UIColor("#0191CA").cgColor, UIColor("#28EDF5").cgColor]
        
        mediasCollectionView.register(UINib(nibName: "EditViewCell", bundle: nil), forCellWithReuseIdentifier: "EditViewCell")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    func reloadData() {
        mediasCollectionView.reloadData()
        updateOrderView()
    }
    
    func updateOrderView() {
        let orderType = OrderType(rawValue: project.orderType)!
        orderLabel.text = orderType.caption
        orderImageView.image = orderType.image
    }
    
    func updateAddButtons() {
        _ = mediasCollectionView.subviews.map { if $0 is UIButton { $0.removeFromSuperview() } }
        let image = UIImage(named: "MediaAdd")!
        let cellSize = collectionView(mediasCollectionView, layout: mediasCollectionView.collectionViewLayout, sizeForItemAt: IndexPath(item: 0, section: 0))
        let itemSpacing = collectionView(mediasCollectionView, layout: mediasCollectionView.collectionViewLayout, minimumInteritemSpacingForSectionAt: 0)
        let cellInsets = collectionView(mediasCollectionView, layout: mediasCollectionView.collectionViewLayout, insetForSectionAt: 0)
        var offset: CGFloat = cellSize.width + itemSpacing
        for i in 1 ..< project.medias.count {
            let button = UIButton(type: .custom)
            button.setImage(image, for: .normal)
            button.isUserInteractionEnabled = true
            button.frame = CGRect(x: offset + (cellSize.width - (image.size.width - itemSpacing) / 2.0), y: (cellSize.height - image.size.height) / 2.0 - cellInsets.top, width: image.size.width, height: image.size.height)
            button.tag = i - 1
            button.addTarget(self, action: #selector(addButtonPressed(_:)), for: .touchUpInside)
            mediasCollectionView.addSubview(button)
            offset += cellSize.width + itemSpacing
        }
    }
    
    func showAddButtons(_ show: Bool) {
        _ = mediasCollectionView.subviews.map { if $0 is UIButton { $0.isHidden = !show } }
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
    
    // MARK: - IBAction
    @IBAction func trashButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func orderButtonPressed(_ sender: Any) {
        delegate?.didTapOrder(self)
    }
    
    @IBAction func addButtonPressed(_ sender: UIButton) {
        delegate?.didTapNew(self, sender.tag + 1)
//        delegate?.didTapAdd(sender)
    }
    
    // MARK: - UIGestureRecognizer Handlers
    @IBAction func handleCollectionLongGesture(_ sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: self)
        let position = CGPoint(x: location.x - mediasCollectionView.frame.origin.x + mediasCollectionView.contentOffset.x, y: location.y - mediasCollectionView.frame.origin.y + mediasCollectionView.contentOffset.y)
        let indexPath = mediasCollectionView.indexPathForItem(at: position)
        
        if sender.state == .began {
            
            replaceSelectedIndex = selectedIndex
            if let indexPath = indexPath {
                if indexPath.item == 0 || self.project.medias.count == 1 || indexPath.item > self.project.medias.count {
                    isLongGesture = false
                    return
                }
                
                delegate?.didStartDrag(self)
                
                showAddButtons(false)
                let trashHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 70.0 : 128.0
                var frame = self.frame
                frame.size.height += trashHeight
                self.frame = frame
                trashView.isHidden = false
                
                mediasCollectionView.clipsToBounds = false
                isLongGesture = true
                sourceIndexPath = indexPath
                initMovingRow = indexPath.row
                /*if sourceIndexPath.item == selectedRow {
                    isMovingSelectedCell = true
                }*/
                
                let cell = mediasCollectionView.cellForItem(at: indexPath)!
                // Take a snapshot of the selected row using helper method.
                if let cell = cell as? EditViewCell {
                    cell.isMoveSelection = true
                }
                snapshot = customSnapshot(from: cell)
                if let cell = cell as? EditViewCell {
                    cell.isMoveSelection = false
                }
                
                // Add the snapshot as subview, centered at cell's center...
                var center = cell.center
                snapshot.center = center
                snapshot.alpha = 0.0
                self.addSubview(snapshot)
                UIView.animate(withDuration: 0.25) {
                    center.x = location.x
                    center.y = location.y
                    self.snapshot.center = center
                    self.snapshot.transform = CGAffineTransform.identity.scaledBy(x: 1.2, y: 1.2)
                    self.snapshot.alpha = 0.6
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
            
            if trashView.frame.contains(location) {
                trashButton.isSelected = true
            } else {
                trashButton.isSelected = false
            }
            
            // Is destination valid and is it different from source?
            if let indexPath = indexPath, indexPath.item != 0 {
                if indexPath != sourceIndexPath, indexPath.item <= project.medias.count {
                    // ... update data source.
                    do {
                        try sharedRealm.write {
                            project.medias.swapAt(indexPath.item - 1, sourceIndexPath.item - 1)
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                    // ... move the rows.
                    if replaceSelectedIndex + 1 == sourceIndexPath.item {
                        replaceSelectedIndex = indexPath.item - 1
                    } else if indexPath.item == replaceSelectedIndex + 1 {
                        replaceSelectedIndex = sourceIndexPath.item - 1
                    }
                    mediasCollectionView.moveItem(at: sourceIndexPath, to: indexPath)
                    // ... and update source so it is in sync with UI changes.
                    sourceIndexPath = indexPath
                    
//                    self.delegate?.reloadMedias()
                }
            }
        }
        else
        {
            if isLongGesture == false {
                return
            }
            
            let trashHeight: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 70.0 : 128.0
            var frame = self.frame
            frame.size.height -= trashHeight
            self.frame = frame
            trashView.isHidden = true
            trashButton.isSelected = false
            
            mediasCollectionView.clipsToBounds = false
            isLongGesture = false
            if sourceIndexPath == nil || project.medias.count == 1 {
                sourceIndexPath = IndexPath(item: 0, section: 0)
            }
            
            let cell = mediasCollectionView.cellForItem(at: sourceIndexPath)!
            var isRemoved = false
            if self.trashView.frame.contains(location) {
                self.delegate?.didTrashMedia(self.sourceIndexPath.item - 1)
                isRemoved = true
            } else {
                cell.isHidden = false
                cell.alpha = 0.0
            }
            UIView.animate(withDuration: 0.25) {
                if !isRemoved {
                    self.snapshot.center = cell.center
                    self.snapshot.transform = .identity
                }
                self.snapshot.alpha = 0.0
                cell.isHidden = false
                cell.alpha = 1.0
            } completion: { finished in
                self.sourceIndexPath = nil
                self.snapshot.removeFromSuperview()
                self.snapshot = nil
                
                self.showAddButtons(true)
                
                if self.replaceSelectedIndex != self.selectedIndex {
                    self.selectedIndex = self.replaceSelectedIndex
                    if self.selectedIndex < 0 {
                        self.selectedIndex = 0
                    } else if self.selectedIndex >= self.project.medias.count {
                        self.selectedIndex = self.project.medias.count - 1
                    }
                    self.mediasCollectionView.reloadData()
//                    self.delegate?.didSelectMedia(self.selectedIndex)
                }
//                self.delegate?.reloadMedias()
            }
            
            delegate?.didEndDrag(self)
        }
    }
}

extension EditView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return project.medias.count + 2
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.item == 0 || indexPath.item == project.medias.count + 1 {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditViewCell", for: indexPath) as! EditViewCell
            cell.media = nil
            cell.isSelection = false
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EditViewCell", for: indexPath) as! EditViewCell
            cell.media = project.medias[indexPath.item - 1]
            cell.isSelection = indexPath.item == selectedIndex + 1
            return cell
        }
    }
}

extension EditView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.item == 0 || indexPath.item == project.medias.count + 1 {
            if indexPath.item == 0 {
                delegate?.didTapNew(self, indexPath.item)
            } else {
                delegate?.didTapNew(self, project.medias.count)
            }
            return
        }
        if let cell = collectionView.cellForItem(at: IndexPath(item: selectedIndex + 1, section: 0)) as? EditViewCell {
            cell.isSelection = false
        }
        selectedIndex = indexPath.item - 1
        if let cell = collectionView.cellForItem(at: indexPath) as? EditViewCell {
            cell.isSelection = true
        }
        delegate?.didSelectMedia(selectedIndex)
    }
}

extension EditView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: UIDevice.current.userInterfaceIdiom == .phone ? 8 : 16, left: 0, bottom: 0, right: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width: CGFloat = (collectionView.frame.height - (UIDevice.current.userInterfaceIdiom == .phone ? 28 : 36)) * 0.9
        return CGSize(width: width, height: collectionView.frame.height - (UIDevice.current.userInterfaceIdiom == .phone ? 8 : 16))
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? 8.0 : 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? 8.0 : 16
    }
}
