//
//  Image.swift
//  SlideShow
//
//  Created by Hua Wan on 9/23/21.
//

import UIKit
import RealmSwift

@objc class Image: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var category: String = ""
    @objc dynamic var filename: String = ""
    @objc dynamic var opacity: Float = 1.0
    @objc dynamic var rotation: Float = 0.0
    @objc dynamic var bounds: String = ""
    @objc dynamic var transform: String = ""
    @objc dynamic var center: String = ""
    @objc dynamic var zIndex: Int = 0
    @objc dynamic var order: Int = 0
    @objc dynamic var data: Data? = nil
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override func copy() -> Any {
        let copy = Image()
        copy.category = category
        copy.filename = filename
        copy.opacity = opacity
        copy.rotation = rotation
        copy.bounds = bounds
        copy.transform = transform
        copy.center = center
        copy.zIndex = zIndex
        copy.order = order
        copy.data = data
        return copy
    }
}
