//
//  Project.swift
//  SlideShow
//
//  Created by Hua Wan on 9/15/21.
//

import UIKit
import RealmSwift
import AVFoundation
import CoreServices

enum RatioType: Int {
    case original = 101
    case portrait
    case landscape
    case square
    
    var ratio: CGFloat {
        switch self {
        case .original:
            return CGFloat(RATIO_ORIGINAL)
            
        case .portrait:
            return CGFloat(RATIO_PORTRAIT)
            
        case .landscape:
            return CGFloat(RATIO_LANDSCAPE)
            
        case .square:
            return CGFloat(RATIO_SQUARE)
        }
    }
    
    var string: String {
        switch self {
        case .original:
            return "4:3"
        
        case .portrait:
            return "9:16"
            
        case .landscape:
            return "16:9"
            
        case .square:
            return "1:1"
        }
    }
    
    var caption: String {
        switch self {
        case .original:
            return "Standard"
        
        case .portrait:
            return "Portrait"
            
        case .landscape:
            return "Landscape"
            
        case .square:
            return "Square"
        }
    }
    
    static var count: Int {
        return RatioType.square.rawValue - RatioType.original.rawValue + 1
    }
}

enum ContentType: Int {
    case scaleFit
    case scaleFill
}

enum OrderType: Int {
    case custom
    case shuffle
    case date
    
    var caption: String {
        switch self {
        case .custom:
            return "Custom"
        case .shuffle:
            return "Shuffle"
        case .date:
            return "By Date"
        }
    }
    
    var image: UIImage? {
        switch self {
        case .custom:
            return UIImage(named: "IconCustomBlack")
        case .shuffle:
            return UIImage(named: "IconShuffleBlack")
        case .date:
            return UIImage(named: "IconDateBlack")
        }
    }
    
    static var count: Int {
        return 3
    }
}

@objc class Project: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var name: String = ""
    @objc dynamic var ratio: Int = RatioType.original.rawValue
    @objc dynamic var imageDuration: Float = Float(DEFAULT_IMAGE_DURATION)
    @objc dynamic var createdDate: Date = Date()
    @objc dynamic var modifiedDate: Date = Date()
    var medias = List<Media>()
    var musics = List<Music>()
    @objc dynamic var contentType: Int = ContentType.scaleFill.rawValue
    @objc dynamic var colorIndex: Int = -1
    @objc dynamic var frame: String = ""
    @objc dynamic var orderType: Int = OrderType.custom.rawValue
    @objc dynamic var themeIndex: Int = 0
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    var renderSize: CGSize {
        let ratio = RatioType(rawValue: self.ratio)!.ratio
        if ratio > 1 {
            return CGSize(width: MAX_VIDEO_WIDTH, height: CGFloat(Int(MAX_VIDEO_WIDTH / ratio + 0.8)))
        } else {
            return CGSize(width: CGFloat(Int(MAX_VIDEO_WIDTH * ratio + 0.8)), height: MAX_VIDEO_WIDTH)
        }
    }
    
    @objc var mediaItems: [Media] {
        var items: [Media] = []
        for media in medias {
            items.append(media)
        }
        return items
    }
    
//    var project: SSProject {
//        let project = SSProject()
//        project.projectId = id
//        let formatter = DateFormatter()
//        formatter.formatterBehavior = .behavior10_4
//        formatter.dateStyle = .long
//        let result = formatter.string(from: Date())
//        project.createdTime = result
//        project.updateTheme(Int32(themeIndex))
//        project.imageDuration = TimeInterval(imageDuration)
//
//        for media in medias {
//            if media.type == MediaType.image.rawValue {
//                project.add(media.renderImage())
//            } else if media.type == MediaType.video.rawValue {
//                let path = Utilities.generateFilePath(filename: media.filename, projectId: media.projectId)
//                let asset = AVAsset(url: URL(fileURLWithPath: path))
//                let frame = VideoService().getFrame(asset)
//                project.addVideo(frame!, url: URL(fileURLWithPath: path))
//            }
//        }
//        return project
//    }
    func project(completion1: @escaping (SSProject)->()) {
        let project = SSProject()
        project.projectId = id
        let formatter = DateFormatter()
        formatter.formatterBehavior = .behavior10_4
        formatter.dateStyle = .long
        let result = formatter.string(from: Date())
        project.createdTime = result
        project.updateTheme(Int32(themeIndex))
        project.imageDuration = TimeInterval(imageDuration)
        project.themeIndex = Int32(self.themeIndex)
        project.settings.fixedPhotoDuration = TimeInterval(imageDuration)
        
        innerProject(project, 0) { project in
            completion1(project)
        }
    }
    
    func innerProject(_ project: SSProject,_ index: Int, completion: @escaping (SSProject)->()) {
        let media = self.medias[index]
        if media.type == MediaType.image.rawValue {
            project.add(media.renderImage())
            if (index+1 == self.medias.count) {
                editViewCtrl?.playButtonPressed1(project)
            } else {
                innerProject(project, index + 1) { project in
                    
                }
            }
        } else if media.type == MediaType.video.rawValue {
            let path = Utilities.generateFilePath(filename: media.filename, projectId: media.projectId)
//            VideoService.loadVideo(URL(fileURLWithPath: path)) { [self] url in
            let url = URL.init(fileURLWithPath: path)
                let asset = AVAsset(url: url)
                let videoDuration = asset.duration
                let generator = AVAssetImageGenerator(asset: asset)
                generator.appliesPreferredTrackTransform = true
                
//                let frame = VideoService().getFrame(asset)
            let frame = UIImage.init(named: "AppIcon")
                project.addVideo(media.renderVideo(_frameImage: frame!), url: URL(fileURLWithPath: path), duration:videoDuration, generator: generator, lastImg: media.renderVideo(_frameImage: frame!)) //media.renderImage() lastImg
                if (index+1 == self.medias.count) {
                    editViewCtrl?.playButtonPressed1(project)
                } else {
                    self.innerProject(project, index + 1) { project in
                        
                    }
                }
//            }
        }
    }
    
    override func copy() -> Any {
        let copy = Project()
        copy.name = "\(name) - Copy"
        copy.ratio = ratio
        copy.imageDuration = imageDuration
        copy.createdDate = Date()
        copy.modifiedDate = Date()
        let medias = List<Media>()
        for media in self.medias {
            let media2 = media.copy() as! Media
            try? FileManager.default.copyItem(atPath: media.path(), toPath: media2.path())
            try? FileManager.default.copyItem(atPath: media.blurpath(), toPath: media2.blurpath())
            medias.append(media2)
        }
        copy.medias = medias
        
        let musics = List<Music>()
        for music in self.musics {
            let music2 = music.copy() as! Music
            musics.append(music2)
        }
        copy.musics = musics
        
        copy.contentType = contentType
        copy.colorIndex = colorIndex
        copy.frame = frame
        copy.themeIndex = themeIndex
        return copy
    }
    
    @objc func path() -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/\(id)/")
    }
    
    @objc func duration(_ addURL: URL? = nil) -> CGFloat {
        var duration: CGFloat = 0
        for media in medias {
            if media.type == MediaType.image.rawValue {
                duration += CGFloat(imageDuration)
            } else if media.type == MediaType.video.rawValue {
                let url = URL(fileURLWithPath: media.path())
                let asset = AVURLAsset(url: url, options: nil)
                duration += CGFloat(asset.duration.seconds)
            }
        }
        
        if let url = addURL {
            let asset = AVURLAsset(url: url, options: nil)
            duration += CGFloat(asset.duration.seconds)
        }
        
        return duration
    }
    
    func mediaTime(_ index: Int) -> (CGFloat, CGFloat) {
        if index == 0 {
            let media = medias[0]
            var duration: CGFloat = 0
            if media.type == MediaType.image.rawValue {
                duration += CGFloat(imageDuration)
            } else if media.type == MediaType.video.rawValue {
                let url = URL(fileURLWithPath: media.path())
                let asset = AVURLAsset(url: url, options: nil)
                duration += CGFloat(asset.duration.seconds)
            }
            return (0, duration)
        }
        
        var duration: CGFloat = 0
        for i in 0 ..< index {
            let media = medias[i]
            if media.type == MediaType.image.rawValue {
                duration += CGFloat(imageDuration)
            } else if media.type == MediaType.video.rawValue {
                let url = URL(fileURLWithPath: media.path())
                let asset = AVURLAsset(url: url, options: nil)
                duration += CGFloat(asset.duration.seconds)
            }
        }
        
        let media = medias[index]
        if media.type == MediaType.image.rawValue {
            return (duration, duration + CGFloat(imageDuration))
        } else if media.type == MediaType.video.rawValue {
            let url = URL(fileURLWithPath: media.path())
            let asset = AVURLAsset(url: url, options: nil)
            return (duration, duration + CGFloat(asset.duration.seconds))
        } else {
            return (duration, duration)
        }
    }
    
    func mediaIndex(_ time: CGFloat) -> Int {
        var duration: CGFloat = 0
        for i in 0 ..< medias.count {
            let media = medias[i]
            if media.type == MediaType.image.rawValue {
                duration += CGFloat(imageDuration)
            } else if media.type == MediaType.video.rawValue {
                let url = URL(fileURLWithPath: media.path())
                let asset = AVURLAsset(url: url, options: nil)
                duration += CGFloat(asset.duration.seconds)
            }
            
            if duration >= time {
                return i
            }
        }
        
        return 0
    }
    
    @objc func deleteFile() {
        for media in medias {
            media.deleteFile()
        }
        
        for music in musics {
            music.deleteFile()
        }
    }
    
    @objc func backgroundImage() -> UIImage {
        let ratio = RatioType(rawValue: self.ratio)!.ratio
        var size = CGSize(width: MAX_VIDEO_WIDTH, height: MAX_VIDEO_WIDTH)
        if ratio > 1.0 {
            size = CGSize(width: MAX_VIDEO_WIDTH, height: MAX_VIDEO_WIDTH / ratio)
        } else {
            size = CGSize(width: MAX_VIDEO_WIDTH * ratio, height: MAX_VIDEO_WIDTH)
        }
        
        if colorIndex >= 0 {
            return UIImage.colorImage(UIColor(hexInt: APP_ARRAY_COLORS[colorIndex]), size: size)
        } else {
            return UIImage.colorImage(.clear, size: size)
        }
    }
    
    @objc func backgroundColor() -> UIColor {
        if colorIndex >= 0 {
            return UIColor(hexInt: APP_ARRAY_COLORS[colorIndex])
        } else {
            return .clear
        }
    }
}
