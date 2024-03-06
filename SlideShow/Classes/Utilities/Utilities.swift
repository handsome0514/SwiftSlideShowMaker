//
//  Utilities.swift
//  SlideShow
//
//  Created by Hua Wan on 9/22/21.
//

import UIKit
import AVFoundation

@objc class Utilities: NSObject {
    @objc static func showAlertView(_ title: String?, _ message: String) {
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { action in
            
        }))
        Utilities.topViewController().present(controller, animated: true, completion: nil)
    }
    
    @objc static func generateThumbImage(videoURL: URL, maxSize: CGSize = .zero) -> UIImage? {
        let asset = AVURLAsset(url: videoURL, options: nil)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        if maxSize != .zero {
            imageGenerator.maximumSize = maxSize
        }
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime.zero, actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            return nil
        }
    }
    
    @objc static func generateRandomFileName(length: Int = 48, fileExtension: String) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz1234567890"
        let count = letters.count
        var filename = ""
        for _ in 0..<length {
            let rand = arc4random_uniform(UInt32(count))
            let startIndex = letters.index(letters.startIndex, offsetBy: String.IndexDistance(rand))
            let endIndex = letters.index(startIndex, offsetBy: 1)
            filename += letters[startIndex..<endIndex]
        }
        return filename + "." + fileExtension
    }
    
    @objc static func generateFilePath(filename: String) -> String {
        var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/"
        if FileManager.default.fileExists(atPath: path) == false {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        path = path + filename
        return path
    }
    
    @objc static func generateFilePath(filename: String, projectId: String) -> String {
        if projectId == "" {
            return ""
        }
        var path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! + "/\(projectId)/"
        if FileManager.default.fileExists(atPath: path) == false {
            try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
        }
        path = path + filename
        return path
    }
    
    @objc static func timeString(_ seconds: Int) -> String {
        let duration = seconds
        let hours = duration / 3600
        let mins = (duration % 3600) / 60
        let secs = (duration % 3600) % 60
        if hours > 0 {
            return String(format: "%.2d:%.2d:%.2d", hours, mins, secs)
        } else {
            return String(format: "%.2d:%.2d", mins, secs)
        }
    }
    
    static func topViewController() -> UIViewController {
        var topController: UIViewController = UIApplication.shared.keyWindow!.rootViewController!
        while topController.presentedViewController != nil {
            topController = topController.presentedViewController!
        }
        return topController
    }
    
    static func rotate(angle: CGFloat, rotationView: UIView) {
        let radians = CGFloat.pi
        rotationView.transform = CGAffineTransform(rotationAngle: radians)
    }
    
    @objc static func viewZoomAnimation(_ animationView: UIView, _ duration: TimeInterval, _ isOut: Bool) {
        if isOut {
            animationView.transform = CGAffineTransform.identity
            UIView.transition(with: animationView,
                duration: duration,
                options: [.curveEaseOut],
                animations: {
                animationView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                },
                completion: {_ in
                
                }
            )
        } else {
            animationView.transform = CGAffineTransform.identity
            animationView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            UIView.transition(with: animationView,
                              duration: duration,
                options: [.curveEaseOut],
                animations: {
                animationView.transform = CGAffineTransform(scaleX: 1.0, y: 1.0)
                },
                completion: {_ in
                
                }
            )
        }
    }
    
    @objc static func viewAnimation(_ themeIndex: Int, _ animationView: UIView) {
        switch themeIndex {
        case 0:
            UIView.transition(with: animationView,
                duration: 1.5,
                options: [.curveEaseOut],
                animations: {
                animationView.alpha = 0
                animationView.transform = CGAffineTransform(translationX: 0, y: +300)
                },
                completion: {_ in
                animationView.transform = CGAffineTransform.identity
                }
            )
            break
        case 1:
            UIView.transition(with: animationView,
                              duration: 1.5,
                              options: [.curveEaseOut, .transitionFlipFromTop],
                animations: {
                animationView.alpha = 0
                },
                completion: {_ in
                }
            )
            break
        case 2:
            UIView.transition(with: animationView,
                              duration: 1.5,
                              options: [.curveEaseOut, .transitionFlipFromLeft],
                animations: {
                animationView.alpha = 0
                },
                completion: {_ in
                }
            )
            break
        case 3:
            UIView.transition(with: animationView,
                              duration: 1.5,
                              options: [.curveEaseIn],
                animations: {
                animationView.alpha = 0
                animationView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                },
                completion: {_ in
                animationView.transform = CGAffineTransform.identity
                }
            )
            break
        case 4:
            UIView.transition(with: animationView,
                duration: 1.5,
                options: [.curveEaseOut],
                animations: {
                animationView.alpha = 0
                animationView.transform = CGAffineTransform(scaleX: 1, y: 3)
                },
                completion: {_ in
                animationView.transform = CGAffineTransform.identity
                }
            )
            break
        case 6:
            UIView.transition(with: animationView,
                duration: 1.5,
                options: [.curveEaseOut],
                animations: {
                animationView.alpha = 0
                animationView.transform = CGAffineTransform(scaleX: 3, y: 1)
                },
                completion: {_ in
                animationView.transform = CGAffineTransform.identity
                }
            )
            break
        case 7:
            UIView.transition(with: animationView,
                              duration: 1.5,
                              options: [.curveLinear],
                animations: {
                animationView.alpha = 0
                animationView.transform = CGAffineTransform(scaleX: 3, y: 3)
                },
                completion: {_ in
                animationView.transform = CGAffineTransform.identity
                }
            )
            break
        default:
            UIView.transition(with: animationView,
                duration: 1.5,
                options: [.curveEaseOut],
                animations: {
                animationView.alpha = 0
                animationView.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
                },
                completion: {_ in
                animationView.transform = CGAffineTransform.identity
                }
            )
            break
        }
    }
    
    static func windowView(_ layoutView: UIView,_ cropBound: CGRect) {
        for item in layoutView.subviews {
            if (!(item is UIButton)) {
                item.removeFromSuperview()
            }
        }
        
        let rect1 = CGRect.init(x: 0, y: 0, width: layoutView.frame.width, height: cropBound.origin.y)
        let rect2 = CGRect.init(x: 0, y: 0, width: cropBound.origin.x, height: layoutView.frame.height)
        let rect3 = CGRect.init(x: 0, y: cropBound.origin.y + cropBound.height, width: layoutView.frame.width, height: layoutView.frame.height - cropBound.origin.y - cropBound.height)
        let rect4 = CGRect.init(x: cropBound.origin.x + cropBound.width, y: 0, width: layoutView.frame.width - cropBound.origin.x - cropBound.width, height: layoutView.frame.height)
        
        let view1 = UIView.init(frame: rect1)
        view1.backgroundColor = .black
        let view2 = UIView.init(frame: rect2)
        view2.backgroundColor = .black
        let view3 = UIView.init(frame: rect3)
        view3.backgroundColor = .black
        let view4 = UIView.init(frame: rect4)
        view4.backgroundColor = .black
        
        layoutView.addSubview(view1)
        layoutView.addSubview(view2)
        layoutView.addSubview(view3)
        layoutView.addSubview(view4)
    }
    
    static func getFilter(_ index: Int, themeNumber: Int) -> GPUImageFilter {
        let themeFilters = [
            [0, 0, 0, 0, 0], //
            [6, 0, 7, 3, 11], // Love Theme:
            [5, 11, 0, 8, 3], // Romance Theme:
            [0, 0, 0, 0, 0], // Happy Birthday Theme:
            [0, 0, 0, 0, 0], // Happy Birthday Rock Theme:
            [11, 8, 7, 6, 8], // Memories Theme:
            [11, 8, 7, 6, 8], // Missing You Theme:
            [7, 6, 11, 7, 7],// Vintage Cinema Theme:
            [0, 1, 0, 3, 4], // Good Life Theme:
            [7, 8, 7, 0, 8], // Free Fall Theme:
            [11, 6, 11, 7, 8], // Winter Wonderland Theme:
            [8, 11, 0, 0, 11], // 80's Theme:
            [11, 8, 7, 6, 8], // Memories Theme:
            [0, 3, 2, 0, 3], // Happy Theme:
            [0, 3, 2, 0, 3], // Pop Theme:
        ]
        let fileterId = themeFilters[themeNumber][index % 5]
        
        return selectFilter(fileterId)
    }
    
    static func selectFilter(_ index: Int) -> GPUImageFilter {
        print("\(index)")
        if index == 0 {
            return GPUImageFilter()
        }
        else if index == 11 {
            return GPUImageGrayscaleFilter()
        } else if index == 12 {
            let filter = GPUImageSharpenFilter()
            filter.sharpness = 4
            return filter
        } else if index == 13 {
            let filter = GPUImageSharpenFilter()
            filter.sharpness = -4
            return filter
        }
        
        let filter = GPUImageSepiaFilter()
        filter.intensity = 4.0 / 9 * CGFloat(ProjectManager.current.themeIndex - 1) - 2.0
        
        return filter
    }
    
    static func videoDuration(_ media: Media) -> CGFloat {
        let path = Utilities.generateFilePath(filename: media.filename, projectId: media.projectId)
        let url = URL.init(fileURLWithPath: path)
        let asset = AVAsset(url: url)
        let videoDuration = asset.duration
        return CGFloat(CMTimeGetSeconds(videoDuration))
    }
    
    static func pauseLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil)
        layer.speed = 0.0
        layer.timeOffset = pausedTime
    }

    static func resumeLayer(layer: CALayer) {
        let pausedTime: CFTimeInterval = layer.timeOffset
        layer.speed = 1.0
        layer.timeOffset = 0.0
        layer.beginTime = 0.0
        let timeSincePause: CFTimeInterval = layer.convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        layer.beginTime = timeSincePause
    }
}
