//
//  AlbumViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 9/16/21.
//

import UIKit

class AlbumViewCell: UICollectionViewCell {
    @IBOutlet weak var albumNameLabel: UILabel!
    
    var isSelection: Bool = false {
        didSet {
            if isSelection {
                albumNameLabel.textColor = .white
            } else {
                albumNameLabel.textColor = UIColor.white.withAlphaComponent(0.6)
            }
        }
    }
}
