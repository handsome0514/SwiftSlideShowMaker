//
//  UIFont+Extension.swift
//  SlideShow
//
//  Created by Hua Wan on 9/17/21.
//

import Foundation
import UIKit

extension UIFont {
    class func regular(size: CGFloat) -> UIFont? {
        return UIFont(name: "Poppins-Regular", size: size)
    }
    
    class func medium(size: CGFloat) -> UIFont? {
        return UIFont(name: "Poppins-Medium", size: size)
    }
    
    class func bold(size: CGFloat) -> UIFont? {
        return UIFont(name: "Poppins-Bold", size: size)
    }
    
    class func semiBold(size: CGFloat) -> UIFont? {
        return UIFont(name: "Poppins-SemiBold", size: size)
    }
}
