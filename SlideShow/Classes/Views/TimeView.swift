//
//  TimeView.swift
//  SlideShow
//
//  Created by Hua Wan on 9/21/21.
//

import UIKit

protocol TimeViewDelegate {
    func didChangeImageDuration(_ time: CGFloat)
}

class TimeView: UIView {

    @IBOutlet weak var imageDurationLabel: UILabel!
    @IBOutlet weak var totalDurationLabel: UILabel!
    @IBOutlet weak var timeSlider: UISlider!
    @IBOutlet weak var lockButton: UIButton!
    
    var project: Project! {
        didSet {
            imageDurationLabel.text = String(format: "%.1fs", Float(CGFloat(project.imageDuration)))
            timeSlider.value = Float(CGFloat(project.imageDuration))
            totalDurationLabel.text = Utilities.timeString(Int(project.duration(nil)))
        }
    }
    
    var parentViewController: UIViewController!
    var delegate: TimeViewDelegate? = nil
    
    class func loadFromNib() -> TimeView {
        let bundles = Bundle.main.loadNibNamed("TimeView", owner: self, options: nil)!.filter { bundle in
            return bundle is TimeView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! TimeView
        } else {
            return bundles.last as! TimeView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //timeSlider.setMinimumTrackImage(UIImage(named: "SliderMin"), for: .normal)
        //timeSlider.setMaximumTrackImage(UIImage(named: "SliderMax"), for: .normal)
        timeSlider.setThumbImage(UIImage(named: "SliderThumb"), for: .normal)
        
        lockButton.isHidden = PurchaseManager.sharedManager.isPurchased()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleDidPurchaseNotification(_:)), name: NSNotification.Name(rawValue: "ProductPurchased"), object: nil)
    }
    
    @objc func handleDidPurchaseNotification(_ notification: Notification) {
        lockButton.isHidden = true
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    // MARK: - IBAction
    @IBAction func lockButtonPressed(_ sender: Any) {
        PurchaseView.show().parentViewController = parentViewController
    }
    
    @IBAction func timeSliderChanged(_ sender: Any) {
        let value = timeSlider.value
        if value >= 4 && PurchaseManager.sharedManager.isPurchased() == false {
            timeSlider.value = 4
            PurchaseView.show().parentViewController = parentViewController
            return
        }
        
        delegate?.didChangeImageDuration(CGFloat(value))
        
        imageDurationLabel.text = String(format: "%.1fs", value)
        totalDurationLabel.text = String(format: "%.1fs", ProjectManager.current.duration(nil))
        //totalDurationLabel.text = Utilities.timeString(Int(ProjectManager.current.duration(nil)))
    }
}
