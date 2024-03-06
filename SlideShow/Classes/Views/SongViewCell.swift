//
//  SongViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 5/19/22.
//

import UIKit
import SDWebImage

class SongViewCell: UITableViewCell {
    
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    
    var item: [String: Any] = [:] {
        didSet {
            //thumbImageView.sd_setImage(with: URL(string: item["Cover"] as! String), completed: nil)
            nameLabel.text = (item["Name"] as! String).replacingOccurrences(of: ".mp3", with: "")
            durationLabel.text = (item["Duration"] as! String)
        }
    }
    
    var isPlaying: Bool = false {
        didSet {
            playButton.isSelected = isPlaying
        }
    }
    
    var isSelection: Bool = false {
        didSet {
            selectedImageView.isHidden = !isSelection
        }
    }
    
    var didTapPlay: ((SongViewCell) -> Void)? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

    // MARK: - IBAction
    @IBAction func didTapPlay(_ sender: UIButton) {
        didTapPlay?(self)
    }
}
