//
//  AudioViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 5/19/22.
//

import UIKit

class AudioViewCell: UITableViewCell {
    
    @IBOutlet weak var waveformScrollView: UIScrollView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var leftPanImageView: UIImageView!
    @IBOutlet weak var rightPanImageView: UIImageView!
    @IBOutlet weak var centerImageView: UIImageView!
    
    @IBOutlet weak var leadingLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingRightConstraint: NSLayoutConstraint!
    
    var music: Music! {
        didSet {
            nameLabel.text = music.name.replacingOccurrences(of: ".mp3", with: "")
        }
    }
    
    var handleMusicEdit: ((Music) -> Void)? = nil
    var handleMusicDelete: ((Music) -> Void)? = nil

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    // MARK: - IBAction
    @IBAction func didTapEdit(_ sender: UIButton) {
        handleMusicEdit?(music)
    }
    
    @IBAction func didTapDelete(_ sender: UIButton) {
        
        let controller = UIAlertController(title: "", message: "Are you sure you want to delete?", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            
        }))
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.handleMusicDelete?(self.music)
        }))
        Utilities.topViewController().present(controller, animated: true, completion: nil)
    }
}
