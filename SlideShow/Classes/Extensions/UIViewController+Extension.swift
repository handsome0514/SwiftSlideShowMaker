//
//  UIViewControllerExtension.swift
//  UIViewControllerExtension
//
//  Created by Artyom Rumyantsev on 9/3/21.
//

import UIKit

extension UIViewController {

    public func showAlertView(_ title: String, _ message: String, _ handler: (() -> Void)? = nil) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            handler?()
        }
        
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }
    
    public func showAlertView(_ title: String, _ message: String, _ cancel: String = "Cancel", _ confirm: String = "OK", _ handler: (() -> Void)? = nil) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: cancel, style: .cancel) { action in
            
        }
        
        let okAction = UIAlertAction(title: confirm, style: .default) { action in
            handler?()
        }
        
        controller.addAction(cancelAction)
        controller.addAction(okAction)
        present(controller, animated: true, completion: nil)
    }
}
