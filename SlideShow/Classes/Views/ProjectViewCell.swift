//
//  ProjectViewCell.swift
//  SlideShow
//
//  Created by Hua Wan on 9/15/21.
//

import UIKit

protocol ProjectViewCellDelegate {
    func didTapOption(_ cell: ProjectViewCell)
}

class ProjectViewCell: UICollectionViewCell {
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    var delegate: ProjectViewCellDelegate? = nil
    
    var project: Project! {
        didSet {
            nameLabel.text = project.name
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MMMM dd, yyyy"
            dateLabel.text = dateFormatter.string(from: project.modifiedDate)
            if project.name == "" {
                dateFormatter.dateFormat = "MM-dd-yyyy"
                nameLabel.text = "Project \(dateFormatter.string(from: project.createdDate))"
            }
            
            if let media = project.medias.first {
                if media.type == MediaType.image.rawValue {
                    thumbImageView.image = UIImage(contentsOfFile: media.path())
                } else {
                    thumbImageView.image = Utilities.generateThumbImage(videoURL: URL(fileURLWithPath: media.path()))
                }
            }
        }
    }
    
    func updateName() {
        nameLabel.text = project.name
    }
    
    // MARK: - IBAction
    @IBAction func optionButtonPressed(_ sender: Any) {
        delegate?.didTapOption(self)
    }
}
