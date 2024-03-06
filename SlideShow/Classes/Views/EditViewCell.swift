//
//  EditViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 9/22/21.
//

import UIKit

class EditViewCell: UICollectionViewCell {
    @IBOutlet weak var selectedImageView: UIImageView!
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var addImageView: UIImageView!
    @IBOutlet weak var durationView: UIView!
    @IBOutlet weak var durationLabel: UILabel!
    
    var media: Media! {
        didSet {
            if media == nil {
                thumbImageView.image = nil
                addImageView.isHidden = false
                durationView?.isHidden = true
                return
            }
            
            addImageView.isHidden = true
            if media.type == MediaType.image.rawValue {
                thumbImageView.image = UIImage(contentsOfFile: media.path())
            } else {
                thumbImageView.image = Utilities.generateThumbImage(videoURL: URL(fileURLWithPath: media.path()), maxSize: CGSize(width: 300, height: 400))
            }
            
            durationView?.isHidden = media.type == MediaType.image.rawValue
            if media.type == MediaType.video.rawValue {
                let duration = Int(media.duration())
                durationLabel?.text = Utilities.timeString(duration)
                durationView?.layoutIfNeeded()
                durationView?.roundCorners(corners: [.topRight, .bottomLeft], radius: 6.0)
            }
        }
    }
    
    var isSelection = false {
        didSet {
            selectedImageView.isHidden = !isSelection
            if isSelection {
                thumbImageView.layer.borderColor = UIColor.white.cgColor
            } else {
                thumbImageView.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }
    
    var isMoveSelection: Bool = false {
        didSet {
            if isMoveSelection {
                selectedImageView.isHidden = true
            } else {
                selectedImageView.isHidden = !isSelection
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        thumbImageView.layer.borderWidth = 2.0
        thumbImageView.layer.borderColor = UIColor.clear.cgColor
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            selectedImageView.layer.cornerRadius = 10
            thumbImageView.layer.cornerRadius = 10
            addImageView.layer.cornerRadius = 10
        } else {
            selectedImageView.layer.cornerRadius = 14
            thumbImageView.layer.cornerRadius = 14
            addImageView.layer.cornerRadius = 14
        }
    }
}
