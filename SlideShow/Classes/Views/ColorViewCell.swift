//
//  ColorViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 9/27/21.
//

import UIKit

class ColorViewCell: UICollectionViewCell {

    @IBOutlet weak var colorImageView: UIImageView!
    
    var color: UIColor = .clear {
        didSet {
            colorImageView.image = nil
            colorImageView.backgroundColor = color
        }
    }
    
    var icon: UIImage! {
        didSet {
            colorImageView.image = icon
            colorImageView.backgroundColor = .clear
        }
    }
    
    var colorIndex: Int = 0
    
    var isSelection: Bool = false {
        didSet {
            if isSelection {
                colorImageView.layer.borderColor = MAIN_ACTIVE_COLOR_1.cgColor
            } else if colorIndex == 7 {
                colorImageView.layer.borderColor = UIColor.lightGray.cgColor
            } else {
                colorImageView.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }
    
    var cellSize: CGSize! {
        didSet {
            colorImageView.layer.cornerRadius = frame.size.width / 2.0
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        colorImageView.layer.borderWidth = 2.0
    }
}
