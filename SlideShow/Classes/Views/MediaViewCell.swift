//
//  MediaViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 9/16/21.
//

import UIKit
import Photos
import SDWebImage

protocol MediaViewCellDelegate {
    func didTapRemove(_ cell: MediaViewCell)
}

class MediaViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var selectImageView: UIImageView!
    @IBOutlet weak var durationView: UIView!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var removeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    
    var isSelection: Bool = false {
        didSet {
            selectImageView.isHidden = !isSelection
        }
    }
    
    var isMoveSelection: Bool = false {
        didSet {
            selectImageView.isHidden = !isMoveSelection
            if removeButton != nil {
                removeButton.isHidden = isMoveSelection
            }
            if isMoveSelection {
                selectImageView.layer.borderWidth = 2.0
                selectImageView.layer.borderColor = MAIN_ACTIVE_COLOR_1.cgColor
            } else {
                selectImageView.layer.borderWidth = 0.0
                selectImageView.layer.borderColor = UIColor.clear.cgColor
            }
        }
    }
    
    var asset: PHAsset! {
        didSet {
            let options = PHImageRequestOptions()
            options.isNetworkAccessAllowed = true
            options.isSynchronous = true
            options.deliveryMode = .highQualityFormat
            PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: 200, height: 240), contentMode: .aspectFill, options: options) { (image, settings) in
                self.thumbImageView.image = image
            }
            
            durationView?.isHidden = asset.mediaType == .image
            if asset.mediaType == .video {
                let duration = Int(asset.duration)
                durationLabel?.text = Utilities.timeString(duration)
                durationView?.layoutIfNeeded()
                durationView?.roundCorners(corners: [.topLeft, .bottomRight], radius: 6.0)
            }
        }
    }
    
    var item: [String: Any] = [:] {
        didSet {
            thumbImageView.sd_setImage(with: URL(string: (item["Cover"] as! String).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!), completed: nil)
            titleLabel.text = (item["Name"] as! String)
        }
    }
    
    var delegate: MediaViewCellDelegate? = nil
    var cellIndex: Int = 0
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectImageView?.layer.borderWidth = 1.0
        selectImageView?.layer.borderColor = MAIN_ACTIVE_COLOR_1.cgColor
        
        durationView?.roundCorners(corners: [.topLeft, .bottomRight], radius: 6.0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        durationView?.roundCorners(corners: [.topLeft, .bottomRight], radius: 6.0)
    }
    
    // MARK: - IBAction
    @IBAction func removeButtonPressed(_ sender: Any) {
        delegate?.didTapRemove(self)
    }
}
