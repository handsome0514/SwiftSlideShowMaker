//
//  VideoManager.swift
//  SlideShow
//
//  Created by Hua Wan on 6/1/22.
//

import UIKit
import CoreMedia

class VideoManager: NSObject {
    static let shared = VideoManager()
    
    func trimVideo(_ asset: AVAsset, _ path: String, _ startTime: CMTime, _ endTime: CMTime, _ completion: ((Bool, Error?) -> Void)?) -> AVAssetExportSession {
        try? FileManager.default.removeItem(atPath: path)
        let outputURL = URL(fileURLWithPath: path)
        let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHighestQuality)!
        exportSession.outputURL = outputURL
        exportSession.outputFileType = .mov
        exportSession.timeRange = CMTimeRange(start: startTime, end: endTime)
        exportSession.shouldOptimizeForNetworkUse = true
        exportSession.exportAsynchronously {
            if let completion = completion {
                DispatchQueue.main.async {
                    if let error = exportSession.error {
                        completion(false, error)
                    } else {
                        completion(true, nil)
                    }
                }
            }
        }
        return exportSession
    }
}
