//
//  FrameRateViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 5/12/22.
//

import UIKit

class FrameRateViewCell: UICollectionViewCell {

    @IBOutlet weak var frameLabel: UILabel!
    @IBOutlet weak var FPSLabel: UILabel!
    
    var isSelection: Bool = false {
        didSet {
            if isSelection {
                backgroundColor = .black
                frameLabel.textColor = .white
                FPSLabel.textColor = .white
            } else {
                backgroundColor = .white
                frameLabel.textColor = .black
                FPSLabel.textColor = .black
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        layer.borderWidth = 1.0
        layer.borderColor = MAIN_ACTIVE_COLOR_1.cgColor
    }

}
