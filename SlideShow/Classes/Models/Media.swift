//
//  Media.swift
//  SlideShow
//
//  Created by Hua Wan on 9/22/21.
//

import UIKit
import RealmSwift
import SDWebImage

enum MediaType: Int {
    case image = 0
    case video = 1
}

enum EffectType: Int {
    case none = 0
    case explode
    case fade
    case zoombl
    case zoombr
    case zoombt
    case zoomcc
    case zoomlr
    case zoomrl
    case zoomtb
    case zoomtl
    case zoomtr
    case revealbt
    case reveallr
    case revealrl
    case revealtb
    case slidebl
    case slidebr
    case slidebt
    case slidelr
    case sliderl
    case slidetb
    case slidetl
    case slidetr
}

enum EffectOrientation: Int {
    case rightToLeft = 0
    case leftToRight
    case topToBottom
    case bottomToTop
    case bottomLeft
    case bottomRight
    case topLeft
    case topRight
}

@objc class Media: Object {
    @objc dynamic var id: String = UUID().uuidString
    @objc dynamic var localIdentifier: String = ""
    @objc dynamic var type: Int = MediaType.image.rawValue
    @objc dynamic var projectId: String = ""
    @objc dynamic var filename: String = ""
    @objc dynamic var blurname: String = ""
    @objc dynamic var creationDate: Date = Date()
    @objc dynamic var effectType: Int = EffectType.none.rawValue
    @objc dynamic var order: Int = 0
    @objc dynamic var isVerticalFlip: Bool = false
    @objc dynamic var isHorizontalFlip: Bool = false
    @objc dynamic var degree: Float = 0
    @objc dynamic var contentType: Int = ContentType.scaleFill.rawValue
    @objc dynamic var scale: Float = 1
    @objc dynamic var centerX: Float = 0
    @objc dynamic var centerY: Float = 0
    @objc dynamic var transform: String = NSCoder.string(for: .identity)
    @objc dynamic var contentTransform: String = ""
    var texts = List<Text>()
    var images = List<Image>()
    @objc dynamic var asset: Data? = nil
    
    override class func primaryKey() -> String? {
        return "id"
    }
    
    override func copy() -> Any {
        let copy = Media()
        copy.localIdentifier = localIdentifier
        copy.type = type
        copy.projectId = projectId
        copy.filename = Utilities.generateRandomFileName(fileExtension: URL(fileURLWithPath: filename).pathExtension)
        copy.blurname = Utilities.generateRandomFileName(fileExtension: URL(fileURLWithPath: filename).pathExtension)
        copy.effectType = effectType
        let texts = List<Text>()
        texts.append(objectsIn: self.texts)
        copy.texts = texts
        let images = List<Image>()
        images.append(objectsIn: self.images)
        copy.images = images
        copy.asset = asset
        copy.isVerticalFlip = isVerticalFlip
        copy.isHorizontalFlip = isHorizontalFlip
        copy.degree = degree
        copy.contentType = contentType
        copy.scale = scale
        copy.centerX = centerX
        copy.centerY = centerY
        return copy
    }
    
    @objc func path() -> String {
        let folder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/\(projectId)")
        try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
        return folder.appending("/\(filename)")
    }
    
    @objc func blurpath() -> String {
        let folder = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!.appending("/\(projectId)")
        try? FileManager.default.createDirectory(atPath: folder, withIntermediateDirectories: true, attributes: nil)
        return folder.appending("/\(blurname)")
    }
    
    @objc func deleteFile() {
        try? FileManager.default.removeItem(atPath: path())
        try? FileManager.default.removeItem(atPath: blurpath())
    }
    
    @objc func duration() -> CGFloat {
        if type == MediaType.image.rawValue {
            let project = sharedRealm.objects(Project.self).filter(NSPredicate(format: "id == %@", projectId)).first!
            return CGFloat(project.imageDuration)
        } else {
            let url = URL(fileURLWithPath: path())
            let asset = AVURLAsset(url: url)
            return CGFloat(asset.duration.seconds)
        }
    }
    
    @objc func thumbImage() -> UIImage {
        let type = MediaType(rawValue: self.type)!
        if type == .image {
            return UIImage(contentsOfFile: path())!
        } else {
            return Utilities.generateThumbImage(videoURL: URL(fileURLWithPath: path()))!
        }
    }
    
    @objc func image() -> UIImage {
        let type = MediaType(rawValue: self.type)!
        if type == .image {
            return UIImage(contentsOfFile: path())!
        } else {
            return UIImage.colorImage(.clear, size: CGSize(width: 320, height: 320))
        }
    }
    
    @objc func blurImage() -> UIImage {
        let type = MediaType(rawValue: self.type)!
        if type == .image {
            return UIImage(contentsOfFile: blurpath())!
        } else {
            return UIImage.colorImage(.clear, size: CGSize(width: 320, height: 320))
        }
    }
    
    @objc func rederVideoUrl() -> URL {
        return URL(fileURLWithPath: path())
    }
    
    @objc func renderImage() -> UIImage {
//        let project = sharedRealm.objects(Project.self).filter(NSPredicate(format: "id == %@", projectId)).first!
//
//        let videoFrame = NSCoder.cgRect(for: project.frame)
//        let videoView = UIView(frame: videoFrame)
//        let thumbImageView = UIImageView(frame: videoView.bounds)
//        thumbImageView.contentMode = .scaleAspectFit
//        let blurImageView = UIImageView(frame: videoView.bounds)
//        blurImageView.contentMode = .scaleAspectFill
//        videoView.addSubview(blurImageView)
//        videoView.addSubview(thumbImageView)
//        thumbImageView.transform = .identity
//        blurImageView.transform = .identity
//        let mediaType = MediaType(rawValue: type)!
//        if mediaType == .image {
//            thumbImageView.image = UIImage(contentsOfFile: path())
//        } else {
//            thumbImageView.image = Utilities.generateThumbImage(videoURL: URL(fileURLWithPath: path()))
//        }
        return UIImage(contentsOfFile: path())!
//        blurImageView.image = thumbImageView.image!.blurImage()
//        thumbImageView.transform = .identity
//        blurImageView.transform = .identity
//        thumbImageView.frame = frame(for: thumbImageView.image!.size.width / thumbImageView.image!.size.height, parentView: videoView)
//        blurImageView.frame = CGRect(x: 0, y: 0, width: videoView.frame.width, height: videoView.frame.height)
//        if degree == 90 || degree == 270 {
//            blurImageView.frame = CGRect(x: 0, y: 0, width: videoView.frame.height, height: videoView.frame.width)
//        }
//        let angle = degree * .pi / 180.0
//        let rotatedTransform = CGAffineTransform.identity.rotated(by: CGFloat(angle))
//        blurImageView.transform = blurImageView.transform.concatenating(rotatedTransform)
//
//        if isHorizontalFlip {
//            if degree == 0 || degree == 180 {
//                let flipTransform = CGAffineTransform.identity.scaledBy(x: -1.0, y: 1.0)
//                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
//            } else if degree == 90 || degree == 270 {
//                let flipTransform = CGAffineTransform.identity.scaledBy(x: 1.0, y: -1.0)
//                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
//            }
//        }
//        if isVerticalFlip {
//            if degree == 0 || degree == 180 {
//                let flipTransform = CGAffineTransform.identity.scaledBy(x: 1.0, y: -1.0)
//                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
//            } else if degree == 90 || degree == 270 {
//                let flipTransform = CGAffineTransform.identity.scaledBy(x: -1.0, y: 1.0)
//                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
//            }
//        }
//        blurImageView.center = CGPoint(x: videoView.frame.width / 2.0, y: videoView.frame.height / 2.0)
//
//        if project.colorIndex >= 0 {
//            blurImageView.isHidden = true
//            videoView.backgroundColor = UIColor(hexInt: APP_ARRAY_COLORS[project.colorIndex])
//        } else {
//            blurImageView.isHidden = false
//        }
//
//        let contentType = ContentType(rawValue: project.contentType)!
//        let imageSize = thumbImageView.image!.size
//        if contentType == .scaleFill {
//            var imageScale = CGFloat(fminf(Float(imageSize.width / videoView.frame.width), Float(imageSize.height / videoView.frame.height)))
//            let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
//            imageScale = fmax(scaledImageSize.width / videoView.frame.width, scaledImageSize.height / videoView.frame.height)
//            let contentTransform = CGAffineTransform.identity.scaledBy(x: imageScale, y: imageScale)
//            thumbImageView.transform = NSCoder.cgAffineTransform(for: self.transform).concatenating(contentTransform)
//        } else {
//            var imageScale = CGFloat(fmaxf(Float(imageSize.width / videoView.frame.width), Float(imageSize.height / videoView.frame.height)))
//            let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
//            imageScale = fmax(scaledImageSize.width / videoView.frame.width, scaledImageSize.height / videoView.frame.height)
//            let contentTransform = CGAffineTransform.identity.scaledBy(x: imageScale, y: imageScale)
//            thumbImageView.transform = NSCoder.cgAffineTransform(for: self.transform).concatenating(contentTransform)
//        }
//
//        videoView.backgroundColor = .clear
//        for text in texts {
//            let textView = addTextView(text.text, videoView)
//            textView.bounds = NSCoder.cgRect(for: text.bounds)
//            textView.transform = NSCoder.cgAffineTransform(for: text.transform)
//            textView.center = NSCoder.cgPoint(for: text.center)
//            textView.fontIndex = text.fontIndex
//            textView.setTextFontWithName(TextsView.arrayFonts[text.fontIndex])
//            textView.fontSize = CGFloat(text.fontSize)
//            textView.colorIndex = text.colorIndex
//            textView.textColor = UIColor(hexInt: APP_ARRAY_COLORS[text.colorIndex])
//            textView.textOpacity = CGFloat(text.opacity)
//            textView.isActive = false
//            self.textView(textView, shouldChangeText: text.text, videoView: videoView)
//        }
//
//        let resourceURL = Bundle.main.bundleURL.appendingPathComponent("Stickers")
//        for image in images {
//            let path = resourceURL.appendingPathComponent(image.category).appendingPathComponent(image.filename).path
//            let uiimage = UIImage(contentsOfFile: path)!
//            let imageView = addImageView(uiimage, videoView)
//            imageView.uuid = image.id
//            imageView.bounds = NSCoder.cgRect(for: image.bounds)
//            imageView.transform = NSCoder.cgAffineTransform(for: image.transform)
//            imageView.center = NSCoder.cgPoint(for: image.center)
//            imageView.isActive = false
//        }
//
//        let assetImage = renderView(videoView)
//        return assetImage
    }
    
    @objc func renderVideo(_frameImage: UIImage) -> UIImage {
//        let project = sharedRealm.objects(Project.self).filter(NSPredicate(format: "id == %@", projectId)).first!
//        let videoFrame = NSCoder.cgRect(for: project.frame)
//        let videoView = UIView(frame: videoFrame)
//        let thumbImageView = UIImageView(frame: videoView.bounds)
//        thumbImageView.contentMode = .scaleAspectFit
//        let blurImageView = UIImageView(frame: videoView.bounds)
//        blurImageView.contentMode = .scaleAspectFill
//        videoView.addSubview(blurImageView)
//        videoView.addSubview(thumbImageView)
//        thumbImageView.transform = .identity
//        blurImageView.transform = .identity
//        let mediaType = MediaType(rawValue: type)!
//        if mediaType == .image {
//            thumbImageView.image = UIImage(contentsOfFile: path())
//        } else {
//            thumbImageView.image = _frameImage // Utilities.generateThumbImage(videoURL: URL(fileURLWithPath: path()))
//        }
        return _frameImage;
//        blurImageView.image = thumbImageView.image!.blurImage()
//        thumbImageView.transform = .identity
//        blurImageView.transform = .identity
//        thumbImageView.frame = frame(for: thumbImageView.image!.size.width / thumbImageView.image!.size.height, parentView: videoView)
//        blurImageView.frame = CGRect(x: 0, y: 0, width: videoView.frame.width, height: videoView.frame.height)
//        if degree == 90 || degree == 270 {
//            blurImageView.frame = CGRect(x: 0, y: 0, width: videoView.frame.height, height: videoView.frame.width)
//        }
//        let angle = degree * .pi / 180.0
//        let rotatedTransform = CGAffineTransform.identity.rotated(by: CGFloat(angle))
//        blurImageView.transform = blurImageView.transform.concatenating(rotatedTransform)
//        
//        if isHorizontalFlip {
//            if degree == 0 || degree == 180 {
//                let flipTransform = CGAffineTransform.identity.scaledBy(x: -1.0, y: 1.0)
//                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
//            } else if degree == 90 || degree == 270 {
//                let flipTransform = CGAffineTransform.identity.scaledBy(x: 1.0, y: -1.0)
//                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
//            }
//        }
//        if isVerticalFlip {
//            if degree == 0 || degree == 180 {
//                let flipTransform = CGAffineTransform.identity.scaledBy(x: 1.0, y: -1.0)
//                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
//            } else if degree == 90 || degree == 270 {
//                let flipTransform = CGAffineTransform.identity.scaledBy(x: -1.0, y: 1.0)
//                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
//            }
//        }
//        blurImageView.center = CGPoint(x: videoView.frame.width / 2.0, y: videoView.frame.height / 2.0)
//        
//        if project.colorIndex >= 0 {
//            blurImageView.isHidden = true
//            videoView.backgroundColor = UIColor(hexInt: APP_ARRAY_COLORS[project.colorIndex])
//        } else {
//            blurImageView.isHidden = false
//        }
//        
//        let contentType = ContentType(rawValue: project.contentType)!
//        let imageSize = thumbImageView.image!.size
//        if contentType == .scaleFill {
//            var imageScale = CGFloat(fminf(Float(imageSize.width / videoView.frame.width), Float(imageSize.height / videoView.frame.height)))
//            let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
//            imageScale = fmax(scaledImageSize.width / videoView.frame.width, scaledImageSize.height / videoView.frame.height)
//            let contentTransform = CGAffineTransform.identity.scaledBy(x: imageScale, y: imageScale)
//            thumbImageView.transform = NSCoder.cgAffineTransform(for: self.transform).concatenating(contentTransform)
//        } else {
//            var imageScale = CGFloat(fmaxf(Float(imageSize.width / videoView.frame.width), Float(imageSize.height / videoView.frame.height)))
//            let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
//            imageScale = fmax(scaledImageSize.width / videoView.frame.width, scaledImageSize.height / videoView.frame.height)
//            let contentTransform = CGAffineTransform.identity.scaledBy(x: imageScale, y: imageScale)
//            thumbImageView.transform = NSCoder.cgAffineTransform(for: self.transform).concatenating(contentTransform)
//        }
//        
//        videoView.backgroundColor = .clear
//        for text in texts {
//            let textView = addTextView(text.text, videoView)
//            textView.bounds = NSCoder.cgRect(for: text.bounds)
//            textView.transform = NSCoder.cgAffineTransform(for: text.transform)
//            textView.center = NSCoder.cgPoint(for: text.center)
//            textView.fontIndex = text.fontIndex
//            textView.setTextFontWithName(TextsView.arrayFonts[text.fontIndex])
//            textView.fontSize = CGFloat(text.fontSize)
//            textView.colorIndex = text.colorIndex
//            textView.textColor = UIColor(hexInt: APP_ARRAY_COLORS[text.colorIndex])
//            textView.textOpacity = CGFloat(text.opacity)
//            textView.isActive = false
//            self.textView(textView, shouldChangeText: text.text, videoView: videoView)
//        }
//        
//        let resourceURL = Bundle.main.bundleURL.appendingPathComponent("Stickers")
//        for image in images {
//            let path = resourceURL.appendingPathComponent(image.category).appendingPathComponent(image.filename).path
//            let uiimage = UIImage(contentsOfFile: path)!
//            let imageView = addImageView(uiimage, videoView)
//            imageView.uuid = image.id
//            imageView.bounds = NSCoder.cgRect(for: image.bounds)
//            imageView.transform = NSCoder.cgAffineTransform(for: image.transform)
//            imageView.center = NSCoder.cgPoint(for: image.center)
//            imageView.isActive = false
//        }
//        
//        let assetImage = renderView(videoView)
//        return assetImage
    }
    
    @objc func foregroundImage() -> UIImage {
        let project = sharedRealm.objects(Project.self).filter(NSPredicate(format: "id == %@", projectId)).first!
        let videoFrame = NSCoder.cgRect(for: project.frame)
        let videoView = UIView(frame: videoFrame)
        let thumbImageView = UIImageView(frame: videoView.bounds)
        thumbImageView.contentMode = .scaleAspectFit
        videoView.addSubview(thumbImageView)
        thumbImageView.transform = .identity
        let mediaType = MediaType(rawValue: type)!
        if mediaType == .image {
            thumbImageView.image = UIImage(contentsOfFile: path())
        } else {
            thumbImageView.image = Utilities.generateThumbImage(videoURL: URL(fileURLWithPath: path()))
        }
        thumbImageView.transform = .identity
        thumbImageView.frame = frame(for: thumbImageView.image!.size.width / thumbImageView.image!.size.height, parentView: videoView)
        if project.colorIndex >= 0 {
            videoView.backgroundColor = UIColor(hexInt: APP_ARRAY_COLORS[project.colorIndex])
        } else {
            videoView.backgroundColor = .clear
        }
        
        let contentType = ContentType(rawValue: project.contentType)!
        let imageSize = thumbImageView.image!.size
        if contentType == .scaleFill {
            var imageScale = CGFloat(fminf(Float(imageSize.width / videoView.frame.width), Float(imageSize.height / videoView.frame.height)))
            let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
            imageScale = fmax(scaledImageSize.width / videoView.frame.width, scaledImageSize.height / videoView.frame.height)
            let contentTransform = CGAffineTransform.identity.scaledBy(x: imageScale, y: imageScale)
            thumbImageView.transform = NSCoder.cgAffineTransform(for: self.transform).concatenating(contentTransform)
        } else {
            var imageScale = CGFloat(fmaxf(Float(imageSize.width / videoView.frame.width), Float(imageSize.height / videoView.frame.height)))
            let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
            imageScale = fmax(scaledImageSize.width / videoView.frame.width, scaledImageSize.height / videoView.frame.height)
            let contentTransform = CGAffineTransform.identity.scaledBy(x: imageScale, y: imageScale)
            thumbImageView.transform = NSCoder.cgAffineTransform(for: self.transform).concatenating(contentTransform)
        }
        
        for text in texts {
            let textView = addTextView(text.text, videoView)
            textView.bounds = NSCoder.cgRect(for: text.bounds)
            textView.transform = NSCoder.cgAffineTransform(for: text.transform)
            textView.center = NSCoder.cgPoint(for: text.center)
            textView.fontIndex = text.fontIndex
            textView.setTextFontWithName(TextsView.arrayFonts[text.fontIndex])
            textView.fontSize = CGFloat(text.fontSize)
            textView.colorIndex = text.colorIndex
            textView.textColor = UIColor(hexInt: APP_ARRAY_COLORS[text.colorIndex])
            textView.textOpacity = CGFloat(text.opacity)
            textView.isActive = false
            self.textView(textView, shouldChangeText: text.text, videoView: videoView)
        }
        
        let resourceURL = Bundle.main.bundleURL.appendingPathComponent("Stickers")
        for image in images {
            let path = resourceURL.appendingPathComponent(image.category).appendingPathComponent(image.filename).path
            let uiimage = UIImage(contentsOfFile: path)!
            let imageView = addImageView(uiimage, videoView)
            imageView.uuid = image.id
            imageView.bounds = NSCoder.cgRect(for: image.bounds)
            imageView.transform = NSCoder.cgAffineTransform(for: image.transform)
            imageView.center = NSCoder.cgPoint(for: image.center)
            imageView.isActive = false
        }
        
        let assetImage = renderView(videoView)
        return assetImage
    }
    
    @objc func backgroundImage() -> UIImage {
        let project = sharedRealm.objects(Project.self).filter(NSPredicate(format: "id == %@", projectId)).first!
        var backgroundImage = project.backgroundImage()
        if self.type == MediaType.video.rawValue {
            backgroundImage = UIImage.colorImage(.clear, size: backgroundImage.size)
        }
        
        if project.colorIndex < 0 {
            var blurImage = self.blurImage()
            blurImage = blurImage.sd_flippedImage(withHorizontal: isHorizontalFlip, vertical: isVerticalFlip)!
            if degree != 0 {
                blurImage = blurImage.rotateImage(byRadian: CGFloat(degree) * .pi / 180.0)
            }
            backgroundImage = backgroundImage.overlayImage(blurImage, contentMode: .scaleAspectFill)
        }
        
        return backgroundImage
    }

    func textView(_ textView: TVTextView!, shouldChangeText newText: String, videoView: UIView) {
        let transform = textView.transform
        textView.transform = .identity
        
        var shouldChangeText = true
        
        let edgeInsets = textView.textEdgesInsets()
        let containedFrame = videoView.frame
        
        let width  = containedFrame.size.width - edgeInsets.left - edgeInsets.right
        let height = UIScreen.main.bounds.size.height * 2.0
        
        var newTextSize: CGSize = .zero
        if newText == "" {
            newTextSize = CGSize(width: TEXTVIEW_FRAME.size.width - 2 * TEXT_OFFSET - edgeInsets.left - edgeInsets.right, height: TEXTVIEW_FRAME.size.height - 2.0 * TEXT_OFFSET - edgeInsets.top - edgeInsets.bottom)
        } else {
            newTextSize = (newText as NSString).boundingRect(with: CGSize(width: width, height: height), options: .usesLineFragmentOrigin, attributes: [.font: textView.textFont()!], context: nil).size
        }
        
        if textView.preservedSize != .zero {
            newTextSize = textView.preservedSize;
        }
        
        newTextSize.width += edgeInsets.left + edgeInsets.right;
        newTextSize.height += edgeInsets.top + edgeInsets.bottom;
        
        shouldChangeText = newTextSize.height * textView.textScale.y  < containedFrame.size.height;
        
        if shouldChangeText {
            if newText == "" {
                textView.textScale = CGPoint(x: 1.0, y: 1.0)
            }
            
            textView.textSize = newTextSize
            
            var frame = textView.frame
            frame.origin.x = fmin(frame.origin.x, containedFrame.size.width - (frame.size.width - TEXT_OFFSET * 2))
            frame.origin.y = fmin(frame.origin.y, containedFrame.size.height - (frame.size.height - TEXT_OFFSET * 2))
            
            textView.frame = frame
        }
        
        textView.transform = transform
    }
    
    func addTextView(_ text: String, _ videoView: UIView) -> TVTextView {
        let textView = TVTextView()
        let videoFrame = videoView.frame
        textView.textView.text = text
        textView.frame = TEXTVIEW_FRAME;
        textView.center = CGPoint(x: videoFrame.midX, y: videoFrame.midY)
        if textView.frame.origin.y + textView.frame.size.height + textView.frame.origin.y > UIScreen.main.bounds.size.height - 216 {
            var center = textView.center
            center.y = UIScreen.main.bounds.size.height - 216 - videoFrame.origin.y - textView.frame.size.height
            textView.center = center
        }

        videoView.addSubview(textView)
        self.textView(textView, shouldChangeText: text, videoView: videoView)
        
        return textView
    }
    
    func addImageView(_ image: UIImage, _ videoView: UIView) -> TVImageView {
        let imageView = TVImageView()
        let videoFrame = videoView.frame
        var frameSize = TVImageView.frameSize(with: image, maxSize: videoFrame.size)
        frameSize.width /= 2.0
        frameSize.height /= 2.0
        imageView.frame = CGRect(x: 0.5 * (videoFrame.size.width - frameSize.width), y: 0.5 * (videoFrame.size.height - frameSize.height), width: frameSize.width, height: frameSize.height)
        imageView.setImage(image)
        imageView.setOriginImage(image)
        imageView.isActive = false
        videoView.addSubview(imageView)
        
        return imageView
    }
    
    func renderView(_ view: UIView) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: view.frame.size)
        let image = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        return image
    }
    
    fileprivate func frame(for ratio: CGFloat, parentView: UIView) -> CGRect {
        let imageSize = CGSize(width: 1.0, height: 1.0 / ratio)
        let viewWidth = parentView.frame.width
        let viewHeight = parentView.frame.height
        
        let imageScale = CGFloat(fmaxf(Float(imageSize.width / viewWidth), Float(imageSize.height / viewHeight)))
        let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
        let frame = CGRect(x: 0.5 * (viewWidth - scaledImageSize.width),
                           y: 0.5 * (viewHeight - scaledImageSize.height),
                           width: scaledImageSize.width,
                           height: scaledImageSize.height);
        
        return frame
    }
}
