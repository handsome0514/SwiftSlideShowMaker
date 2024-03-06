//
//  String+Extension.swift
//  SlideShow
//
//  Created by Hua Wan on 9/17/21.
//

import Foundation
import UIKit

extension String {
    func size(_ maxWidth: CGFloat = .infinity, _ maxHeight: CGFloat = 1024, _ attributes: [NSAttributedString.Key: Any]) -> CGSize {
        let bounding = (self as NSString).boundingRect(with: CGSize(width: maxWidth, height: maxHeight), options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)
        return bounding.size
    }
}
