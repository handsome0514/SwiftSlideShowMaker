//
//  SetupViewController.swift
//  SlideShow
//
//  Created by Hua Wan on 9/20/21.
//

import UIKit
import SwiftColor
import Photos

class SetupViewController: UIViewController {

    @IBOutlet weak var nameView: UIView!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var ratiosView: UIView!
    @IBOutlet weak var ratiosContentView: UIView!
    @IBOutlet weak var nextButton: UIButton!
    
    @IBOutlet weak var widthRatiosConstraint: NSLayoutConstraint!
    
    fileprivate var selectedRatioView: UIView!
    
    var selectedAssets: [MediaAsset] = []
    var selectedRatio = RatioType.original
    var orderType: OrderType = .custom
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        nameView.layer.borderWidth = 1.0
        nameView.layer.borderColor = UIColor("#3e3d3f").cgColor
        
        for view in ratiosContentView.subviews {
            if view.tag >= 100 {
                view.layer.borderColor = UIColor.clear.cgColor
            }
        }
        
        checkNextButton(nameTextField.text!)
        
        let project = ProjectManager.current
        nameTextField.text = project.name
        checkNextButton(project.name)
        
        deselectRatioViews()
        
        selectedRatio = RatioType(rawValue: project.ratio)!
        
        selectRatioView(selectedRatio)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy"
        nameTextField.text = "Project \(dateFormatter.string(from: Date()))"
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        widthRatiosConstraint.constant = UIDevice.current.userInterfaceIdiom == .phone ? fmin(ratiosView.frame.width, ratiosView.frame.height) : fmax(ratiosView.frame.width, ratiosView.frame.height)
    }
    
    fileprivate func checkNextButton(_ text: String) {
        /*if text.isEmpty {
            nextButton.isEnabled = false
            nextButton.backgroundColor = UIColor("#F0F0F0")
        } else {*/
            nextButton.isEnabled = true
        //}
    }
    
    fileprivate func initRatioView(_ ratio: CGFloat) {
        
    }
    
    fileprivate func deselectRatioViews() {
        for rawValue in 1 ... 4 {
            let ratioView = ratiosContentView.viewWithTag(100 + rawValue)!
            let gradientImageView = ratioView.viewWithTag(ratioView.tag * 10 + 1) as! GradientImageView
            gradientImageView.layer.borderWidth = 1.0
            gradientImageView.layer.borderColor = UIColor("#3e3d3f").cgColor
            gradientImageView.colors = [UIColor.clear.cgColor, UIColor("#3e3d3f").withAlphaComponent(0.6).cgColor]
            let imageView = ratioView.viewWithTag(ratioView.tag * 10 + 2) as! UIImageView
            imageView.image = UIImage(named: "IconNoSelected")
            var label = ratioView.viewWithTag(ratioView.tag * 10 + 3) as! UILabel
            label.textColor = .white
            label = ratioView.viewWithTag(ratioView.tag * 10 + 4) as! UILabel
            label.textColor = UIColor.white.withAlphaComponent(0.6)
        }
    }
    
    fileprivate func selectRatioView(_ ratio: RatioType) {
        let rawValue = ratio.rawValue
        let ratioView = ratiosContentView.viewWithTag(rawValue)!
        let gradientImageView = ratioView.viewWithTag(ratioView.tag * 10 + 1) as! GradientImageView
        gradientImageView.layer.borderWidth = 1.0
        gradientImageView.layer.borderColor = UIColor("#00f8f5").cgColor
        gradientImageView.colors = [UIColor.clear.cgColor, UIColor("#00f8f5").withAlphaComponent(0.6).cgColor]
        let imageView = ratioView.viewWithTag(ratioView.tag * 10 + 2) as! UIImageView
        imageView.image = UIImage(named: "IconSelected")
        var label = ratioView.viewWithTag(ratioView.tag * 10 + 3) as! UILabel
        label.textColor = UIColor("#00f8f5")
        label = ratioView.viewWithTag(ratioView.tag * 10 + 4) as! UILabel
        label.textColor = UIColor("#00f8f5")
    }

    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "LoadingViewController" {
            let controller = segue.destination as! LoadingViewController
            controller.selectedAssets = selectedAssets
        } else if segue.identifier == "RenameViewController" {
            let controller = segue.destination as! RenameViewController
            controller.didChangeName = { name in
                self.nameTextField.text = name
            }
        }
    }

    // MARK: - IBAction
    @IBAction func backButtonPressed(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func ratioButtonPressed(_ sender: UIButton) {
        let view = sender.superview!
        if selectedRatioView == view {
            return
        }
        
        deselectRatioViews()
        
        selectedRatio = RatioType(rawValue: view.tag)!
        
        selectRatioView(selectedRatio)
    }
    
    @IBAction func nextButtonPressed(_ sender: UIButton) {
        if ProjectManager.shared.isEditing == true {
            //let storyboard = UIStoryboard(name: UIDevice.current.userInterfaceIdiom == .phone ? "Edit" : "Edit_iPad", bundle: nil)
            //let controller = storyboard.instantiateInitialViewController()!
            //navigationController?.pushViewController(controller, animated: true)
            performSegue(withIdentifier: "LoadingViewController", sender: nil)
            do {
                try sharedRealm.write {
                    ProjectManager.current.name = nameTextField.text!
                    ProjectManager.current.ratio = selectedRatio.rawValue
                    ProjectManager.current.orderType = orderType.rawValue
                }
            } catch {
                print(error.localizedDescription)
            }
        } else {
            ProjectManager.current.name = nameTextField.text!
            ProjectManager.current.ratio = selectedRatio.rawValue
            ProjectManager.current.orderType = orderType.rawValue
            performSegue(withIdentifier: "LoadingViewController", sender: nil)
        }
    }
}

extension SetupViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        performSegue(withIdentifier: "RenameViewController", sender: nil)
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        checkNextButton(text)
        return true
    }
}
