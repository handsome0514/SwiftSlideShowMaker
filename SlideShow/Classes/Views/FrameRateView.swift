//
//  FrameRateView.swift
//  SlideShow
//
//  Created by Hua Wan on 5/12/22.
//

import UIKit

protocol FrameRateViewDelegate {
    func didSelectFrameRate(_ rate: Int)
}

class FrameRateView: UIView {

    @IBOutlet weak var collectionView: UICollectionView!
    
    fileprivate var frameRates: [Int] = [24, 25, 30, 50, 60]
    fileprivate var selectedIndex: Int = 2
    
    var delegate: FrameRateViewDelegate? = nil
    
    class func loadFromNib() -> FrameRateView {
        let bundles = Bundle.main.loadNibNamed("FrameRateView", owner: self, options: nil)!.filter { bundle in
            return bundle is FrameRateView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! FrameRateView
        } else {
            return bundles.last as! FrameRateView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        collectionView.register(UINib(nibName: "FrameRateViewCell", bundle: nil), forCellWithReuseIdentifier: "FrameRateViewCell")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension FrameRateView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return frameRates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FrameRateViewCell", for: indexPath) as! FrameRateViewCell
        cell.frameLabel.text = "\(frameRates[indexPath.item])"
        cell.isSelection = indexPath.item == selectedIndex
        return cell
    }
}

extension FrameRateView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
        collectionView.reloadData()
        delegate?.didSelectFrameRate(frameRates[indexPath.item])
    }
}

extension FrameRateView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 48.0, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        var left = (collectionView.frame.width - (CGFloat(frameRates.count) * 48.0 + CGFloat(frameRates.count - 1) * 8.0)) / 2.0
        if left < 0.0 {
            left = 0.0
        }
        return UIEdgeInsets(top: 0, left: left, bottom: 0, right: left)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
}
