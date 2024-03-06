//
//  MusicEditView.swift
//  SlideShow
//
//  Created by Hua Wan on 10/12/21.
//

import UIKit

protocol MusicEditViewDelegate {
    func didChangeValue()
}

class MusicEditView: UIView {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var repeatButton: UIButton!
    @IBOutlet weak var fadeinButton: UIButton!
    @IBOutlet weak var fadeoutButton: UIButton!
    @IBOutlet weak var volumeSlider: UISlider!
    
    var delegate: MusicEditViewDelegate? = nil
    
    var music: Music? = nil {
        didSet {
            if let music = music {
                repeatButton.isSelected = music.isRepeat
                fadeinButton.isSelected = music.isFadein
                fadeoutButton.isSelected = music.isFadeout
                volumeSlider.value = music.volume
                nameLabel.text = music.name.replacingOccurrences(of: ".mp3", with: "")
            } else {
                fadeinButton.isSelected = false
                fadeoutButton.isSelected = false
                volumeSlider.value = 0.5
                nameLabel.text = "Rec 1"
            }
        }
    }
    
    var changeButtonHandler: (() -> Void)? = nil
    var deleteButtonHandler: (() -> Void)? = nil

    class func loadFromNib() -> MusicEditView {
        let bundles = Bundle.main.loadNibNamed("MusicEditView", owner: self, options: nil)!.filter { bundle in
            return bundle is MusicEditView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! MusicEditView
        } else {
            return bundles.last as! MusicEditView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        //let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 4.0 : 8.0
        //volumeSlider.setMinimumTrackImage(UIImage(named: "SliderMin"), for: .normal)
        //volumeSlider.setMaximumTrackImage(UIImage(named: "SliderMax"), for: .normal)
        volumeSlider.setThumbImage(UIImage(named: "SliderThumb"), for: .normal)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    // MARK: - IBAction
    @IBAction func fadeinButtonPressed(_ sender: Any) {
        fadeinButton.isSelected = !fadeinButton.isSelected
        if let music = music {
            do {
                try sharedRealm.write {
                    music.isFadein = fadeinButton.isSelected
                }
                
                delegate?.didChangeValue()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func fadeoutButtonPressed(_ sender: Any) {
        fadeoutButton.isSelected = !fadeoutButton.isSelected
        if let music = music {
            do {
                try sharedRealm.write {
                    music.isFadeout = fadeoutButton.isSelected
                }
                delegate?.didChangeValue()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func volumeSliderChanged(_ sender: Any) {
        //fadeLabel.text = "\(Int(volumeSlider.value * 100))%"
        if let music = music {
            do {
                try sharedRealm.write {
                    music.volume = volumeSlider.value
                }
                delegate?.didChangeValue()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    @IBAction func changeButtonPressed(_ sender: Any) {
        repeatButton.isSelected = !repeatButton.isSelected
        if let music = music {
            do {
                try sharedRealm.write {
                    music.isRepeat = repeatButton.isSelected
                }
            } catch {
                print(error.localizedDescription)
            }
        }
//        changeButtonHandler?()
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        let controller = UIAlertController(title: "", message: "Are you sure you want to delete?", preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            
        }))
        controller.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            self.deleteButtonHandler?()
        }))
        Utilities.topViewController().present(controller, animated: true, completion: nil)
    }
}
