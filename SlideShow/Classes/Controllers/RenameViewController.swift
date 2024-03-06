//
//  RenameViewController.swift
//  SlideShow
//
//  Created by Hua Wan on 4/20/22.
//

import UIKit

class RenameViewController: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var bottomNameConstraint: NSLayoutConstraint!
    
    var didChangeName: ((String) -> Void)? = nil
    var name: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        nameTextField.text = name
        nameTextField.becomeFirstResponder()
        nameTextField.selectAll(nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func handleKeyboardShow(_ notification: Notification) {
        if let rect = notification.userInfo?["UIKeyboardFrameEndUserInfoKey"] as? NSValue {
            let rect = rect.cgRectValue
            bottomNameConstraint.constant = rect.height
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
    @IBAction func didTapClose(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapNext(_ sender: Any) {
        didChangeName?(nameTextField.text!)
        dismiss(animated: true, completion: nil)
    }
}
