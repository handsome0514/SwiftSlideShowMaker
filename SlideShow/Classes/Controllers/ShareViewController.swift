import UIKit
import LinearProgressBar
import SVProgressHUD
import AVKit
import AssetsLibrary
import MediaPlayer
import AVFoundation
import MobileCoreServices
import Photos
import SwiftVideoGenerator
import RealmSwift
import SlideShowMaker

class ShareViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    
    @IBOutlet weak var resolutionLabel: UILabel!
    @IBOutlet weak var exportLabel: UILabel!
    @IBOutlet weak var frameLabel: UILabel!
    
    var videoUrl: URL! = nil
    
    var isShareButtonClicked: Bool = false
    
    var editViewController: EditViewController!
   
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: - IBAction
    @IBAction func didTapClose(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapResolution(_ sender: UIButton) {
        let contentView = ResolutionView.loadFromNib()
        contentView.frame = CGRect(x: 24, y: 0, width: view.frame.width - 48, height: contentView.frame.height)
        let popup = FFPopup(contentView: contentView, showType: .slideInFromBottom, dismissType: .slideOutToBottom, maskType: .dimmed, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
        popup.didFinishShowingBlock = {
            contentView.selectionAlpha = 1.0
            contentView.reloadData()
        }
        let layout = FFPopupLayout(horizontal: .center, vertical: .bottom, offset: 10 + view.safeAreaInsets.bottom)
        popup.show(layout: layout)
    }
    
    @IBAction func didTapFrame(_ sender: UIButton) {
        let contentView = FrameRateView.loadFromNib()
        contentView.frame = CGRect(x: 24, y: 0, width: view.frame.width - 48, height: contentView.frame.height)
        let popup = FFPopup(contentView: contentView, showType: .slideInFromBottom, dismissType: .slideOutToBottom, maskType: .dimmed, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
        let layout = FFPopupLayout(horizontal: .center, vertical: .bottom, offset: 10 + view.safeAreaInsets.bottom)
        popup.show(layout: layout)
    }
    
    
    
    @IBAction func didTapShare(_ sender: UIButton) {
        self.isShareButtonClicked = true
        exportVideo()
    }
     
    // MARK: - Save Button Click Event
    @IBAction func didTapSave(_ sender: UIButton) {
        exportVideo()
    }
        
    // MARK: - ImageToVideo module
    func _exportVideo() {
        var audioURLs = [URL]()
        var imageURLs = [URL]()
        var images = [UIImage]()
        
        print("\(ProjectManager.current.duration())")
        
        for audio in ProjectManager.current.musics {
            let audioURL = URL(fileURLWithPath: ProjectManager.current.path() + audio.filename)
            audioURLs.append(audioURL)
        }
        
        for image in Medias.frames {
//            let img = UIImage(contentsOfFile: image.path)
            images.append(image)
        }
                        
        var audio: AVURLAsset?
        var timeRange: CMTimeRange?
        
        if audioURLs.count != 0 {
            audio = AVURLAsset(url: audioURLs[0])
            let audioDuration = CMTime(seconds: Double((Int(ProjectManager.current.duration()))), preferredTimescale: audio!.duration.timescale)
            timeRange = CMTimeRange(start: CMTime.zero, duration: audioDuration)
        }
                        
        // OR: VideoMaker(images: images, movement: ImageMovement.fade)
        let maker = VideoMaker(images: images, transition: ImageTransition.none)
        
        maker.videoDuration = Int(ProjectManager.current.duration())
        maker.videoName = "\(ProjectManager.current.name) + .mov"
        
        maker.exportVideo(audio: audio, audioTimeRange: timeRange, completed: { success, videoURL in
            if let url = videoURL {
                print(url)  // /Library/Mov/Video.mov
                UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
                SVProgressHUD.dismiss()
                print("DONE")
            }
        }).progress = { progress in
            print(progress)
        }
    }
    
    // MARK: - SwiftVideoGenerator module | No used
    func exportVideo() {
        
        var audioURLs = [URL]()
        var imageURLs = [URL]()
        var images = [UIImage]()
        
        for audio in ProjectManager.current.musics {
            let audioURL = URL(fileURLWithPath: ProjectManager.current.path() + audio.filename)
            audioURLs.append(audioURL)
        }
        
        for image in ProjectManager.current.medias {
            let imageURL = URL(fileURLWithPath: ProjectManager.current.path() + image.filename)
            imageURLs.append(imageURL)
            let img = UIImage(contentsOfFile: imageURL.path)
            images.append(img!)
        }
        
        VideoGenerator.fileName = ProjectManager.current.name
        VideoGenerator.shouldOptimiseImageForVideo = true
        VideoGenerator.videoBackgroundColor = .black
        
        SVProgressHUD.show(withStatus: "0%")
        VideoGenerator.current.generate(withImages: images, andAudios: audioURLs, andType: .multiple, { (progress) in
            // MARK: Show progress when export video
            SVProgressHUD.show(withStatus: String(format:"%.0f", progress.fractionCompleted * 100) + "%");
        }) { [self] (result) in
            switch result {
            case .success(let url):
                print(url)
                self.videoUrl = url
                UISaveVideoAtPathToSavedPhotosAlbum(url.path, nil, nil, nil)
                
                SVProgressHUD.dismiss()
                
                if (!self.isShareButtonClicked) {
                    showAlert(_title: "", _message: "Your slideshow has been successfully saved")
                    
                } else {
                    self.isShareButtonClicked = false
                    let video: [Any] = [self.videoUrl, "Check it out!"]
                    let activityController = UIActivityViewController(activityItems: video, applicationActivities: nil)
                    activityController.popoverPresentationController?.sourceView = self.view
                    activityController.excludedActivityTypes = [
                        .mail, .message, .postToFacebook
                    ]
                    
                    self.present(activityController, animated: true, completion: nil)
                    
                    activityController.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, arrayReturnedItems: [Any]?, error: Error?) in
                        if completed {
                            return
                        }
                        else {
                            
                        }
                        if let shareError = error {
                            
                        }
                        showAlert(_title: "", _message: "Your slideshow has been successfully shared")
                        
                    }
                }
                
            case .failure(let error):
                print(error)
            }
          }
        
    }
    
    // MARK: Show Alert | params: String | return obj
    func showAlert(_title: String, _message: String) {
        // Create the alert controller
        let alertController = UIAlertController(title: _title, message: _message, preferredStyle: .alert)
        // Create the actions
        let okAction = UIAlertAction(title: "OK", style: .cancel) { (action) in }
        // Add the actions
        alertController.addAction(okAction)
        // Present the alert
        self.present(alertController, animated: true, completion: nil)
    }
    
}
