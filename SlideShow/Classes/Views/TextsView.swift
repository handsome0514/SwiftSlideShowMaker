//
//  TextsView.swift
//  SlideShow
//
//  Created by Hua Wan on 9/29/21.
//

import UIKit

enum TextOption {
    case letterSpacing
    case verticalSpacing
}

protocol TextsViewDelegate {
    func didSelectDone(_ view: TextsView)
    func didSelectKeyboard(_ view: TextsView)
    func didSelectFont(_ view: TextsView)
    func didSelectColor(_ view: TextsView)
    func didSelectFont(_ view: TextsView, _ fontName: String)
    func didSelectColor(_ view: TextsView, _ color: UIColor, _ index: Int)
    func didSelectOption(_ view: TextsView)
    func didSelectOption(_ view: TextsView, _ option: TextOption, _ value: CGFloat)
}

let MAX_FONT_SIZE: Float = 500
let MIN_FONT_SIZE: Float = 16

class TextsView: UIView {

    @IBOutlet weak var topMenuView: UIView!
    @IBOutlet weak var fontsPickerView: UIPickerView!
    @IBOutlet weak var fontSizeSlider: UISlider!
    @IBOutlet weak var opacitySlider: UISlider!
    @IBOutlet weak var colorsCollectionView: UICollectionView!
    @IBOutlet weak var letterSpacingSlider: UISlider!
    @IBOutlet weak var verticalSpacingSlider: UISlider!
    
    @IBOutlet weak var fontsView: UIView!
    @IBOutlet weak var textEditView: UIView!
    @IBOutlet weak var alignView: UIView!
    
    @IBOutlet weak var keyboardButton: UIButton!
    @IBOutlet weak var fontsButton: UIButton!
    @IBOutlet weak var textEditButton: UIButton!
    @IBOutlet weak var alignButton: UIButton!
    
    static var arrayFonts: [String] = []
    var delegate: TextsViewDelegate? = nil
    var textView: TVTextView! {
        didSet {
            fontSizeSlider.value = Float(textView.fontSize)
            opacitySlider.value = Float(textView.textOpacity)
            
            letterSpacingSlider.value = Float(self.textView.hSpacing * 10)
            verticalSpacingSlider.value = Float(self.textView.vSpacing * 10)
        }
    }
    
    var text: Text! {
        didSet {
            fontSizeSlider.value = text.fontSize
            opacitySlider.value = text.opacity
            
            letterSpacingSlider.value = Float(self.textView.hSpacing * 10)
            verticalSpacingSlider.value = Float(self.textView.vSpacing * 10)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadFonts()
        
        fontsPickerView.reloadAllComponents()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        loadFonts()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    class func loadFromNib() -> TextsView {
        let bundles = Bundle.main.loadNibNamed("TextsView", owner: self, options: nil)!.filter { bundle in
            return bundle is TextsView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! TextsView
        } else {
            return bundles.last as! TextsView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)

        letterSpacingSlider.minimumValue = -20
        letterSpacingSlider.maximumValue = 80
        
        verticalSpacingSlider.minimumValue = 0
        verticalSpacingSlider.maximumValue = 100
        
        loadFonts()
        
        colorsCollectionView.register(UINib(nibName: "ColorViewCell", bundle: nil), forCellWithReuseIdentifier: "ColorViewCell")
        
        fontSizeSlider.minimumValue = MIN_FONT_SIZE
        fontSizeSlider.maximumValue = MAX_FONT_SIZE
        fontSizeSlider.setMinimumTrackImage(UIImage(named: "SliderMin"), for: .normal)
        fontSizeSlider.setMaximumTrackImage(UIImage(named: "SliderMax"), for: .normal)
        fontSizeSlider.setThumbImage(UIImage(named: "SliderThumb"), for: .normal)
        
        opacitySlider.setMinimumTrackImage(UIImage(named: "SliderMin"), for: .normal)
        opacitySlider.setMaximumTrackImage(UIImage(named: "SliderMax"), for: .normal)
        opacitySlider.setThumbImage(UIImage(named: "SliderThumb"), for: .normal)
        
        letterSpacingSlider.setMinimumTrackImage(UIImage(named: "SliderMin"), for: .normal)
        letterSpacingSlider.setMaximumTrackImage(UIImage(named: "SliderMax"), for: .normal)
        letterSpacingSlider.setThumbImage(UIImage(named: "SliderThumb"), for: .normal)
        
        verticalSpacingSlider.setMinimumTrackImage(UIImage(named: "SliderMin"), for: .normal)
        verticalSpacingSlider.setMaximumTrackImage(UIImage(named: "SliderMax"), for: .normal)
        verticalSpacingSlider.setThumbImage(UIImage(named: "SliderThumb"), for: .normal)
    }
    
    func loadFonts() {
        TextsView.arrayFonts = ["Andes",
                                "Arial-Black",
                                "ArialMT",
                                "BacktoBlackDemo",
                                "BodoniFLF-Roman",
                                "Bisous",
                                "Blacksword",
                                "BradleyHandITCTT-Bold",
                                "BrushScriptStd",
                                "DINAlternate-Bold",
                                "Futura-Medium",
                                "Georgia-Bold",
                                "GillSans",
                                "GlossAndBloom",
                                "Jellyka---le-Grand-Saut-Textual",
                                "HighTide",
                                "JellykaCuttyCupcakes",
                                "KaushanScript-Regular",
                                "lazer84",
                                "DKLemonYellowSun",
                                "Limelight-Regular",
                                "Montserrat-ExtraLight",
                                "MyriadPro-CondIt",
                                "NuevaStd-CondItalic",
                                "On-Air-Inline",
                                "Phosphate-Inline",
                                "Pristina-Regular",
                                "Roboto-Thin",
                                "RoundedElegance-Regular",
                                "SFProDisplay-Light",
                                "SavoyeLetPlain",
                                "SignPainter-HouseScript",
                                "SkarpaLT",
                                "DKSleepyTime",
                                "SnellRoundhand",
                                "StencilStd",
                                "TimesNewRomanPSMT",
                                "TypoRound-LightItalicDemo",
                                "VCROSDMono",
                                "VertigoFLF"]
    }
    
    @objc func handleKeyboardWillShow(_ notification: Notification) {
        if textView != nil {
            textView.showBorder = false
        }
        if let userInfo = notification.userInfo, let value = userInfo["UIKeyboardFrameEndUserInfoKey"] as? NSValue, let _ = self.superview {
            let frame = value.cgRectValue
            self.frame.origin.y = frame.origin.y - topMenuView.frame.height
        }
    }
    
    @objc func handleKeyboardWillHide(_ notification: Notification) {
        if let superview = self.superview {
            self.frame.origin.y = superview.frame.height - self.frame.height
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    fileprivate func hideAllViews() {
        fontsView.isHidden = true
        textEditView.isHidden = true
        alignView.isHidden = true
    }
    
    fileprivate func deselectAllButtons() {
        keyboardButton.isSelected = false
        fontsButton.isSelected = false
        textEditButton.isSelected = false
        alignButton.isSelected = false
    }

    // MARK: - IBAction
    @IBAction func didTapKeyboardButton(_ sender: Any) {
        hideAllViews()
        deselectAllButtons()
        keyboardButton.isSelected = true
        textView.showKeyboard()
    }
    
    @IBAction func didTapFontButton(_ sender: Any) {
        hideAllViews()
        deselectAllButtons()
        fontsView.isHidden = false
        fontsButton.isSelected = true
        textView.dismissKeyboard()
    }
    
    @IBAction func didTapEditButton(_ sender: Any) {
        hideAllViews()
        deselectAllButtons()
        textEditView.isHidden = false
        textEditButton.isSelected = true
        textView.dismissKeyboard()
    }
    
    @IBAction func didTapAlignButton(_ sender: Any) {
        hideAllViews()
        deselectAllButtons()
        alignView.isHidden = false
        alignButton.isSelected = true
        textView.dismissKeyboard()
    }
    
    @IBAction func didTapSelectButton(_ sender: Any) {
        if textView != nil {
            textView.showBorder = true
        }
        delegate?.didSelectDone(self)
    }
    
    @IBAction func didChangeFontSize(_ sender: Any) {
        textView.fontSize = CGFloat(fontSizeSlider.value)
    }
    
    @IBAction func didChangeOpacity(_ sender: Any) {
        textView.textOpacity = CGFloat(opacitySlider.value)
    }
    
    @IBAction func didChangeLetterSpacing(_ sender: Any) {
        self.textView.hSpacing = CGFloat(letterSpacingSlider.value / 10.0)
        self.textView.updateAllTextAttribute()
    }
    
    @IBAction func didChangeVerticalSpacing(_ sender: Any) {
        self.textView.vSpacing = CGFloat(verticalSpacingSlider.value / 10.0)
        self.textView.updateAllTextAttribute()
    }
}

extension TextsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return APP_ARRAY_COLORS.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorViewCell", for: indexPath) as! ColorViewCell
        cell.color = UIColor(hexInt: APP_ARRAY_COLORS[indexPath.item])
        cell.colorIndex = indexPath.item
        cell.isSelection = indexPath.item == textView.colorIndex
        cell.cellSize = CGSize(width: collectionView.frame.height, height: collectionView.frame.height)
        return cell
    }
}

extension TextsView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: IndexPath(item: textView.colorIndex, section: 0)) as? ColorViewCell {
            cell.isSelection = false
        }
        textView.colorIndex = indexPath.item
        textView.textColor = UIColor(hexInt: APP_ARRAY_COLORS[indexPath.item])
        if let cell = collectionView.cellForItem(at: indexPath) as? ColorViewCell {
            cell.isSelection = true
        }
        delegate?.didSelectColor(self, UIColor(hexInt: APP_ARRAY_COLORS[indexPath.item]), indexPath.item)
    }
}

extension TextsView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.height
        return CGSize(width: width, height: collectionView.frame.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
}

extension TextsView: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return TextsView.arrayFonts.count
    }
}

extension TextsView: UIPickerViewDelegate {
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        if let view = view {
            let label = view.viewWithTag(804) as! UILabel
            let fontSize: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 16.0 : 24
            label.font = UIFont(name: TextsView.arrayFonts[row], size: fontSize)
            label.text = label.font.familyName
            label.textColor = .white
            return view
        } else {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: pickerView.frame.size.width, height: 44))
            let label = UILabel(frame: view.bounds)
            let fontSize: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 16.0 : 24
            label.font = UIFont(name: TextsView.arrayFonts[row], size: fontSize)
            label.text = label.font.familyName
            label.textColor = .white//.black
            label.textAlignment = .center
            label.tag = 804
            view.addSubview(label)
            return view
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return UIDevice.current.userInterfaceIdiom == .phone ? 44 : 64
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        textView.setTextFontWithName(TextsView.arrayFonts[row])
        textView.fontIndex = row
        delegate?.didSelectFont(self, TextsView.arrayFonts[row])
    }
}
