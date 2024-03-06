//
//  AudioRecorderView.swift
//  SlideShow
//
//  Created by Hua Wan on 5/20/22.
//

import UIKit
import SwiftColor

class AudioRecorderView: UIView {

    @IBOutlet weak var timesScrollView: UIScrollView!
    @IBOutlet weak var recordButton: UIButton!
    @IBOutlet weak var waveformView: WaveformLiveView!
    @IBOutlet weak var indicatorImageView: UIImageView!
    
    fileprivate var recorder: SCAudioManager = SCAudioManager()
    fileprivate var imageDrawer: WaveformImageDrawer = WaveformImageDrawer()
    var recordURL: URL!
    
    class func loadFromNib() -> AudioRecorderView {
        let bundles = Bundle.main.loadNibNamed("AudioRecorderView", owner: self, options: nil)!.filter { bundle in
            return bundle is AudioRecorderView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! AudioRecorderView
        } else {
            return bundles.last as! AudioRecorderView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let project = ProjectManager.current
        recorder.projectId = project.id
        recorder.recordingDelegate = self
        waveformView.configuration = waveformView.configuration.with(style: .striped(Waveform.Style.StripeConfig(color: UIColor("#29EFF6"), width: 2.0, spacing: 2.0, lineCap: .round)))
        recorder.prepareAudioRecording()
        
        configTimesScrollView()
        
        reset()
    }
    
    fileprivate func configTimesScrollView() {
        _ = timesScrollView.subviews.map { $0.removeFromSuperview() }
        let width: CGFloat = 4.0 * 25.0
        let count = 60 * 60
        let startX: CGFloat = 16.0
        timesScrollView.contentSize = CGSize(width: width * CGFloat(count), height: 0)
        timesScrollView.isUserInteractionEnabled = false
        for i in 0 ..< count {
            let label = UILabel(frame: CGRect(origin: .zero, size: CGSize(width: width, height: 40)))
            label.text = Utilities.timeString(i)
            label.textAlignment = .center
            label.textColor = UIColor("#BBBEBF")
            label.font = UIFont.medium(size: 10)
            label.center = CGPoint(x: startX + CGFloat(i) * width, y: 20)
            timesScrollView.addSubview(label)
        }
    }
    
    func reset() {
        waveformView.reset()
        timesScrollView.contentOffset = .zero
        indicatorImageView.frame = CGRect(x: waveformView.frame.origin.x, y: waveformView.frame.origin.y, width: 2.0, height: waveformView.frame.height)
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    // MARK: - IBAction
    @IBAction func didTapRecording() {
        if recorder.recording() {
            recorder.stopRecording()
            recordButton.isSelected = false
        } else {
            waveformView.reset()
            recorder.startRecording()
            recordButton.isSelected = true
        }
    }
}

extension AudioRecorderView: RecordingDelegate {
    func audioManager(_ manager: SCAudioManager!, didAllowRecording flag: Bool) {
        if flag == false {
            Utilities.showAlertView("", "Recording must be allowed in Settings to work.")
        }
    }
    
    func audioManager(_ manager: SCAudioManager!, didFinishRecordingSuccessfully flag: Bool) {
        if flag == true {
            recordURL = manager.recordedAudioFileURL()
        }
    }
    
    func audioManager(_ manager: SCAudioManager!, didUpdateRecordProgress progress: CGFloat, currentTime: TimeInterval) {
        print("current progress: \(progress), time: \(currentTime)")
        let linear = 1 - pow(10, manager.lastAveragePower() / 20)
        // Here we add the same sample 3 times to speed up the animation.
        // Usually you'd just add the sample once.
        waveformView.add(samples: [linear, linear, linear])
        var frame = CGRect(x: waveformView.frame.origin.x + currentTime * 100.0, y: waveformView.frame.origin.y, width: 2.0, height: waveformView.frame.height)
        if frame.origin.x > waveformView.frame.maxX {
            timesScrollView.contentOffset = CGPoint(x: frame.origin.x - waveformView.frame.maxX, y: 0)
            frame.origin.x = waveformView.frame.maxX
        } else {
            timesScrollView.contentOffset = .zero
        }
        indicatorImageView.frame = frame
    }
}
