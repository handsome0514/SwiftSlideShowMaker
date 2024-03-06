//
//  Music.swift
//  SlideShow
//
//  Created by Hua Wan on 9/22/21.
//

import UIKit
import RealmSwift

@objc class Music: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var projectId: String = ""
    @objc dynamic var filename: String = ""
    @objc dynamic var itunespath: String = ""
    @objc dynamic var start: Float = 0
    @objc dynamic var end: Float = 0
    @objc dynamic var scrollStart: Float = 0
    @objc dynamic var scrollEnd: Float = 0
    @objc dynamic var name: String = ""
    @objc dynamic var isRepeat: Bool = false
    @objc dynamic var isFadein: Bool = false
    @objc dynamic var isFadeout: Bool = true
    @objc dynamic var volume: Float = 0.5      // Music volume
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override func copy() -> Any {
        let copy = Music()
        copy.projectId = projectId
        copy.filename = Utilities.generateRandomFileName(fileExtension: "mp3")
        copy.itunespath = itunespath
        copy.start = start
        copy.end = end
        copy.scrollStart = scrollStart
        copy.scrollEnd = scrollEnd
        copy.name = name
        copy.isRepeat = isRepeat
        copy.isFadein = isFadein
        copy.isFadeout = isFadeout
        copy.volume = volume
        return copy
    }
    
    @objc func path() -> String {
        return Utilities.generateFilePath(filename: filename, projectId: projectId)
    }
    
    @objc func deleteFile() {
        if path() != "" {
            try? FileManager.default.removeItem(atPath: path())
        }
    }
}
