//
//  GradientSelectView.swift
//  SlideShow
//
//  Created by Hua Wan on 5/13/22.
//

import UIKit

class GradientSelectView: UIView {

    fileprivate var gradientLayer: CAGradientLayer!
    
    var colors: [CGColor] = [] {
        didSet {
            gradientLayer.frame = self.bounds
            gradientLayer.colors = colors
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    fileprivate func setupView() {
        gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = CGPoint(x: 0.0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.5)
        gradientLayer.frame = self.bounds
        layer.addSublayer(gradientLayer)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    func refresh() {
        gradientLayer.frame = self.bounds
    }
}
