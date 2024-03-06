//
//  ProjectManager.swift
//  SlideShow
//
//  Created by Hua Wan on 9/22/21.
//

import UIKit
import SVProgressHUD
import SwiftColor
import AVKit

class ProjectManager: NSObject {
    
    static let shared = ProjectManager()
    
    static var current: Project = Project()
    
    var isEditing: Bool = false
    var project: Project!
    var completion: ((URL?) -> Void)? = nil
    
    func export(project: Project, completion: ((URL?) -> Void)?) {
        SVProgressHUD.show()
        self.project = project
        self.completion = completion
        self.perform(#selector(exportVideo), with: nil, afterDelay: 0.2)
    }
    
    @objc func exportVideo() {
        for music in project.musics {
            let timeLine = TVTimeLine()
            timeLine.timeLineType = TIMELINE_TYPE(rawValue: 1)
            timeLine.timeLineId = 0
            if music.itunespath != "" {
                timeLine.musicURL = URL(string: music.itunespath)
            } else {
                timeLine.musicURL = URL(fileURLWithPath: music.path())
            }
            timeLine.musicVolume = CGFloat(music.volume)
            timeLine.startTime = CGFloat(music.start)
            timeLine.endTime = CGFloat(music.end)
            timeLine.isFadeIn = music.isFadein
            timeLine.isFadeOut = music.isFadeout
            timeLine.musicStartTime = CGFloat(music.start + music.scrollStart)
            timeLine.musicEndTime = CGFloat(music.end + music.scrollStart)
            VideoService.shared().arrayTimeLines = [timeLine]
        }
        var videoLines = [VFVideoLine]()
        var videoLineId = 0
        var startTime: CGFloat = 0.0
        for media in project.medias {
            let videoLine = VFVideoLine()
            videoLine.uuidString = media.id
            videoLine.videoLineId = videoLineId
            let mediaType = MediaType(rawValue: media.type)!
            if mediaType == .video {
                videoLine.videoAsset = AVURLAsset(url: URL(fileURLWithPath: media.path()), options: nil)
                videoLine.blurAsset = AVURLAsset(url: URL(fileURLWithPath: media.blurpath()), options: nil)
                videoLine.startTime = startTime
                videoLine.endTime = startTime + CGFloat(videoLine.videoAsset.duration.seconds)
            } else {
                videoLine.imageAsset = media.foregroundImage()
                //videoLine.imageAsset = media.renderImage()//UIImage(contentsOfFile: media.path())
                videoLine.startTime = startTime
                videoLine.endTime = startTime + CGFloat(project.imageDuration)
            }
            videoLine.degree = CGFloat(media.degree)
            videoLine.backgroundUIImage = media.backgroundImage()
            videoLine.backgroundImage = CIImage(image: videoLine.backgroundUIImage)
            videoLine.transform = NSCoder.cgAffineTransform(for: media.transform)
            videoLine.isHorizontalFlip = media.isHorizontalFlip
            videoLine.isVerticalFlip = media.isVerticalFlip
            videoLine.isAspectFill = project.contentType == ContentType.scaleFill.rawValue
            videoLine.scale = CGFloat(media.scale)
            videoLine.offset = CGPoint(x: CGFloat(media.centerX), y: CGFloat(media.centerY))
            videoLine.imageDuration = CGFloat(project.imageDuration)
            videoLine.videoVolume = 1.0
            videoLines.append(videoLine)
            videoLineId += 1
            startTime = videoLine.endTime
        }
        VideoService.shared().project = project
        VideoService.shared().arrayVideoLines = videoLines
        VideoService.shared().handlerBlock = { outputURL in
            SVProgressHUD.dismiss()
            self.completion?(outputURL)
        }
        if project.colorIndex < 0 {
            VideoService.shared().saveVideo(project.renderSize, save: false, colorVideoURL: nil)
        } else {
            VideoService.colorVideo(UIColor(hexInt: APP_ARRAY_COLORS[project.colorIndex])) { success, colorURL in
                VideoService.shared().saveVideo(self.project.renderSize, save: false, colorVideoURL: colorURL)
            }
        }
    }
    
    func share(project: Project, from viewController: UIViewController, sourceView: UIView) {
        export(project: project) { outputURL in
            SVProgressHUD.dismiss()
            if let outputURL = outputURL {
                self.showShareView(url: outputURL, from: viewController, sourceView: sourceView)
                //self.play(url: outputURL!, from: viewController)
            } else {
                viewController.showAlertView("Error", "There was a error. Please try again.")
                return
            }
        }
    }
    
    func showShareView(url: URL, from viewController: UIViewController, sourceView: UIView) {
        let text = "Created with SlideShow"
        let activityItems = [text, url] as [Any]
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        controller.excludedActivityTypes = []
        controller.completionWithItemsHandler = { itemType, success, items, error in
            if let type = itemType?.rawValue, type == "com.apple.UIKit.activity.SaveToCameraRoll" && success {
                viewController.showAlertView("Video Saved", "Saved To Photo Album") {
                    var count = UserDefaults.standard.integer(forKey: "VideoSavedCount")
                    count += 1
                    if count >= 2 {
                        count = 0
                        if UserDefaults.standard.bool(forKey: kAppiraterRatedCurrentVersion) == false {
                            Appirater.setAppId("1046183199")
                            Appirater.rateApp()
                        }
                    }
                    
                    UserDefaults.standard.set(count, forKey: "VideoSavedCount")
                }
            }
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            controller.popoverPresentationController?.sourceView = viewController.view
            controller.popoverPresentationController?.sourceRect = sourceView.frame
            controller.popoverPresentationController?.permittedArrowDirections = .any
        }
        viewController.present(controller, animated: true, completion: nil)
    }
    
    func play(url: URL, from viewController: UIViewController) {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        viewController.present(controller, animated: true) {
            player.play()
        }
    }
}
