//
//  UIViewExtension.swift
//  UIViewExtension
//
//  Created by Artyom Rumyantsev on 9/3/21.
//

import UIKit

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        layer.mask = mask
    }
    
    @objc func addShadows(_ opacity: Float = 0.5, _ color: UIColor = .black, _ radius: CGFloat = 0) {
        layer.cornerRadius = radius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = opacity
        layer.shadowRadius = 8.0
        layer.masksToBounds = false
    }
    
    @objc func addRoundedShadows(_ opacity: Float = 0.5, _ color: UIColor = .black) {
        layer.cornerRadius = self.bounds.height / 2.0
        layer.shadowColor = color.cgColor
        layer.shadowOffset = .zero
        layer.shadowOpacity = opacity
        layer.shadowRadius = 8.0
    }
}
