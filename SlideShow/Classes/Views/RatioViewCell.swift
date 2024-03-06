//
//  RatioViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 9/25/21.
//

import UIKit

class RatioViewCell: UICollectionViewCell {
    
    @IBOutlet weak var ratioView: UIView!
    @IBOutlet weak var ratioImageView: UIImageView!
    @IBOutlet weak var ratioLabel: UILabel!
    @IBOutlet weak var captionLabel: UILabel!
    
    @IBOutlet weak var centerYRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var centerYCaptionConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var centerYImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthRatioConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightRatioConstraint: NSLayoutConstraint!
    
    var ratio: RatioType = .original {
        didSet {
            ratioLabel.text = ratio.string
            captionLabel.text = ratio.caption
            
            let width: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 28.0 : 40
            let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 38.0 : 64
            switch ratio {
            case .original:
                widthRatioConstraint.constant = width
                heightRatioConstraint.constant = width / ratio.ratio
            case .portrait:
                heightRatioConstraint.constant = height
                widthRatioConstraint.constant = height * ratio.ratio
            case .landscape:
                widthRatioConstraint.constant = height
                heightRatioConstraint.constant = height / ratio.ratio
            case .square:
                widthRatioConstraint.constant = width
                heightRatioConstraint.constant = width
            }
        }
    }
    
    var isSelection: Bool = false {
        didSet {
            if isSelection {
                ratioView.layer.borderColor = MAIN_ACTIVE_COLOR_1.cgColor
            } else {
                ratioView.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //ratioView.layer.borderWidth = UIDevice.current.userInterfaceIdiom == .phone ? 2.0 : 3.0
        ratioView.addShadows(0.05, UIColor.lightGray, UIDevice.current.userInterfaceIdiom == .phone ? 20 : 36)
        ratioImageView.layer.borderWidth = 1.0
        ratioImageView.layer.borderColor = UIColor.white.cgColor
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            ratioLabel.font = ratioLabel.font.withSize(18)
            captionLabel.font = captionLabel.font.withSize(10)
            centerYImageConstraint.constant = -20
            centerYRatioConstraint.constant = 20
            centerYCaptionConstraint.constant = 40
        } else {
            ratioLabel.font = ratioLabel.font.withSize(32)
            captionLabel.font = captionLabel.font.withSize(18)
            centerYImageConstraint.constant = -40
            centerYRatioConstraint.constant = 18
            centerYCaptionConstraint.constant = 56
        }
    }
}
