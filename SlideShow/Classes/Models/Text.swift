//
//  Text.swift
//  SlideShow
//
//  Created by Hua Wan on 9/23/21.
//

import UIKit
import RealmSwift

@objc class Text: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var text: String = ""
    @objc dynamic var fontIndex: Int = 0
    @objc dynamic var fontSize: Float = 16.0
    @objc dynamic var colorIndex: Int = 0
    @objc dynamic var opacity: Float = 1.0
    @objc dynamic var vspacing: Float = 1.0
    @objc dynamic var hspacing: Float = 1.0
    @objc dynamic var rotation: Float = 0.0
    @objc dynamic var bounds: String = ""
    @objc dynamic var transform: String = ""
    @objc dynamic var center: String = ""
    @objc dynamic var zindex: Int = 0
    @objc dynamic var order: Int = 0
    @objc dynamic var data: Data? = nil
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override func copy() -> Any {
        let copy = Text()
        copy.text = text
        copy.fontIndex = fontIndex
        copy.fontSize = fontSize
        copy.colorIndex = colorIndex
        copy.opacity = opacity
        copy.vspacing = vspacing
        copy.hspacing = hspacing
        copy.rotation = rotation
        copy.bounds = bounds
        copy.transform = transform
        copy.center = center
        copy.zindex = zindex
        copy.order = order
        copy.data = data
        return copy
    }
}
