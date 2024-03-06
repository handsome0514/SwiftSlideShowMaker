//
//  ArrangeView.swift
//  SlideShow
//
//  Created by Hua Wan on 9/21/21.
//

import UIKit
import SwiftColor

protocol ArrangeViewDelegate {
    func didChangeColor(_ index: Int)
    func didChangeContentType(_ type: ContentType)
    func didTapRatio()
}

class ArrangeView: UIView {
    
    @IBOutlet weak var colorsCollectionView: UICollectionView!
    @IBOutlet weak var contentModeView: UIView!
    @IBOutlet weak var contentModeButton: UIButton!
    @IBOutlet weak var contentModeLabel: UILabel!
    @IBOutlet weak var ratioView: UIView!
    @IBOutlet weak var ratioImageView: UIImageView!
    @IBOutlet weak var ratioLabel: UILabel!
    
    @IBOutlet weak var widthRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightRatioConstraint: NSLayoutConstraint!

    var project: Project! {
        didSet {
            let ratioType = RatioType(rawValue: project.ratio)!
            ratioLabel.text = "Aspect: \(ratioType.caption)"
            let contentType = ContentType(rawValue: project.contentType)!
            if contentType == .scaleFill {
                //contentModeButton.backgroundColor = MAIN_ACTIVE_COLOR_1
                contentModeButton.isSelected = true
                contentModeLabel.text = "Fill"
            } else {
                //contentModeButton.backgroundColor = .white
                contentModeButton.isSelected = false
                contentModeLabel.text = "Fit"
            }
            selectedIndex = project.colorIndex
            
            let width: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 36.0 : 64
            let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 48.0 : 88
            switch ratioType {
            case .original:
                widthRatioConstraint.constant = width
                heightRatioConstraint.constant = width / ratioType.ratio
            case .portrait:
                heightRatioConstraint.constant = height
                widthRatioConstraint.constant = height * ratioType.ratio
            case .landscape:
                widthRatioConstraint.constant = height
                heightRatioConstraint.constant = height / ratioType.ratio
            case .square:
                widthRatioConstraint.constant = width
                heightRatioConstraint.constant = width
            }
        }
    }
    
    var delegate: ArrangeViewDelegate?
    
    fileprivate var selectedIndex: Int = 0
    
    class func loadFromNib() -> ArrangeView {
        let bundles = Bundle.main.loadNibNamed("ArrangeView", owner: self, options: nil)!.filter { bundle in
            return bundle is ArrangeView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! ArrangeView
        } else {
            return bundles.last as! ArrangeView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        colorsCollectionView.register(UINib(nibName: "ColorViewCell", bundle: nil), forCellWithReuseIdentifier: "ColorViewCell")
        //contentModeView.addShadows(0.05, UIColor.lightGray, 20)
        //ratioView.addShadows(0.05, UIColor.lightGray, 20)
        
        ratioImageView.layer.borderWidth = 1.0
        ratioImageView.layer.borderColor = UIColor.white.cgColor
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    // MARK: - IBAction
    @IBAction func modeButtonPressed(_ sender: Any) {
        
        contentModeButton.isSelected = !contentModeButton.isSelected
        var contentType = ContentType.scaleFill
        if contentModeButton.isSelected {
            //contentModeButton.backgroundColor = MAIN_ACTIVE_COLOR_1
            contentType = .scaleFill
            contentModeLabel.text = "Fill"
        } else {
            //contentModeButton.backgroundColor = .white
            contentType = .scaleFit
            contentModeLabel.text = "Fit"
        }
        
        if project.contentType == contentType.rawValue {
            return
        }
        
        delegate?.didChangeContentType(contentType)
    }
    
    @IBAction func ratioButtonPressed(_ sender: Any) {
        
        delegate?.didTapRatio()
    }
}

extension ArrangeView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return APP_ARRAY_COLORS.count + 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorViewCell", for: indexPath) as! ColorViewCell
        if indexPath.item == 0 {
            cell.icon = UIImage(named: "BlurIcon")
        } else {
            cell.color = UIColor(hexInt: APP_ARRAY_COLORS[indexPath.item - 1])
        }
        cell.colorIndex = indexPath.item - 1
        cell.isSelection = indexPath.item - 1 == selectedIndex
        cell.cellSize = CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
        return cell
    }
}

extension ArrangeView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: IndexPath(item: selectedIndex + 1, section: 0)) as? ColorViewCell {
            cell.isSelection = false
        }
        selectedIndex = indexPath.item - 1
        if let cell = collectionView.cellForItem(at: indexPath) as? ColorViewCell {
            cell.isSelection = true
        }
        delegate?.didChangeColor(selectedIndex)
    }
}

extension ArrangeView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.height
        return CGSize(width: width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
}
