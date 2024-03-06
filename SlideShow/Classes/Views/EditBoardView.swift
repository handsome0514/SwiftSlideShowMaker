//
//  EditBoardView.swift
//  SlideShow
//
//  Created by Hua Wan on 4/22/22.
//

import UIKit
import CoreMedia

enum EditItemType: Int {
    case add = 0
    case trim
    case time
    case size
    case volume
}

protocol EditBoardViewDelegate {
    func didSelectAssetView(_ view: EditBoardView)
    func didSelectTrimView(_ view: EditBoardView)
    func didChangeTrimView(_ view: EditBoardView, startTime: CMTime)
    func didChangeTrimView(_ view: EditBoardView, endTime: CMTime)
    func didDoneTrimView(_ view: EditBoardView, _ url: URL?, _ blururl: URL?)
    func didSelectTimeView(_ view: EditBoardView)
    func didSelectSizeView(_ view: EditBoardView)
    func didSelectVolumeView(_ view: EditBoardView)
    func didSelectSubview(_ view: EditBoardView)
    func didSelectText(_ view: EditBoardView)
    func didSelectDone(_ view: EditBoardView)
}

class EditBoardView: UIView {
    
    @IBOutlet weak var iconsView: UIView!
    @IBOutlet weak var doneButton: UIButton!
    
    fileprivate lazy var assetView: AssetView = {
        let view = AssetView.loadFromNib()
        view.frame = CGRect(x: 0, y: iconsView.frame.maxY, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY)
        view.delegate = self
        return view
    }()
    
    fileprivate lazy var artsView: ArtsView = {
        let view = ArtsView.loadFromNib()
        view.frame = CGRect(x: 0, y: iconsView.frame.maxY, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY)
        view.delegate = artsViewDelegate
        return view
    }()
    
    fileprivate lazy var gifsView: GifsView = {
        let view = GifsView.loadFromNib()
        view.frame = CGRect(x: 0, y: iconsView.frame.maxY, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY)
        //view.delegate = artsViewDelegate
        return view
    }()
    
    fileprivate lazy var trimView: TrimView = {
        let view = TrimView.loadFromNib()
        view.frame = CGRect(x: 0, y: iconsView.frame.maxY, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY)
        view.delegate = self
        return view
    }()
    
    fileprivate lazy var cropView: CropView = {
        let view = CropView.loadFromNib()
        view.project = project
        view.delegate = cropViewDelegate
        return view
    }()
    
    fileprivate lazy var timeView: TimeView = {
        let view = TimeView.loadFromNib()
        view.project = project
        view.delegate = timeViewDelegate
        view.parentViewController = parentViewController
        return view
    }()
    
    var selectedView: UIView!
    
    var selectedItemType: EditItemType = .add
    var cropViewDelegate: CropViewDelegate? = nil
    var timeViewDelegate: TimeViewDelegate? = nil
    var artsViewDelegate: ArtsViewDelegate? = nil
    
    var parentViewController: UIViewController!
    var project: Project!
    var delegate: EditBoardViewDelegate? = nil
    var selectedMediaIndex: Int = 0 {
        didSet {
            let media = project.medias[selectedMediaIndex]
            if media.type == MediaType.video.rawValue {
                button(for: .trim).isEnabled = true
                button(for: .volume).isEnabled = true
            } else {
                button(for: .trim).isEnabled = false
                button(for: .volume).isEnabled = false
            }
            
            if selectedView is TrimView {
                (selectedView as! TrimView).media = project.medias[selectedMediaIndex]
                delegate?.didSelectTrimView(self)
            }
        }
    }
    
    class func loadFromNib() -> EditBoardView {
        let bundles = Bundle.main.loadNibNamed("EditBoardView", owner: self, options: nil)!.filter { bundle in
            return bundle is EditBoardView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! EditBoardView
        } else {
            return bundles.last as! EditBoardView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let button = button(for: selectedItemType)
        button.isSelected = true
        addSubview(assetView)
        selectedView = assetView
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if selectedView != nil {
            selectedView.frame = CGRect(x: 0, y: iconsView.frame.maxY, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY)
        }
    }
    
    fileprivate func deselectAllItems() {
        for i in 0 ..< 5 {
            let button = iconsView.viewWithTag(10 + i) as! UIButton
            button.isSelected = false
        }
        selectedView.removeFromSuperview()
        selectedView = nil
    }
    
    fileprivate func button(for itemType: EditItemType) -> UIButton {
        let button = iconsView.viewWithTag(10 + itemType.rawValue) as! UIButton
        return button
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func hideAllSubviews() {
        artsView.isHidden = true
        gifsView.isHidden = true
    }
    
    func doneSubview() {
        iconsView.isHidden = false
        addSubview(selectedView)
        selectedView.isHidden = false
    }
    
    public func showSeekTime(_ time: CMTime) {
        trimView.showSeekTime(time)
    }

    // MARK: - IBAction
    @IBAction func addButtonPressed(_ sender: UIButton) {
        deselectAllItems()
        sender.isSelected = true
        addSubview(assetView)
        assetView.frame = CGRect(x: 0, y: iconsView.frame.maxY, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY)
        selectedView = assetView
    }
    
    @IBAction func trimButtonPressed(_ sender: UIButton) {
        deselectAllItems()
        sender.isSelected = true
        addSubview(trimView)
        trimView.frame = CGRect(x: 0, y: iconsView.frame.maxY, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY)
        trimView.media = project.medias[selectedMediaIndex]
        selectedView = trimView
        delegate?.didSelectTrimView(self)
        
    }
    
    @IBAction func timeButtonPressed(_ sender: UIButton) {
        deselectAllItems()
        sender.isSelected = true
        addSubview(timeView)
        timeView.frame = CGRect(x: 0, y: iconsView.frame.maxY, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY)
        selectedView = timeView
        //delegate?.didSelectSubview(self)
    }
    
    @IBAction func sizeButtonPressed(_ sender: UIButton) {
        deselectAllItems()
        sender.isSelected = true
        addSubview(cropView)
        cropView.frame = CGRect(x: 0, y: iconsView.frame.maxY, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY)
        selectedView = cropView
    }
    
    @IBAction func musicButtonPressed(_ sender: UIButton) {
        deselectAllItems()
        
    }
    
    @IBAction func doneButtonPressed(_ sender: UIButton) {
        
    }
}

extension EditBoardView: AssetViewDelegate {
    func didSelectArt(_ view: AssetView) {
        view.removeFromSuperview()
        artsView.frame = CGRect(x: 0, y: iconsView.frame.maxY - 32, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY + 32)
        artsView.media = ProjectManager.current.medias[selectedMediaIndex]
        artsView.isHidden = false
        addSubview(artsView)
        delegate?.didSelectSubview(self)
        iconsView.isHidden = true
    }
    
    func didSelectText(_ view: AssetView) {
        view.removeFromSuperview()
        //delegate?.didSelectSubview(self)
        delegate?.didSelectText(self)
    }
    
    func didSelectGif(_ view: AssetView) {
        view.removeFromSuperview()
        gifsView.frame = CGRect(x: 0, y: iconsView.frame.maxY - 32, width: self.frame.width, height: self.frame.height - iconsView.frame.maxY + 32)
        gifsView.media = ProjectManager.current.medias[selectedMediaIndex]
        gifsView.isHidden = false
        addSubview(gifsView)
        delegate?.didSelectSubview(self)
        iconsView.isHidden = true
    }
    
    func didSelectBack(_ view: AssetView) {
        delegate?.didSelectDone(self)
    }
}

extension EditBoardView: TrimViewDelegate {
    func didTrimDone(_ view: TrimView, _ url: URL?, _ blururl: URL?) {
        //trimView.removeFromSuperview()
        delegate?.didDoneTrimView(self, url, blururl)
    }
    
    func didChangeTrimView(_ view: TrimView, startTime: CMTime) {
        delegate?.didChangeTrimView(self, startTime: startTime)
    }
    
    func didChangeTrimView(_ view: TrimView, endTime: CMTime) {
        delegate?.didChangeTrimView(self, endTime: endTime)
    }
}
