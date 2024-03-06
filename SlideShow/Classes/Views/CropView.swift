//
//  CropView.swift
//  SlideShow
//
//  Created by Hua Wan on 11/5/21.
//

import UIKit

protocol CropViewDelegate {
    func didSelectRotate()
    func didSelectFlip()
    func didSelectFill()
    func didSelectClose()
}

class CropView: UIView {

    @IBOutlet weak var rotateView: UIView!
    @IBOutlet weak var flipView: UIView!
    @IBOutlet weak var fillView: UIView!
    @IBOutlet weak var fillImageView: UIImageView!
    @IBOutlet weak var fillLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    var delegate: CropViewDelegate? = nil
    
    var project: Project! {
        didSet {
            let contentType = ContentType(rawValue: project.contentType)!
            if contentType == .scaleFill {
                fillImageView.isHighlighted = false
                fillLabel.text = "Fill"
            } else {
                fillImageView.isHighlighted = true
                fillLabel.text = "Fit"
            }
        }
    }
    
    var media: Media! {
        didSet {
            
        }
    }
    
    class func loadFromNib() -> CropView {
        let bundles = Bundle.main.loadNibNamed("CropView", owner: self, options: nil)!.filter { bundle in
            return bundle is CropView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! CropView
        } else {
            return bundles.last as! CropView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let radius: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 20 : 36
        rotateView.addShadows(0.05, UIColor.lightGray, radius)
        flipView.addShadows(0.05, UIColor.lightGray, radius)
        fillView.addShadows(0.05, UIColor.lightGray, radius)
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
        //self.removeFromSuperview()
        delegate?.didSelectClose()
    }
    
    @IBAction func rotateButtonPressed(_ sender: Any) {
        delegate?.didSelectRotate()
    }
    
    @IBAction func flipButtonPressed(_ sender: Any) {
        delegate?.didSelectFlip()
    }
    
    @IBAction func fillButtonPressed(_ sender: Any) {
        fillImageView.isHighlighted = !fillImageView.isHighlighted
        if fillImageView.isHighlighted {
            fillLabel.text = "Fit"
        } else {
            fillLabel.text = "Fill"
        }
        delegate?.didSelectFill()
    }
}
