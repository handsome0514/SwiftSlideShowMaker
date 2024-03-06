//
//  RatiosView.swift
//  SlideShow
//
//  Created by Hua Wan on 9/25/21.
//

import UIKit

protocol RatiosViewDelegate {
    func didSelectRatio(_ ratio: RatioType?)
}

class RatiosView: UIView {

    @IBOutlet weak var ratiosCollectionView: UICollectionView!
    @IBOutlet weak var backButton: UIButton!
    
    fileprivate var selectedIndex: Int = -1
    
    var delegate: RatiosViewDelegate? = nil
    
    class func loadFromNib() -> RatiosView {
        let bundles = Bundle.main.loadNibNamed("RatiosView", owner: self, options: nil)!.filter { bundle in
            return bundle is RatiosView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! RatiosView
        } else {
            return bundles.last as! RatiosView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        ratiosCollectionView.register(UINib(nibName: "RatioViewCell", bundle: nil), forCellWithReuseIdentifier: "RatioViewCell")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    // MARK: - IBAction
    @IBAction func backButtonPressed(_ sender: Any) {
        if selectedIndex != -1 {
            delegate?.didSelectRatio(nil)
        } else {
            delegate?.didSelectRatio(RatioType(rawValue: RatioType.original.rawValue + selectedIndex))
        }
        self.removeFromSuperview()
    }
}

extension RatiosView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return RatioType.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RatioViewCell", for: indexPath) as! RatioViewCell
        cell.ratio = RatioType(rawValue: RatioType.original.rawValue + indexPath.item)!
        cell.isSelection = indexPath.item == selectedIndex
        return cell
    }
}

extension RatiosView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: IndexPath(item: selectedIndex, section: 0)) as? RatioViewCell {
            cell.isSelection = false
        }
        selectedIndex = indexPath.item
        if let cell = collectionView.cellForItem(at: indexPath) as? RatioViewCell {
            cell.isSelection = true
        }
        delegate?.didSelectRatio(RatioType(rawValue: RatioType.original.rawValue + selectedIndex)!)
    }
}

extension RatiosView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height - 40
        let width = height * 0.8
        return CGSize(width: width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? 16.0 : 24
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? 16.0 : 24
    }
}
