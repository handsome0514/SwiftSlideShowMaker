//
//  ResolutionViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 5/13/22.
//

import UIKit

class ResolutionViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var sizeLabel: UILabel!
    @IBOutlet weak var selectionView: GradientSelectView!
    
    var isSelection: Bool = false {
        didSet {
            selectionView.isHidden = !isSelection
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        selectionView.colors = [UIColor("#4A9DB0").cgColor, UIColor("#63ABAE").cgColor, UIColor("#4A9DB0").cgColor]
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        selectionView.refresh()
    }
}
