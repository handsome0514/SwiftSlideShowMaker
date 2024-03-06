//
//  ArtViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 9/29/21.
//

import UIKit
import SwiftColor

class ArtViewCell: UICollectionViewCell {

    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var artImageView: UIImageView!
    @IBOutlet weak var checkImageView: UIImageView!
    
    var artImage: UIImage! {
        didSet {
            artImageView.image = artImage
        }
    }
    
    var isSelection: Bool = false {
        didSet {
            if isSelection {
                checkImageView.isHidden = false
                backgroundImageView.backgroundColor = UIColor("#FF0047")
            } else {
                checkImageView.isHidden = true
                backgroundImageView.backgroundColor = UIColor("#303030")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
