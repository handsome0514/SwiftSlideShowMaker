//
//  ResolutionView.swift
//  SlideShow
//
//  Created by Hua Wan on 5/13/22.
//

import UIKit

class ResolutionView: UIView {

    @IBOutlet weak var tableView: UITableView!
    
    fileprivate var settings: [String] = [AVAssetExportPreset3840x2160, AVAssetExportPresetHighestQuality, AVAssetExportPreset1280x720, AVAssetExportPreset960x540, AVAssetExportPreset640x480]
    fileprivate var names: [String] = ["Ultra - 4k", "Full HD - 1080p", "HD - 720p", "Large - 540p", "Medium - 320p"]
    fileprivate var selectedIndex: Int = 1
    
    var selectionAlpha: CGFloat = 0.0
    
    class func loadFromNib() -> ResolutionView {
        let bundles = Bundle.main.loadNibNamed("ResolutionView", owner: self, options: nil)!.filter { bundle in
            return bundle is ResolutionView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! ResolutionView
        } else {
            return bundles.last as! ResolutionView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        tableView.register(UINib(nibName: "ResolutionViewCell", bundle: nil), forCellReuseIdentifier: "ResolutionViewCell")
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    func reloadData() {
        tableView.reloadData()
    }
}

extension ResolutionView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResolutionViewCell", for: indexPath) as! ResolutionViewCell
        cell.nameLabel.text = names[indexPath.item]
        cell.isSelection = indexPath.row == selectedIndex
        cell.selectionView.alpha = selectionAlpha
        return cell
    }
}

extension ResolutionView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndex = indexPath.item
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}
