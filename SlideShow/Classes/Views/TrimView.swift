//
//  TrimView.swift
//  SlideShow
//
//  Created by Hua Wan on 5/11/22.
//

import UIKit
import AVFoundation
import SVProgressHUD

protocol TrimViewDelegate {
    func didTrimDone(_ view: TrimView, _ url: URL?, _ blururl: URL?)
    func didChangeTrimView(_ view: TrimView, startTime: CMTime)
    func didChangeTrimView(_ view: TrimView, endTime: CMTime)
}

class TrimView: UIView {
    
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var thumbsScrollView: UIScrollView!
    @IBOutlet weak var leftPanImageView: UIImageView!
    @IBOutlet weak var rightPanImageView: UIImageView!
    @IBOutlet weak var indicatorImageView: UIImageView!
    
    @IBOutlet weak var leadingLeftConstraint: NSLayoutConstraint!
    @IBOutlet weak var trailingRightConstraint: NSLayoutConstraint!
    
    fileprivate var videoAsset: AVURLAsset!
    fileprivate var onesec: CGFloat = 1.0
    fileprivate var startTime: CMTime = .zero
    fileprivate var endTime: CMTime = .zero
    
    var media: Media! {
        didSet {
            configThumbnailView()
            
            leadingLeftConstraint.constant = -4.0
            trailingRightConstraint.constant = 4.0
            layoutIfNeeded()
            indicatorImageView.frame = CGRect(origin: CGPoint(x: leftPanImageView.frame.origin.x + 4.0, y: leftPanImageView.frame.origin.y), size: indicatorImageView.frame.size)
        }
    }
    var delegate: TrimViewDelegate? = nil

    class func loadFromNib() -> TrimView {
        let bundles = Bundle.main.loadNibNamed("TrimView", owner: self, options: nil)!.filter { bundle in
            return bundle is TrimView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! TrimView
        } else {
            return bundles.last as! TrimView
        }
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func configThumbnailView() {
        if media.type == MediaType.video.rawValue {
            let path = Utilities.generateFilePath(filename: media.filename, projectId: media.projectId)
            videoAsset = AVURLAsset(url: URL(fileURLWithPath: path))
            durationLabel.text = Utilities.timeString(Int(CMTimeGetSeconds(videoAsset.duration)))
            let frameCount: CGFloat = 12
            let FRAME_WIDTH = thumbsScrollView.frame.size.width / frameCount
            let FRAME_HEIGHT = thumbsScrollView.frame.size.height
            onesec = thumbsScrollView.frame.size.width / CMTimeGetSeconds(videoAsset.duration);
            startTime = .zero
            endTime = videoAsset.duration
            let generator = AVAssetImageGenerator(asset: videoAsset)
            generator.appliesPreferredTrackTransform = true
            generator.requestedTimeToleranceBefore = .zero
            generator.requestedTimeToleranceAfter = .zero
            generator.maximumSize = CGSize(width: FRAME_WIDTH * 2.0, height: FRAME_HEIGHT * 2.0)
            DispatchQueue.global(qos: .default).async {
                var times: [NSValue] = []
                let offset: CGFloat = CMTimeGetSeconds(self.videoAsset.duration) / frameCount
                for i in 0 ..< Int(frameCount) {
                    let time = CMTimeMakeWithSeconds(offset * CGFloat(i), preferredTimescale: self.videoAsset.duration.timescale)
                    times.append(NSValue(time: time))
                }
                
                var i: CGFloat = 0
                generator.generateCGImagesAsynchronously(forTimes: times) { requestTime, cgImage, realTime, result, error in
                    if let cgImage = cgImage {
                        let image = UIImage(cgImage: cgImage)
                        DispatchQueue.main.async {
                            let imageView = UIImageView(image: image)
                            imageView.contentMode = .scaleAspectFill
                            imageView.clipsToBounds = true
                            imageView.frame = CGRect(x: CGFloat(i) * FRAME_WIDTH, y: 0, width: FRAME_WIDTH, height: FRAME_HEIGHT)
                            self.thumbsScrollView.addSubview(imageView)
                            i += 1
                        }
                    }
                }
            }
        }
    }
    
    public func showSeekTime(_ time: CMTime) {
        indicatorImageView.frame = CGRect(origin: CGPoint(x: thumbsScrollView.frame.origin.x - 2.0 + CGFloat(CMTimeGetSeconds(time)) * onesec, y: thumbsScrollView.frame.origin.y), size: indicatorImageView.frame.size)
    }
    
    fileprivate func showTrimDuration() {
        let duration: CGFloat = (rightPanImageView.frame.origin.x + rightPanImageView.frame.size.width - leftPanImageView.frame.origin.x - 8.0) / onesec
        durationLabel.text = Utilities.timeString(Int(duration))
    }


    // MARK: - IBAction
    @IBAction func didTapDone(_ sender: UIButton) {
        if CMTimeCompare(startTime, .zero) == 0, CMTimeCompare(endTime, videoAsset.duration) == 0 {
            delegate?.didTrimDone(self, nil, nil)
            return
        }
        let filename = Utilities.generateRandomFileName(fileExtension: "mov")
        let path = Utilities.generateFilePath(filename: filename, projectId: media.projectId)
        //delegate?.didTrimDone(self, nil, nil)
        SVProgressHUD.show()
        _ = VideoManager.shared.trimVideo(videoAsset, path, startTime, endTime) { success, error in
            let blurAsset = AVURLAsset(url: URL(fileURLWithPath: self.media.blurpath()))
            let blurname = Utilities.generateRandomFileName(fileExtension: "mov")
            let blurpath = Utilities.generateFilePath(filename: blurname, projectId: self.media.projectId)
            _ = VideoManager.shared.trimVideo(blurAsset, blurpath, self.startTime, self.endTime, { success, error in
                SVProgressHUD.dismiss()
                if success {
                    self.delegate?.didTrimDone(self, URL(fileURLWithPath: path), URL(fileURLWithPath: blurpath))
                }
            })
        }
    }
    
    // MARK: - UIGestureRecognizer
    @IBAction func handleLeftPanGestureRecognizer(_ sender: UIPanGestureRecognizer) {
        let location = sender.translation(in: self)
        var constant = leadingLeftConstraint.constant + location.x
        if constant < -4 {
            constant = -4
        }
        
        if rightPanImageView.frame.origin.x + rightPanImageView.frame.size.width - thumbsScrollView.frame.origin.x - constant - 8 < onesec {
            constant = rightPanImageView.frame.origin.x + rightPanImageView.frame.size.width - thumbsScrollView.frame.origin.x - onesec - 8
        }
        
        leadingLeftConstraint.constant = constant;
        sender.setTranslation(.zero, in: self)
        layoutIfNeeded()
        
        showTrimDuration()
        startTime = CMTimeMakeWithSeconds((leftPanImageView.frame.origin.x + 4 - thumbsScrollView.frame.origin.x) / onesec, preferredTimescale: videoAsset.duration.timescale)
        //selectedVideo.startTime = startTime;
        delegate?.didChangeTrimView(self, startTime: startTime)
        indicatorImageView.frame = CGRect(origin: CGPoint(x: leftPanImageView.frame.origin.x + 4.0, y: leftPanImageView.frame.origin.y), size: indicatorImageView.frame.size)
    }

    @IBAction func handleRightPanGestureRecognizer(_ sender: UIPanGestureRecognizer) {
        let location = sender.translation(in: self)
        var constant = trailingRightConstraint.constant + location.x
        if constant > 4 {
            constant = 4
        }
        
        if thumbsScrollView.frame.size.width - leftPanImageView.frame.origin.x + thumbsScrollView.frame.origin.x + constant - 8 < onesec {
            constant = onesec - thumbsScrollView.frame.size.width + leftPanImageView.frame.origin.x - thumbsScrollView.frame.origin.x + 8
        }
        
        trailingRightConstraint.constant = constant;
        sender.setTranslation(.zero, in: self)
        layoutIfNeeded()
        
        showTrimDuration()
        endTime = CMTimeMakeWithSeconds((rightPanImageView.frame.origin.x + rightPanImageView.frame.size.width - 4.0 - thumbsScrollView.frame.origin.x) / onesec, preferredTimescale: videoAsset.duration.timescale)
        //selectedVideo.endTime = endTime;
        delegate?.didChangeTrimView(self, endTime: endTime)
        indicatorImageView.frame = CGRect(origin: CGPoint(x: rightPanImageView.frame.origin.x + rightPanImageView.frame.size.width - 4.0 - indicatorImageView.frame.size.width, y: leftPanImageView.frame.origin.y), size: indicatorImageView.frame.size)
    }
}
