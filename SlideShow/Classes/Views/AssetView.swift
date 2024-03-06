//
//  AssetView.swift
//  SlideShow
//
//  Created by Hua Wan on 9/29/21.
//

import UIKit

protocol AssetViewDelegate {
    func didSelectArt(_ view: AssetView)
    func didSelectText(_ view: AssetView)
    func didSelectGif(_ view: AssetView)
    func didSelectBack(_ view: AssetView)
}

class AssetView: UIView {

    var delegate: AssetViewDelegate? = nil
    
    class func loadFromNib() -> AssetView {
        let bundles = Bundle.main.loadNibNamed("AssetView", owner: self, options: nil)!.filter { bundle in
            return bundle is AssetView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! AssetView
        } else {
            return bundles.last as! AssetView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    @IBAction func artButtonPressed(_ sender: Any) {
        delegate?.didSelectArt(self)
        self.removeFromSuperview()
    }
    
    @IBAction func textButtonPressed(_ sender: Any) {
        delegate?.didSelectText(self)
        self.removeFromSuperview()
    }
    
    @IBAction func gifButtonPressed(_ sender: Any) {
        delegate?.didSelectGif(self)
        self.removeFromSuperview()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        delegate?.didSelectBack(self)
        //self.removeFromSuperview()
    }
}
