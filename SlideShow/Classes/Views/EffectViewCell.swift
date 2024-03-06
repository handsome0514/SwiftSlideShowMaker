//
//  EffectViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 9/22/21.
//

import UIKit

class EffectViewCell: UICollectionViewCell {
    
    @IBOutlet weak var previewView: UIView!
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    var isSelection: Bool = false {
        didSet {
            if isSelection {
                nameLabel.textColor = MAIN_ACTIVE_COLOR_1
                thumbImageView.layer.borderColor = MAIN_ACTIVE_COLOR_1.cgColor
            } else {
                nameLabel.textColor = .white
                thumbImageView.layer.borderColor =  UIColor.clear.cgColor
            }
        }
    }
    
    var isLocked: Bool = false {
        didSet {
            
        }
    }
    
    var name: String = "" {
        didSet {
            nameLabel.text = name
        }
    }
    
    var thumbImage: UIImage! {
        didSet {
            thumbImageView.image = thumbImage
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        thumbImageView.layer.borderWidth = 2.0
        thumbImageView.layer.borderColor = UIColor.clear.cgColor
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            nameLabel.font = nameLabel.font.withSize(12.0)
        } else {
            nameLabel.font = nameLabel.font.withSize(16.0)
        }
    }
}
