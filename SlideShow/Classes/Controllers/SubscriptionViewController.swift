//
//  SubscriptionViewController.swift
//  SlideShow
//
//  Created by Hua Wan on 4/20/22.
//

import UIKit
import SVProgressHUD

class SubscriptionViewController: UIViewController {

    @IBOutlet weak var descriptionTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineSpacing = -4.0
        let attributedText =  NSMutableAttributedString(string: descriptionTextView.text!, attributes: [.font: descriptionTextView.font!, .foregroundColor: UIColor.white, .paragraphStyle: paragraph])
        let termsRange = (descriptionTextView.text! as NSString).range(of: "Terms and Condition")
        attributedText.addAttributes([.foregroundColor: UIColor("#FFDE17"), .underlineStyle: NSUnderlineStyle.single.rawValue, .underlineColor: UIColor("#FFDE17")], range: termsRange)
        let privacyRange = (descriptionTextView.text! as NSString).range(of: "Privacy Policy")
        attributedText.addAttributes([.foregroundColor: UIColor("#FFDE17"), .underlineStyle: NSUnderlineStyle.single.rawValue, .underlineColor: UIColor("#FFDE17")], range: privacyRange)
        
        descriptionTextView.attributedText = attributedText
        descriptionTextView.addClickable(to: termsRange, privacyRange) { range in
            if range.location == termsRange.location {
                UIApplication.shared.open(URL(string: "https://www.grassapper.com/terms-and-conditions")!, options: [:], completionHandler: nil)
            } else {
                UIApplication.shared.open(URL(string: "https://www.grassapper.com/application-privacy-policy")!, options: [:], completionHandler: nil)
            }
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - IBAction
    @IBAction func backButtonPressed(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func restoreButtonPressed(_ sender: UIButton) {
        SVProgressHUD.show()
        PurchaseManager.sharedManager.restore()
    }
}
