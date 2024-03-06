//
//  GifsView.swift
//  SlideShow
//
//  Created by Mobile Master on 6/10/22.
//

import UIKit
import GiphyUISDK

struct GiphyGif {
    var id: String?
    var displayURL: String?
    var originalURL: String?
    var width: Double?
    var height: Double?
}

class GifsView: UIView {

    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var giphysCollectionView: UICollectionView!
    
    var media: Media! {
        didSet {
            
        }
    }
    
    class func loadFromNib() -> GifsView {
        let bundles = Bundle.main.loadNibNamed("GifsView", owner: self, options: nil)!.filter { bundle in
            return bundle is GifsView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! GifsView
        } else {
            return bundles.last as! GifsView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        searchTextField.attributedPlaceholder = NSAttributedString(string: "Search GIPHY", attributes: [.font: searchTextField.font!, .foregroundColor: UIColor.lightGray])
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    fileprivate func searchGIPHY(_ key: String) {
        
    }
    
    @objc fileprivate func handleKeyboardShow(_ notification: Notification) {
        guard let view = self.superview?.superview else { return }
        if let userInfo = notification.userInfo, let value = userInfo["UIKeyboardFrameEndUserInfoKey"] as? NSValue {
            let rect = value.cgRectValue
            let frame = searchView.convert(searchView.frame, to: view)
            let offset = frame.origin.y - rect.origin.y
            view.frame = CGRect(origin: CGPoint(x: view.frame.origin.x, y: -offset - frame.height), size: view.frame.size)
        }
    }
    
    @objc fileprivate func handleKeyboardHide(_ notification: Notification) {
        guard let view = self.superview?.superview else { return }
        view.frame = view.bounds
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension GifsView: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchGIPHY(textField.text!)
        textField.resignFirstResponder()
        return true
    }
}
