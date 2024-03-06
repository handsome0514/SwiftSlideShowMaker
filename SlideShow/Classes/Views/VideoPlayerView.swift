//
//  VideoPlayerView.swift
//  SlideShow
//
//  Created by Hua Wan on 5/30/22.
//

import UIKit
import AVKit

class VideoPlayerView: UIView {
    
    public var videoPlayer: AVPlayer!
    public var playerLayer: AVPlayerLayer!
    public var playerItem: AVPlayerItem!
    public var asset: AVAsset!
    public var videoAsset: AVAsset!
    public var timeObserver: Any? = nil
    
    var isPlaying: Bool {
        if videoPlayer == nil {
            return false
        }
        return videoPlayer.rate != 0
    }
    
    var startTime: CMTime = .zero
    var endTime: CMTime = .zero
    
    var playerDidEndTimeHandler: ((_ view: VideoPlayerView) -> Void)? = nil
    var playerDidPlayHandler: ((_ view: VideoPlayerView, _ time: CMTime) -> Void)? = nil
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        initView()
    }
    
    fileprivate func initView() {
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if playerLayer != nil {
            playerLayer.frame = bounds
        }
    }
    
    fileprivate func generateVideoComposition(_ videoAsset: AVAsset, _ startTime: CMTime, _ endTime: CMTime) -> AVMutableComposition? {
        let mixComposition = AVMutableComposition()
        let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid)
        let videoDataSources = videoAsset.tracks(withMediaType: .video)
        let assetTrack = videoDataSources.first!
        let videoDuration = CMTimeSubtract(endTime, startTime)
        do {
            try videoTrack!.insertTimeRange(CMTimeRange(start: startTime, duration: videoDuration), of: assetTrack, at: .zero)
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
        videoTrack?.preferredTransform = assetTrack.preferredTransform

        let audioDataSources = videoAsset.tracks(withMediaType: .audio)
        if audioDataSources.count > 0 {
            let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            let assetTrack = audioDataSources.first!
            do {
                try audioTrack!.insertTimeRange(CMTimeRange(start: startTime, duration: videoDuration), of: assetTrack, at: .zero)
            } catch {
                print(error.localizedDescription)
                return nil
            }
        }
        
        return mixComposition
    }
    
    @objc fileprivate func handlePlayerEndTime(_ notification: Notification) {
        if let item = notification.object as? AVPlayerItem, item == playerItem {
            playerDidEndTimeHandler?(self)
        }
    }
    
    func configPlayerView(_ url: URL, startTime: CMTime, endTime: CMTime) {
        removePlayerView()
        asset = AVURLAsset(url: url)
        //videoAsset = generateVideoComposition(asset, startTime, endTime)!
        videoAsset = asset
        playerItem = AVPlayerItem(asset: videoAsset)
        videoPlayer = AVPlayer(playerItem: playerItem)
        playerLayer = AVPlayerLayer(player: videoPlayer)
        playerLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(playerLayer)
        timeObserver = videoPlayer.addPeriodicTimeObserver(forInterval: CMTimeMakeWithSeconds(0.01, preferredTimescale: asset.duration.timescale), queue: DispatchQueue.main, using: { time in
            if self.isPlaying == false {
                return
            }
            
            self.playerDidPlayHandler?(self, time)
            
            if CMTimeCompare(self.endTime, time) == -1 {
                self.playerDidEndTimeHandler?(self)
                self.seek(self.startTime)
                self.pause()
            }
        })
        self.startTime = startTime
        self.endTime = endTime
        //NotificationCenter.default.addObserver(self, selector: #selector(handlePlayerEndTime(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func removePlayerView() {
        if videoPlayer != nil {
            videoPlayer.pause()
            videoPlayer = nil
        }
        
        if playerLayer != nil {
            playerLayer.removeFromSuperlayer()
            playerLayer = nil
        }
        
        NotificationCenter.default.removeObserver(self)
        playerItem = nil
        asset = nil
        videoAsset = nil
    }
    
    func play() {
        videoPlayer.play()
    }
    
    func pause() {
        videoPlayer.pause()
    }
    
    func seek(_ time: CMTime) {
        videoPlayer.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero)
    }

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
