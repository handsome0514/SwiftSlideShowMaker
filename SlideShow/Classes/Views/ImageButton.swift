//
//  ImageButton.swift
//  SlideShow
//
//  Created by Hua Wan on 9/15/21.
//

import UIKit

class ImageButton: UIButton {
    
    enum Direction {
        case top
        case topOffset
        case left
    }

    var direction: ImageButton.Direction = .left {
        didSet {
            layoutIfNeeded()
        }
    }
    
    var offset: CGFloat = 0.0 {
        didSet {
            layoutIfNeeded()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        switch direction {
        case .left:
            let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 30.0 : 60.0
            if let imageView = self.imageView {
                imageView.frame = CGRect(x: bounds.width / 2.0 - imageView.frame.width - offset, y: (bounds.height - imageView.frame.height) / 2.0, width: imageView.frame.width, height: imageView.frame.height)
            }
            
            if let titleLabel = self.titleLabel {
                titleLabel.frame = CGRect(x: bounds.width / 2.0 - offset / 2.0, y: (bounds.height - titleLabel.frame.height) / 2.0, width: titleLabel.frame.width, height: titleLabel.frame.height)
            }
        case .top:
            if let imageView = self.imageView {
                imageView.frame = CGRect(x: (bounds.width - imageView.frame.width) / 2.0, y: (bounds.height / 2.0 - imageView.frame.height) / 2.0, width: imageView.frame.width, height: imageView.frame.height)
            }
            
            if let titleLabel = self.titleLabel {
                titleLabel.textAlignment = .center
                titleLabel.frame = CGRect(x: 0, y: bounds.height / 2.0, width: bounds.width, height: bounds.height / 2.0)
            }
        case .topOffset:
            if let imageView = self.imageView {
                imageView.frame = CGRect(x: (bounds.width - imageView.frame.width) / 2.0, y: (bounds.height / 2.0 - imageView.frame.height) / 2.0 + offset, width: imageView.frame.width, height: imageView.frame.height)
            }
            
            if let titleLabel = self.titleLabel {
                titleLabel.textAlignment = .center
                titleLabel.frame = CGRect(x: 0, y: bounds.height / 2.0 - offset / 5.0, width: bounds.width, height: bounds.height / 2.0)
            }
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
