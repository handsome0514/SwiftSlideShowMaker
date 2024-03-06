import UIKit
import CoreServices
import Photos
import SwiftColor
import AVKit
import SVProgressHUD
import RealmSwift
import GPUImage
import PhotosUI
import ReplayKit
import SwiftVideoGenerator
import Foundation
import AVFoundation

// MARK: UIView extension
extension UIView {
    // get image from uiview to uiimage
    func snapshotImage(afterScreenUpdates: Bool = true) -> UIImage? {
        let rendererFormat = UIGraphicsImageRendererFormat.default()
        rendererFormat.opaque = isOpaque
        let renderer = UIGraphicsImageRenderer(bounds: bounds, format: rendererFormat)
        let image = renderer.image { context in
            drawHierarchy(in: bounds, afterScreenUpdates: afterScreenUpdates)
        }
        return image
    }
}

// MARK: FrameExtractor
class FrameExtractor {
    private weak var targetView: UIView?
    private var displayLink: CADisplayLink?
    var lastSnapshotTime: TimeInterval = 0
    // constructor
    init () {}
    // initialize
    func setView(targetView: UIView) {
        self.targetView = targetView
    }
    // start capture
    func startCapture() {
        displayLink?.invalidate()
        displayLink = CADisplayLink(target: self, selector: #selector(captureFrame))
        displayLink?.add(to: .current, forMode: .default)
        lastSnapshotTime = CACurrentMediaTime()
    }
    // stop capture
    func stopCapture() {
        displayLink?.invalidate()
        displayLink = nil
    }
    // call caputre frame from uiview | every time or static time
    @objc private func captureFrame() {
//        takeSnapshot()
        let now = displayLink!.timestamp
        if now - lastSnapshotTime >= 0.2 {
            takeSnapshot()
            lastSnapshotTime = now
        }
    }
    // screenshot
    func takeSnapshot() {
        guard let targetView = targetView else { return }
//        let image = captureImage(from: targetView)
        let image = targetView.snapshotImage()
        Medias.frames.append(image!)
    }
    // caputre image from uiview to uiimage
    private func captureImage(from view: UIView) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        view.layer.render(in: context)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        return image
    }
}

// MARK: TabItem
enum TabItem: Int {
    case edit = 101
    case effect = 102
    case music = 103
    case arrange = 104
    case time = 105
}

// MARK: Medias
struct Medias {
    static var medias: [AVPlayer] = []
    static var current_project: SSProject! = nil
    static var frames: [UIImage] = []
    static var state: Int? = 0
}

// MARK: Constants
let TEXTVIEW_FRAME = CGRect(x: 0, y: 0, width: 140, height: 100)
let TEXT_OFFSET: CGFloat = 20

// MARK: EditViewController
@objc class EditViewController: UIViewController, AVPlayerItemOutputPullDelegate {
    // Variables definition
    let captureSession = AVCaptureSession()
    let output = AVCaptureVideoDataOutput()
    private var screenRecorder = Recorder()
    var frameExtractor = FrameExtractor()
    var isRecording: Bool = false
    var player: AVPlayer! = nil
    var playerItem : AVPlayerItem! = nil
    var currentPlayViewIndex: Int = -1
    var frames:[UIImage] = []
    private var generator:AVAssetImageGenerator?
    @IBOutlet weak var editDoneButton: UIButton!
    @IBOutlet weak var timelineButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var videoView: UIView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var blurImageView: UIImageView!
    @IBOutlet weak var thumbImageView: UIImageView!
    @IBOutlet weak var tabView: UIView!
    @IBOutlet weak var controlsView: UIView!
    @IBOutlet weak var playsView: UIView!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var seekSlider: UISlider!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var assetButtonView: UIView!
    @IBOutlet weak var previewEndButton: UIButton!
    @IBOutlet weak var artButton: UIButton!
    @IBOutlet weak var textButton: UIButton!
    @IBOutlet weak var textDoneButton: UIButton!
    @IBOutlet weak var videoPlayerView: VideoPlayerView!
    @IBOutlet weak var trimPlayView: UIView!
    @IBOutlet weak var trimPlayButton: UIButton!
    @IBOutlet weak var sheetMenuView: UIView!
    @IBOutlet weak var menuUndoView: UIView!
    @IBOutlet weak var menuRedoView: UIView!
    @IBOutlet weak var menuRevertView: UIView!
    @IBOutlet weak var viewPlayerView: UIView!
    @IBOutlet weak var viewPlayerRecoverView: UIView!
    @IBOutlet weak var previewPlayerView: SSPlayer!
    @IBOutlet var orderMenuView: UIView!
    @IBOutlet weak var orderCustomButton: UIButton!
    @IBOutlet weak var orderShuffleButton: UIButton!
    @IBOutlet weak var orderDateButton: UIButton!
    @IBOutlet weak var orderCheckImageView: UIImageView!
    @IBOutlet weak var bottomMenuConstraint: NSLayoutConstraint!
    @IBOutlet weak var bottomRevertConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthOrderConstraint: NSLayoutConstraint!
    @IBOutlet weak var topOrderCheckConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightControlsConstraint: NSLayoutConstraint!
    @IBOutlet weak var heightTabConstraint: NSLayoutConstraint!
    
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
    
    fileprivate var lastBottomView: UIView? = nil
    fileprivate var popupView: FFPopup!
    fileprivate var previewController: SSPlayerController!
    
    fileprivate lazy var playerView: UIView = {
        return UIView(frame: .zero)
    }()
    
    var selectedAssets: [MediaAsset] = []
    
    fileprivate lazy var mediasView: EditView = {
        let view = EditView.loadFromNib()
        let height = controlsView.frame.height - playsView.frame.maxY
        view.frame = CGRect(x: 0, y: tabView.frame.origin.y - height, width: UIScreen.main.bounds.width, height: height)
        view.project = ProjectManager.current
        view.delegate = self
        view.backgroundColor = .clear
        self.view.addSubview(view)
        return view
    }()
    
    fileprivate lazy var effectView: EffectView = {
        let view = EffectView.loadFromNib()
        view.frame = CGRect(x: 0, y: playsView.frame.maxY, width: controlsView.frame.width, height: controlsView.frame.height - playsView.frame.maxY)
        
        view.didSelectTheme = {
                        
            if view.themeIndex > 0 {
                let musicTitle = ThemeManager.sharedInstance().themes[view.themeIndex]["music"] as! String
                let project = ProjectManager.current
                do {
                    try sharedRealm.write {
                        let music = Music()
                        music.projectId = ""
                        music.name = musicTitle
                        music.itunespath = ""
                        music.filename = musicTitle
                        music.start = 0
                        music.end = Float(project.duration())
                        
                        if project.musics.count > 0 {
                            project.musics.first?.deleteFile()
                            project.musics.remove(at: 0)
                        }
                        
                        project.musics.append(music)
                    }
                } catch {
                    
                }
            }
            
            // song a theme music
            self.musicBottomView.reloadData()
            
//            if self.previewController != nil {
//                if self.playButton.isSelected {
//                    self.previewController.pause()
//                    self.audioPlayer?.pause()
//                }
//            }
            self.playAudio(false)
//            self.seekSlider.value = 0
//            self.seekSliderChanged(self.seekSlider)

            self.playButtonPressed1(self.currentProject!)
        }
        
        controlsView.addSubview(view)
        
        return view
    }()
    
    fileprivate lazy var musicBottomView: MusicBottomView = {
        let view = MusicBottomView.loadFromNib()
        view.delegateViewCtrl = self
        let height = controlsView.frame.height - playsView.frame.maxY
        view.frame = CGRect(x: 0, y: tabView.frame.origin.y - height, width: UIScreen.main.bounds.width, height: height)
        view.didSelectMusic = {
            
            self.seekToFirstPoint()
            
            let storyboard = UIStoryboard(name: UIDevice.current.userInterfaceIdiom == .phone ? "Edit" : "Edit", bundle: nil) //"Edit_iPad"
            let controller = storyboard.instantiateViewController(withIdentifier: "MusicViewController") as! MusicViewController
            controller.musicPickerHandler = { name, url in
                let project = ProjectManager.current
                //let asset = AVURLAsset(url: url)
                do {
                    try sharedRealm.write {
                        let music = Music()
                        music.projectId = project.id
                        music.name = name
                        if url.absoluteString.contains("ipod-library://") {
                            music.itunespath = url.absoluteString
                            music.filename = ""
                        } else {
                            music.itunespath = ""
                            music.filename = url.lastPathComponent
                        }
                        music.start = 0
                        music.end = Float(project.duration())
                        
                        if project.musics.count > 0 {
                            project.musics.first?.deleteFile()
                            project.musics.remove(at: 0)
                        }
                        
                        project.musics.append(music)
                        self.musicBottomView.reloadData()
                        
//                        if self.previewController != nil {
//                            if self.playButton.isSelected {
//                                self.previewController.pause()
//                                self.audioPlayer?.pause()
//                            }
//                        }
                        self.playAudio(false)
//                        self.seekSlider.value = 0
//                        self.seekSliderChanged(self.seekSlider)
                        
                        self.playButtonPressed1(self.currentProject!)
                        
//                        self.effectView.updateThemeIndex(index: 0)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
            let navcontroller = UINavigationController(rootViewController: controller)
            navcontroller.modalPresentationStyle = .fullScreen
            navcontroller.isNavigationBarHidden = true
            self.present(navcontroller, animated: true, completion: nil)
        }
        view.didSelectRecord = {
            self.musicBottomView.isHidden = true
            self.tabView.isHidden = true
            self.audioRecordView.isHidden = false
            self.audioRecordView.reset()
            self.editButton.isHidden = true
            self.shareButton.isHidden = true
            self.editDoneButton.isHidden = false
        }
        view.didPauseVideoPlay = {
            self.seekToFirstPoint()
        }
        self.view.addSubview(view)
        return view
    }()
    
    fileprivate lazy var audioRecordView: AudioRecorderView = {
        let view = AudioRecorderView.loadFromNib()
        var frame = self.musicBottomView.frame
        frame.size.height += self.tabView.frame.height
        view.frame = frame
        view.isHidden = true
        self.view.addSubview(view)
        return view
    }()
    
    fileprivate lazy var arrangeView: ArrangeView = {
        let view = ArrangeView.loadFromNib()
        view.frame = CGRect(x: 0, y: playsView.frame.maxY, width: controlsView.frame.width, height: controlsView.frame.height - playsView.frame.maxY)
        view.project = ProjectManager.current
        view.delegate = self
        controlsView.addSubview(view)
        return view
    }()
    
    fileprivate lazy var timeView: TimeView = {
        let view = TimeView.loadFromNib()
        view.frame = CGRect(x: 0, y: playsView.frame.maxY, width: controlsView.frame.width, height: controlsView.frame.height - playsView.frame.maxY)
        view.project = ProjectManager.current
        view.delegate = self
        view.parentViewController = self
        controlsView.addSubview(view)
        return view
    }()
    
    fileprivate lazy var textsView: TextsView = {
        let textsView = TextsView.loadFromNib()
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 260 : 340
        let frame = CGRect(x: 0, y: self.view.frame.height - height, width: self.view.frame.width, height: height)
        textsView.frame = frame
        textsView.delegate = self
        return textsView
    }()
    
    fileprivate lazy var editBoardView: EditBoardView = {
        let view = EditBoardView.loadFromNib()
        let height = controlsView.frame.height - playsView.frame.maxY + tabView.frame.height
        view.frame = CGRect(x: 0, y: self.view.frame.height - self.view.safeAreaInsets.bottom - height, width: UIScreen.main.bounds.width, height: height)
        view.project = ProjectManager.current
        view.cropViewDelegate = self
        view.timeViewDelegate = self
        view.artsViewDelegate = self
        view.delegate = self
        view.parentViewController = self
        view.backgroundColor = .clear
        return view
    }()
    
    fileprivate lazy var trimPlayerView: VideoPlayerView = {
        let view = VideoPlayerView(frame: .zero)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handlePauseTrimVideo))
        view.addGestureRecognizer(tapGesture)
        return view
    }()
    
    fileprivate var selectedMediaIndex = 0
    fileprivate var lastSelectedIndex = 0
    fileprivate var selectedTabItem: TabItem = .edit
    fileprivate var insertMediaIndex: Int = -1
    
    fileprivate var activeImageView: TVImageView? = nil
    fileprivate var activeTextView: TVTextView? = nil
    fileprivate var previousPoint = CGPoint.zero
    fileprivate var arrayImageViews: [TVImageView] = []
    fileprivate var arrayTextViews: [TVTextView] = []
    fileprivate var arrayArrayImageViews: [[TVImageView]] = []
    fileprivate var arrayArrayTextViews: [[TVTextView]] = []
    fileprivate var prevSeekValue: Float = 0
    fileprivate var recordIndex = 1
    fileprivate var isFirstLayout = true
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait, .portraitUpsideDown]
    }
    
    override var shouldAutorotate: Bool {
        return false
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        editViewCtrl = self

        // Do any additional setup after loading the view.
        
        widthOrderConstraint.constant = UIScreen.main.bounds.width - 108
        
        timelineButton.isHidden = true
        
        textsView.loadFonts()
        
        seekSlider.setThumbImage(UIImage(named: "SliderThuƒmb"), for: .normal)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(deactivateViews(tapGesture:)))
        tapGesture.numberOfTapsRequired = 1
        editView.addGestureRecognizer(tapGesture)
        
        effectView.isHidden = true
        
        orderCustomButton.titleEdgeInsets = UIEdgeInsets(top: -10, left: 44, bottom: 10, right: -44)
        orderShuffleButton.titleEdgeInsets = UIEdgeInsets(top: -10, left: 44, bottom: 10, right: -44)
        orderDateButton.titleEdgeInsets = UIEdgeInsets(top: -12, left: 44, bottom: 12, right: -44)
        
        selectedTabItem = .edit
        
        self.delayLoadProject()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Medias.frames = []
        
        NotificationCenter.default.addObserver(self, selector: #selector(handlePreviewPlaying(_:)), name: NSNotification.Name(rawValue: "SSPlayerControllerPlaying"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handlePreviewStopped(_:)), name: NSNotification.Name(rawValue: "SSPlayerControllerStopped"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if self.audioPlayer != nil {
            if ProjectManager.current.musics.count > 0 {
                let item = ProjectManager.current.musics.last!
                if item.isFadeout {
                    self.audioPlayer?.setVolume(0, fadeDuration: 2)
                } else {
                    self.audioPlayer?.stop()
                }
            } else if effectView.themeIndex > 0 {
                self.audioPlayer?.stop()
            }
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        view.bringSubviewToFront(orderMenuView)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if isFirstLayout {
            isFirstLayout = false
            
            self.loadProject()
            
            deselectAllTabs()
            selectTabItem(.edit)
            
            mediasView.project = ProjectManager.current
            
            updateVideoView()
//            updateAssets(ProjectManager.current.medias[selectedMediaIndex], true)
            
            sheetMenuView.roundCorners(corners: [.topLeft, .topRight], radius: 20)
            
            bottomRevertConstraint.constant = self.view.safeAreaInsets.bottom + 20
            
            seekSlider.minimumValue = 0;
            updateSeekSlider()
            updateTimeLabel()
            updateOrderView()
            
            musicBottomView.isHidden = true
        }
    }
    
    fileprivate func tabBarView(for tag: Int) -> UIView {
        return tabView.viewWithTag(tag)!
    }
    
    fileprivate func deselectTabView(_ tabItem: TabItem) {
        if let view = tabView.viewWithTag(tabItem.rawValue) {
            for subview in view.subviews {
                if let imageView = subview as? UIImageView {
                    imageView.isHighlighted = false
                    imageView.backgroundColor = .clear
                }
                if let label = subview as? UILabel {
                    label.isHidden = false
                    label.textColor = .white
                }
            }
//            for constraint in view.constraints {
//                if constraint.firstItem is UILabel, constraint.secondItem is UIImageView {
//                    if UIDevice.current.userInterfaceIdiom == .phone {
//                        constraint.constant = -10
//                    } else {
//                        constraint.constant = -4
//                    }
//                }
//            }
        }
    }
    
    @objc func startRecording() {
            let recorder = RPScreenRecorder.shared()

        recorder.startRecording { error in
            if let unwrappedError = error {
                print(unwrappedError.localizedDescription)
            }
        }
//            recorder.startRecording{ (error) in
//                if let unwrappedError = error {
//                    print(unwrappedError.localizedDescription)
//                } else {
////                    self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Stop", style: .plain, target: self, action: #selector(self.stopRecording))
//                }
//            }
        }
    
    func tempURL() -> URL? {
        let directory = NSTemporaryDirectory() as NSString
        
        if directory != "" {
            let path = directory.appendingPathComponent(NSUUID().uuidString + ".mp4")
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    @objc func stopRecording() {
        let recorder = RPScreenRecorder.shared()
        
        let outputURL = tempURL()
        recorder.stopRecording(withOutput: outputURL!) { error in
            guard error == nil else {
                return
            }
        }
    }
    
    fileprivate func selectTabItem(_ tabItem: TabItem) {
        deselectAllTabs()
        
        if tabItem == .effect {
            // Start
            self.startRecording()
        } else if tabItem == .music {
            // Stop
            self.stopRecording()
        }
        if let view = tabView.viewWithTag(tabItem.rawValue) {
            for subview in view.subviews {
                if let imageView = subview as? UIImageView {
                    imageView.isHighlighted = true
//                    imageView.backgroundColor = MAIN_ACTIVE_COLOR_1
                }
                if let label = subview as? UILabel {
                    label.isHidden = false
                    label.textColor = MAIN_ACTIVE_COLOR_1
                }
            }
//            for constraint in view.constraints {
//                if constraint.firstItem is UILabel, constraint.secondItem is UIImageView {
//                    if UIDevice.current.userInterfaceIdiom == .phone {
//                        constraint.constant = 0
//                    } else {
//                        constraint.constant = 8
//                    }
//                }
//            }
        }
    }
    
    fileprivate func deselectAllTabs() {
        for item in TabItem.edit.rawValue...TabItem.time.rawValue {
            deselectTabView(TabItem(rawValue: item)!)
        }
    }
    
    fileprivate func hideAllSubviews() {
        mediasView.isHidden = true
        effectView.isHidden = true
        musicBottomView.isHidden = true
        arrangeView.isHidden = true
        timeView.isHidden = true
    }
    
    fileprivate func showBottomSubview() {
        
    }
    
    func showPurchaseView() -> Bool {
        if Int(ProjectManager.current.medias.count) >= 5  {
            if PurchaseManager.sharedManager.isPurchased() == false {
                PurchaseView.show().parentViewController = self
                return true
            }
        }
        return false
    }
    
    fileprivate func updateTimeLabel() {
        let duration = Int(ProjectManager.current.duration())
        timeLabel.text = Utilities.timeString(0) + "/" + Utilities.timeString(duration)
    }
    
    fileprivate func showBoardView(_ tabItem: TabItem) {
        hideAllSubviews()
        switch tabItem {
        case .edit:
            mediasView.isHidden = false
            
        case .effect:
            effectView.media = ProjectManager.current.medias[selectedMediaIndex]
            effectView.isHidden = false
            
        case .music:
            //musicView.isHidden = false
            musicBottomView.isHidden = false
            
        case .arrange:
            arrangeView.isHidden = false
            
        case .time:
            timeView.isHidden = false
            timeView.lockButton.isHidden = PurchaseManager.sharedManager.isPurchased()
        }
    }
    
    fileprivate func updateVideoView() {
        let project = ProjectManager.current
        let ratio = RatioType(rawValue: project.ratio)!.ratio
        videoView.frame = frame(for: ratio, parentView: editView)
        let media = project.medias[selectedMediaIndex]
        let mediaType = MediaType(rawValue: media.type)!
        if mediaType == .image {
            thumbImageView.image = UIImage(contentsOfFile: media.path())
        } else {
            thumbImageView.image = Utilities.generateThumbImage(videoURL: URL(fileURLWithPath: media.path()))
        }
        blurImageView.image = thumbImageView.image!.blurImage()
        thumbImageView.transform = .identity
        blurImageView.transform = .identity
        thumbImageView.frame = frame(for: thumbImageView.image!.size.width / thumbImageView.image!.size.height, parentView: videoView)
        blurImageView.frame = CGRect(x: 0, y: 0, width: videoView.frame.width, height: videoView.frame.height)
        if media.degree == 90 || media.degree == 270 {
            blurImageView.frame = CGRect(x: 0, y: 0, width: videoView.frame.height, height: videoView.frame.width)
        }
        let angle = media.degree * .pi / 180.0
        let rotatedTransform = CGAffineTransform.identity.rotated(by: CGFloat(angle))
        blurImageView.transform = blurImageView.transform.concatenating(rotatedTransform)
        
        if media.isHorizontalFlip {
            if media.degree == 0 || media.degree == 180 {
                let flipTransform = CGAffineTransform.identity.scaledBy(x: -1.0, y: 1.0)
                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
            } else if media.degree == 90 || media.degree == 270 {
                let flipTransform = CGAffineTransform.identity.scaledBy(x: 1.0, y: -1.0)
                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
            }
        }
        if media.isVerticalFlip {
            if media.degree == 0 || media.degree == 180 {
                let flipTransform = CGAffineTransform.identity.scaledBy(x: 1.0, y: -1.0)
                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
            } else if media.degree == 90 || media.degree == 270 {
                let flipTransform = CGAffineTransform.identity.scaledBy(x: -1.0, y: 1.0)
                blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
            }
        }
        blurImageView.center = CGPoint(x: videoView.frame.width / 2.0, y: videoView.frame.height / 2.0)
        
        if project.colorIndex >= 0 {
            blurImageView.isHidden = true
            videoView.backgroundColor = UIColor(hexInt: APP_ARRAY_COLORS[project.colorIndex])
        } else {
            blurImageView.isHidden = false
        }
        
        do {
            try sharedRealm.write {
                project.frame = NSCoder.string(for: videoView.frame)
            }
        } catch {
            print(error.localizedDescription)
        }

        perform(#selector(updateContentTransform), with: nil, afterDelay: 0.1)

        if self.currentProject != nil {
            self.playButtonPressed1(self.currentProject!)
        }
    }
    
    @objc fileprivate func updateContentTransform() {
        let project = ProjectManager.current
        let media = project.medias[selectedMediaIndex]
        let contentType = ContentType(rawValue: project.contentType)!
        let imageSize = thumbImageView.image!.size
        if contentType == .scaleFill {
            var imageScale = CGFloat(fminf(Float(imageSize.width / videoView.frame.width), Float(imageSize.height / videoView.frame.height)))
            let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
            imageScale = fmax(scaledImageSize.width / videoView.frame.width, scaledImageSize.height / videoView.frame.height)
            do {
                try sharedRealm.write {
                    media.contentTransform = NSCoder.string(for: CGAffineTransform.identity.scaledBy(x: imageScale, y: imageScale))
                    thumbImageView.transform = NSCoder.cgAffineTransform(for: media.transform).concatenating(NSCoder.cgAffineTransform(for: media.contentTransform))
                }
            } catch {
                
            }
        } else {
            var imageScale = CGFloat(fmaxf(Float(imageSize.width / videoView.frame.width), Float(imageSize.height / videoView.frame.height)))
            let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
            imageScale = fmax(scaledImageSize.width / videoView.frame.width, scaledImageSize.height / videoView.frame.height)
            do {
                try sharedRealm.write {
                    media.contentTransform = NSCoder.string(for: CGAffineTransform.identity.scaledBy(x: imageScale, y: imageScale))
                    thumbImageView.transform = NSCoder.cgAffineTransform(for: media.transform).concatenating(NSCoder.cgAffineTransform(for: media.contentTransform))
                }
            } catch {
                
            }
        }
    }
    
    fileprivate func updateAssets(_ media: Media, _ isOnVideoView: Bool) {
        if isOnVideoView {
            for imageView in arrayImageViews {
                imageView.removeFromSuperview()
            }
            arrayImageViews.removeAll()
        } else {
            let viewIndex = self.mediaViews.count - 1 - selectedMediaIndex
            let selectedView = self.mediaViews[viewIndex]
            
            for item in selectedView.subviews {
                if item.tag == -1 {
                    item.removeFromSuperview()
                }
            }
        }
        activeImageView = nil
        
        let resourceURL = Bundle.main.bundleURL.appendingPathComponent("Stickers")
        for image in media.images {
            let path = resourceURL.appendingPathComponent(image.category).appendingPathComponent(image.filename).path
            let uiimage = UIImage(contentsOfFile: path)!
            addImageView(uiimage, isOnVideoView)
            activeImageView?.uuid = image.id
            activeImageView?.bounds = NSCoder.cgRect(for: image.bounds)
            activeImageView?.transform = NSCoder.cgAffineTransform(for: image.transform)
            activeImageView?.center = NSCoder.cgPoint(for: image.center)
            activeImageView?.isActive = false
            activeImageView?.transform = CGAffineTransform(rotationAngle: CGFloat(image.rotation))
            activeImageView = nil
        }
        
        if isOnVideoView {
            for textView in arrayTextViews {
                textView.removeFromSuperview()
            }
            arrayTextViews.removeAll()
        }
        activeTextView = nil
        
        for text in media.texts {
            addTextView(text.text, false, isOnVideoView)
            let _ = self.textView(activeTextView!, shouldChangeText: text.text)
            activeTextView?.bounds = NSCoder.cgRect(for: text.bounds)
            activeTextView?.transform = NSCoder.cgAffineTransform(for: text.transform)
            activeTextView?.center = NSCoder.cgPoint(for: text.center)
            activeTextView?.fontIndex = text.fontIndex
            activeTextView?.setTextFontWithName(TextsView.arrayFonts[text.fontIndex])
            activeTextView?.fontSize = CGFloat(text.fontSize)
            activeTextView?.colorIndex = text.colorIndex
            activeTextView?.textColor = UIColor(hexInt: APP_ARRAY_COLORS[text.colorIndex])
            activeTextView?.textOpacity = CGFloat(text.opacity)
            activeTextView?.isActive = false
            activeTextView?.uuid = text.id
            activeTextView?.transform = CGAffineTransform(rotationAngle: CGFloat(text.rotation))
            activeTextView = nil
        }
        
        timeLabel.isHidden = false
        assetButtonView.isHidden = false
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
    
    fileprivate func frame(contained ratio: CGFloat, parentView: UIView) -> CGRect {
        let imageSize = CGSize(width: 1.0, height: 1.0 / ratio)
        let viewWidth = parentView.frame.width
        let viewHeight = parentView.frame.height
        
        let imageScale = CGFloat(fminf(Float(imageSize.width / viewWidth), Float(imageSize.height / viewHeight)))
        let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
        let frame = CGRect(x: 0.5 * (viewWidth - scaledImageSize.width),
                           y: 0.5 * (viewHeight - scaledImageSize.height),
                           width: scaledImageSize.width,
                           height: scaledImageSize.height);
        
        return frame
    }
    
    fileprivate func showBottomMenu(_ show: Bool) {
        UIView.animate(withDuration: 0.3) {
            if show {
                self.bottomMenuConstraint.constant = 0
            } else {
                self.bottomMenuConstraint.constant = -self.sheetMenuView.frame.height
            }
            self.view.layoutIfNeeded()
        } completion: { (finished) in
            
        }
    }
    
    fileprivate func showOrderMenu(_ show: Bool) {
        if show {
            orderMenuView.removeFromSuperview()
            let contentView = orderMenuView!
            contentView.frame = CGRect(x: 24, y: 0, width: view.frame.width - 48, height: contentView.frame.height)
            popupView = FFPopup(contentView: contentView, showType: .slideInFromBottom, dismissType: .slideOutToBottom, maskType: .dimmed, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
            let layout = FFPopupLayout(horizontal: .center, vertical: .bottom, offset: 10 + view.safeAreaInsets.bottom)
            //popupView.shouldShowClose = true
            popupView.show(layout: layout)
            self.shareButton.isHidden = true
            popupView.didFinishShowingBlock = {
                self.shareButton.isHidden = true
            }
            popupView.didFinishDismissingBlock = {
                self.shareButton.isHidden = false
            }
            popupView.closeButton.frame = CGRect(x: self.view.frame.width - 68, y: self.view.safeAreaInsets.top, width: 64.0, height: 64.0)
            popupView.closeButton.setImage(UIImage(named: "IconClose"), for: .normal)
        } else {
            popupView.dismiss(animated: true)
            shareButton.isHidden = false
        }
    }
    
    fileprivate func updateSeekSlider() {
        seekSlider.maximumValue = Float(ProjectManager.current.duration())
        let range = ProjectManager.current.mediaTime(selectedMediaIndex)
        if seekSlider.value <= Float(range.0) || seekSlider.value >= Float(range.1) {
            seekSlider.value = Float(range.0)
        }
    }
    
    fileprivate func updateOrderView() {
        let orderType = OrderType(rawValue: ProjectManager.current.orderType)!
        switch orderType {
        case .custom:
            topOrderCheckConstraint.constant = 10
        case .shuffle:
            topOrderCheckConstraint.constant = 10 + orderCustomButton.superview!.frame.height
        case .date:
            topOrderCheckConstraint.constant = 10 + orderCustomButton.superview!.frame.height + orderShuffleButton.superview!.frame.height
        }
        
        mediasView.updateOrderView()
    }
    
    @objc fileprivate func handlePauseTrimVideo() {
        trimPlayerView.pause()
        trimPlayView.isHidden = false
    }
    
    @objc fileprivate func handlePreviewPlaying(_ notification: Notification) {
        playButton.isSelected = true
        editButton.isHidden = true
        Medias.frames = []
        Medias.state = 0
    }
    
    @objc fileprivate func handlePreviewStopped(_ notification: Notification) {
        editButton.isHidden = false
        self.currentPlayViewIndex = -1
        
        let itemVideo = self.mediaVideos[0]
        if self.mediaViews[0].tag == 10 {
            itemVideo.pause()
        }
        
        if ProjectManager.current.musics.count > 0 {
            let item = ProjectManager.current.musics.last!
            if item.isFadeout {
                self.audioPlayer?.setVolume(0, fadeDuration: 2)
            } else {
                self.audioPlayer?.stop()
            }
        }
        
        self.playButton.isSelected = false
        
        self.seekTimeSlider(0)
        
    }

    /*
    // MARK: - Navigation
     
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MARK: - UITapGestureRecognizer
    @objc fileprivate func deactivateViews(tapGesture: UITapGestureRecognizer) {
        for textView in arrayTextViews {
            textView.isActive = false
        }
        
        for imageView in arrayImageViews {
            imageView.isActive = false
        }
        
        timeLabel.isHidden = false
        
        if textsView.superview != nil, textsView.isHidden == false {
            didSelectDone(textsView)
        }
        
        textDoneButton.isHidden = true
        shareButton.isHidden = false
    }
    
    @IBAction fileprivate func handlePanGesture(panGesture: UIPanGestureRecognizer) {
        let translation = panGesture.translation(in: videoView)
        let project = ProjectManager.current
        let media = project.medias[selectedMediaIndex]
        let moveTransform = CGAffineTransform.identity.translatedBy(x: translation.x, y: translation.y)
        let transform = NSCoder.cgAffineTransform(for: media.transform).concatenating(moveTransform)
//        thumbImageView.transform = transform.concatenating(NSCoder.cgAffineTransform(for: media.contentTransform))
        panGesture.setTranslation(.zero, in: videoView)
        do {
            try sharedRealm.write {
                media.transform = NSCoder.string(for: transform)
                media.centerX += Float(translation.x)
                media.centerY += Float(translation.y)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @IBAction fileprivate func handlePinchGesture(pinchGesture: UIPinchGestureRecognizer) {
//        let scale = pinchGesture.scale
//        let project = ProjectManager.current
//        let media = project.medias[selectedMediaIndex]
//        let scaleTransform = CGAffineTransform.identity.scaledBy(x: scale, y: scale)
//        let transform = NSCoder.cgAffineTransform(for: media.transform).concatenating(scaleTransform)
//        thumbImageView.transform = transform.concatenating(NSCoder.cgAffineTransform(for: media.contentTransform))
//        pinchGesture.scale = 1.0
//        do {
//            try sharedRealm.write {
//                media.transform = NSCoder.string(for: transform)
//                media.scale *= Float(scale)
//            }
//        } catch {
//            print(error.localizedDescription)
//        }
    }
    
    // MARK: - IBAction
    @IBAction func backButtonPressed(_ sender: UIButton) {
        if editButton.isHidden == true {
            editButton.isHidden = false
            editBoardView.isHidden = true
            lastBottomView?.isHidden = false
            controlsView.isHidden = false
            tabView.isHidden = false
            trimPlayView.isHidden = true
            shareButton.isHidden = false
            trimPlayerView.removeFromSuperview()
            showBoardView(selectedTabItem)
            
            self.addAssets()
            return
        }
        
        if textDoneButton.isHidden == false {
            textDoneButton.isHidden = true
            shareButton.isHidden = false
            if let view = activeTextView {
                let project = ProjectManager.current
                let media = project.medias[selectedMediaIndex]
                let text = media.texts.first { text in
                    return text.id == view.uuid
                }
                
                if text == nil {
                    view.removeFromSuperview()
                    activeTextView = nil
                    textsView.isHidden = true
                } else {
                    didSelectDone(textsView)
                }
            }
            return
        }
        
        let vc = UIAlertController(title: "", message: "Are you sure you want to go back to the main menu?", preferredStyle: .alert)
        vc.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            
            if self.previewController != nil {
                if self.playButton.isSelected {
                    self.previewController.pause()
                    self.audioPlayer?.pause()
                }
            }
            self.navigationController?.popToRootViewController(animated: true)
        }))
        vc.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            
        }))
        present(vc, animated: true, completion: nil)
    }
    
    @IBAction func timelineButtonPressed(_ sender: UIButton) {
        showBottomMenu(true)
    }
    
    @IBAction func editDoneButtonPressed(_ sender: UIButton) {
        editDoneButton.isHidden = true
        shareButton.isHidden = false
        editBoardView.hideAllSubviews()
        editBoardView.doneSubview()
    }
    
    // MARK: - Go to share view controller here | Controller ID ###
    @IBAction func shareButtonPressed(_ sender: UIButton) {
//        self.previewController.stop()
//        self.audioPlayer?.stop()
//        self.seekTimeSlider(0)
        performSegue(withIdentifier: "ShareViewController", sender: nil)
    }
    
    @IBAction func textDoneButtonPressed(_ sender: UIButton) {
        if textsView.superview != nil, textsView.isHidden == false {
            didSelectDone(textsView)
        }
    }
    
    @IBAction func editButtonPressed(_ sender: UIButton) {
        
        updateAssets(ProjectManager.current.medias[selectedMediaIndex], true)
        
        self.viewPlayerView.alpha = 0
        self.viewPlayerRecoverView.alpha = 0
        
        /*let assetView = AssetView.loadFromNib()
        assetView.frame = CGRect(x: 0, y: self.view.frame.height - assetView.frame.height, width: self.view.frame.width, height: assetView.frame.height)
        assetView.delegate = self
        self.view.addSubview(assetView)
        
        assetButtonView.isHidden = true*/
        
        hideAllSubviews()
        self.view.addSubview(editBoardView)
        editBoardView.selectedMediaIndex = selectedMediaIndex
        editButton.isHidden = true
        editBoardView.isHidden = false
        shareButton.isHidden = true
        controlsView.isHidden = true
        tabView.isHidden = true
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        
    }
    
    @IBAction func playButtonPressed() {
        
        if self.playButton.isSelected {
            if self.previewController != nil {
                previewPlayerView.isHidden = true
                previewPlayerView.alpha = 0.0
                self.previewController.pause()
                self.audioPlayer?.pause()
                self.playButton.isSelected = false
                self.editButton.isHidden = false
            }
        } else {
            if self.previewController != nil {
                self.editButton.isHidden = true
                if !self.previewController.isPlaying {
                    previewPlayerView.isHidden = false
                    previewPlayerView.alpha = 1.0
                    self.previewController.play()
                    
                    self.playButton.isSelected = true
                    
                    self.playAudio(true)
                } else {
                    previewPlayerView.isHidden = false
                    previewPlayerView.alpha = 1.0
                    self.previewController.resume()
                    self.audioPlayer?.play()
                    
                    self.playButton.isSelected = true
                }
            }
        }
    }
    
    var mediaViews: [UIView] = []
    
    var mediaVideos: [AVPlayer] = []
    
    var currentProject: SSProject?
    
    var audioPlayer: AVAudioPlayer?
    
    func playAudio(_ isPlay: Bool) {
        if ProjectManager.current.musics.count > 0 || effectView.themeIndex > 0 {
            
            var path = ""
            var volume: Float = 0.5
            var isFadein = true
            let item = ProjectManager.current.musics.last
            if  item == nil  {
                return
            }
            if item?.projectId == "" {
                path = Bundle.main.path(forResource: item!.filename, ofType: "mp3")!
            } else {
                path = Utilities.generateFilePath(filename: item!.filename, projectId: item!.projectId)
            }
            volume = item!.volume
            isFadein = item!.isFadein
            
            let pathUrl = URL.init(fileURLWithPath: path)
            
            do {
                self.audioPlayer = try AVAudioPlayer.init(contentsOf: pathUrl)
                self.audioPlayer?.volume = volume
//                if item.isRepeat {
//                    self.audioPlayer?.numberOfLoops = -1
//                } else {
//                    self.audioPlayer?.numberOfLoops = 1
//                }
                if isFadein {
                    self.audioPlayer?.setVolume(volume, fadeDuration: 2)
                }
            } catch {
                
            }
        } else {
            self.audioPlayer = nil
        }
        
        if isPlay {
            if self.audioPlayer != nil {
                self.audioPlayer!.play()
            }
        }
    }
    
    public func insertMediaView(media: SSProjectImageItem, index: Int) {
//        let media = project.imageItems[index]
        let viewBound = self.getFrameAccordingRatio(self.viewPlayerView.bounds, self.viewPlayerView.center)
        let container = UIView.init(frame: viewBound)
        if media.isVideo {
            let item = AVPlayerItem(url: media.videoUrl)
            let pplayer = AVPlayer(playerItem: item)
            
            let gpuMovie = GPUImageMovie(playerItem: item)
            gpuMovie!.playAtActualSpeed = true
            
            let filteredView: GPUImageView = GPUImageView();
            filteredView.frame = container.frame
            filteredView.clipsToBounds = true
            container.addSubview(filteredView)
            
            if ProjectManager.current.contentType == ContentType.scaleFill.rawValue {
                filteredView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
            } else {
                filteredView.fillMode = kGPUImageFillModePreserveAspectRatio
            }
            if ProjectManager.current.colorIndex >= 0  {
                let color = UIColor(hexInt: APP_ARRAY_COLORS[ProjectManager.current.colorIndex])
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                filteredView.setBackgroundColorRed(GLfloat(red), green: GLfloat(green), blue: GLfloat(blue), alpha: 1)
//                filteredView.backgroundColor = UIColor(hexInt: APP_ARRAY_COLORS[ProjectManager.current.colorIndex])
            } else {
                filteredView.setBackgroundColorRed(0, green: 0, blue: 0, alpha: 1)
//                filteredView.backgroundColor = UIColor.black
            }
            let filter = Utilities.selectFilter(ProjectManager.current.themeIndex)
            
            gpuMovie!.addTarget(filter)
            gpuMovie!.playAtActualSpeed = true
            filter.addTarget(filteredView)
            gpuMovie!.startProcessing()
            container.tag = 10
            
            mediaVideos.insert(pplayer, at: index)
        } else {
            let imageView = UIImageView.init(frame: container.bounds)
            if ProjectManager.current.contentType == ContentType.scaleFill.rawValue {
                imageView.contentMode = .scaleAspectFill
            } else {
                imageView.contentMode = .scaleAspectFit
            }
            imageView.clipsToBounds = true
            if ProjectManager.current.colorIndex >= 0  {
                imageView.backgroundColor = UIColor(hexInt: APP_ARRAY_COLORS[ProjectManager.current.colorIndex])
            } else {
                imageView.backgroundColor = .black
            }
            let filter = Utilities.selectFilter(ProjectManager.current.themeIndex)
            
            let filterImage = filter.image(byFilteringImage: media.rawImage)
            imageView.image = filterImage
            imageView.tag = 1
            container.addSubview(imageView)
            
            mediaVideos.insert(AVPlayer(), at: index)
        }
        container.backgroundColor = UIColor.black
        self.viewPlayerView.insertSubview(container, at: index)
//        self.viewPlayerView.addSubview(container)
        mediaViews.append(container)
        mediaViews.insert(container, at: index)
    }
    
    var __player: AVPlayer! = nil
    
    var __playerItem : AVPlayerItem! = nil
    
    public func tempPlayVideo(_ pathURL: URL) {
        
        __player = AVPlayer()
        
        __playerItem = AVPlayerItem(url: pathURL)
        __player = AVPlayer.init(playerItem: __playerItem)
        
        let gpuMovie = GPUImageMovie(playerItem: __playerItem)
        gpuMovie!.playAtActualSpeed = true
        
        let filteredView: GPUImageView = GPUImageView();
        filteredView.frame = self.editView.frame
        self.editView.addSubview(filteredView)
        
        if ProjectManager.current.contentType == ContentType.scaleFill.rawValue {
            filteredView.contentMode = .scaleAspectFill
        } else {
            filteredView.contentMode = .scaleAspectFit
        }
        
        let filter = GPUImageSepiaFilter()
        
        gpuMovie!.addTarget(filter)
        gpuMovie!.playAtActualSpeed = true
        filter.addTarget(filteredView)

        gpuMovie!.startProcessing()
        __player.play()
        
    }
    
    func seekToFirstPoint() {
        if self.playButton.isSelected {
            playButtonPressed()
        }
        self.seekSlider.value = 0
        self.seekSliderChanged(self.seekSlider)
    }
    
    public func playButtonPressed1(_ project: SSProject) {
        
        if (self.previewController != nil) {
            self.seekToFirstPoint()
        }
        
        for item in self.mediaViews {
            item.removeFromSuperview()
        }
        self.mediaViews.removeAll()
        self.mediaVideos.removeAll()
        self.currentProject = project
        let settings = SSProjectSettings()
        project.settings = settings
        self.previewController = nil
        self.previewController = SSPlayerController(player: self.previewPlayerView, andProject: project)
        self.previewController.editViewCtrl = self
        var index = project.imageItems.count
        let viewBound = self.getFrameAccordingRatio(self.viewPlayerView.bounds, self.viewPlayerView.center)
        Utilities.windowView(self.viewPlayerRecoverView, viewBound)
        index = index - 1
        while index > -1 {
            let media = project.imageItems[index]
            let container = UIView.init(frame: viewBound)
            if media.isVideo {
                let item = AVPlayerItem(url: media.videoUrl)
                let pplayer = AVPlayer(playerItem: item)
                
                let gpuMovie = GPUImageMovie(playerItem: item)
                gpuMovie!.playAtActualSpeed = true
                
                let filteredView: GPUImageView = GPUImageView()
                filteredView.frame = CGRect.init(x: 0, y: 0, width: viewBound.width, height: viewBound.height)
                filteredView.clipsToBounds = true
                container.addSubview(filteredView)
                
                if ProjectManager.current.contentType == ContentType.scaleFill.rawValue {
                    filteredView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
                } else {
                    filteredView.fillMode = kGPUImageFillModePreserveAspectRatio
                }
                
                let filter = Utilities.getFilter(project.imageItems.count - 1 - index, themeNumber: ProjectManager.current.themeIndex)
//                Utilities.selectFilter(ProjectManager.current.themeIndex)
                
                if ProjectManager.current.colorIndex >= 0  {
                    let color = UIColor(hexInt: APP_ARRAY_COLORS[ProjectManager.current.colorIndex])
                    var red: CGFloat = 0
                    var green: CGFloat = 0
                    var blue: CGFloat = 0
                    var alpha: CGFloat = 0
                    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                    filteredView.setBackgroundColorRed(GLfloat(red), green: GLfloat(green), blue: GLfloat(blue), alpha: 1)
                } else {
                    filteredView.setBackgroundColorRed(0, green: 0, blue: 0, alpha: 1)
                }
                
                gpuMovie!.addTarget(filter)
                gpuMovie!.playAtActualSpeed = true
                filter.addTarget(filteredView)
                gpuMovie!.startProcessing()
                
                container.tag = 10
                
                mediaVideos.append(pplayer)
            } else {
                let imageView = UIImageView.init(frame: container.bounds)
                if ProjectManager.current.contentType == ContentType.scaleFill.rawValue {
                    imageView.contentMode = .scaleAspectFill
                } else {
                    imageView.contentMode = .scaleAspectFit
                }
                imageView.clipsToBounds = true
                if ProjectManager.current.colorIndex >= 0  {
                    imageView.backgroundColor = UIColor(hexInt: APP_ARRAY_COLORS[ProjectManager.current.colorIndex])
                } else {
                    imageView.backgroundColor = .black
                }
                let filter = Utilities.getFilter(project.imageItems.count - 1 - index, themeNumber: ProjectManager.current.themeIndex)
//                Utilities.selectFilter(ProjectManager.current.themeIndex)
                
                let filterImage = filter.image(byFilteringImage: media.rawImage)
                imageView.image = filterImage
                imageView.tag = 1
                container.addSubview(imageView)
                                
                mediaVideos.append(AVPlayer())
            }
            container.backgroundColor = UIColor.black
            self.viewPlayerView.addSubview(container)
            mediaViews.append(container)
            
            index = index - 1
            
        }
        
        self.addAssets()
        
        playButtonPressed()
        playButtonPressed()
        
        SVProgressHUD.dismiss()
        
        self.seekSliderChanged(self.seekSlider)
    }
    
    func addAssets() {
        let temp = selectedMediaIndex
        let project = ProjectManager.current
        
        var index = project.medias.count - 1
        while index > -1 {
            selectedMediaIndex = index
            let media = project.medias[index]
            updateAssets(media, false)
            index = index - 1
        }
        selectedMediaIndex = temp
    }
    
    func getFrameAccordingRatio(_ bound: CGRect, _ center: CGPoint) -> CGRect {
        var width: CGFloat = bound.size.width
        var height: CGFloat = bound.size.height
        
        switch ProjectManager.current.ratio {
        case RatioType.original.rawValue:    // 4:3
            height = width * 0.75
            height = bound.size.height < height ? bound.size.height : height
            break
            
        case RatioType.portrait.rawValue:    // 9:16
            width = height * 0.75 * 0.75
            width = bound.size.width < width ? bound.size.width : width
            break
            
        case RatioType.landscape.rawValue:   // 16:9
            height = width * 0.75 * 0.75
            height = bound.size.height < height ? bound.size.height : height
            break
            
        case RatioType.square.rawValue:      // 1:1
            width = width > height ? height : width
            height = width
            break
            
        default:
            break
        }
        
        return CGRect.init(x: center.x - width / 2, y: center.y - height / 2, width: width, height: height)
    }
    
    @IBAction func seekSliderChanged(_ sender: UISlider) {
        self.viewPlayerView.alpha = 1
        self.viewPlayerRecoverView.alpha = 1
        
        if (self.audioPlayer != nil) {
            var timeSeek = TimeInterval(sender.value)
            while timeSeek > self.audioPlayer!.duration {
                timeSeek = timeSeek - self.audioPlayer!.duration
            }
            self.audioPlayer!.currentTime = timeSeek
        }
        
        if self.previewController != nil {
            previewController.jump(TimeInterval(sender.value))
        }
    }
    
    @IBAction func seekSliderChangedUp(_ sender: UISlider) {
//        previewController.jump(TimeInterval(sender.value))
    }
    
    @IBAction func tabButtonPressed(_ sender: UIButton) {
        let tabItem = TabItem(rawValue: sender.superview!.tag)!
        if tabItem == .music {
            /*if PurchaseManager.sharedManager.isPurchased(productId: UNLOCK_MUSIC) == false {
                if UserDefaults.standard.bool(forKey: kAppiraterRatedCurrentVersion) == false {
                    let controller = UIAlertController(title: "Rating Us", message: "If you are enjoying the app, would you mind leaving some feedback?", preferredStyle: .alert)
                    controller.addAction(UIAlertAction(title: "Sure", style: .cancel, handler: { action in
                        Appirater.setAppId("1046183199")
                        Appirater.rateApp()
                    }))
                    controller.addAction(UIAlertAction(title: "Not Now", style: .default, handler: { (action) in
                        //PurchaseView.show().parentViewController = self
                    }))
                    self.present(controller, animated: true, completion: nil)
                    return
                }
            }*/
        }
        
        selectedTabItem = tabItem
        selectTabItem(tabItem)
        showBoardView(tabItem)
    }
    
    @IBAction func handleBlurViewTapGesture(_ sender: UITapGestureRecognizer) {
        showBottomMenu(false)
        showOrderMenu(false)
    }
    
    @IBAction func undoButtonPressed(_ sender: UIButton) {
        
    }
    
    @IBAction func redoButtonPressed(_ sender: UIButton) {
        
    }
        
    @IBAction func revertButtonPressed(_ sender: UIButton) {
        
    }
    
    @IBAction func previewEndButtonPressed(_ sender: UIButton) {
        previewEndButton.isHidden = true
        
        seekSlider.value = prevSeekValue
        
        selectedMediaIndex = lastSelectedIndex
        didSelectMedia(selectedMediaIndex)
        mediasView.selectedIndex = selectedMediaIndex
        updateTimeLabel()
    }
    
    @IBAction func didSelectText(_ sender: UIButton?) {
        addTextView("", true, true)
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 360 : 558
        let frame = CGRect(x: 0, y: self.view.frame.height - height, width: self.view.frame.width, height: height)
        textsView.frame = frame
        textsView.textView = activeTextView!
        self.view.addSubview(textsView)
    }
    
    @IBAction func orderCustomPressed(_ sender: UIButton) {
        do {
            try sharedRealm.write {
                ProjectManager.current.orderType = OrderType.custom.rawValue
            }
        } catch {
            print(error.localizedDescription)
        }
        updateOrderView()
    }
    
    @IBAction func orderShufflePressed(_ sender: UIButton) {
        do {
            try sharedRealm.write {
                ProjectManager.current.orderType = OrderType.shuffle.rawValue
                let medias = List<Media>()
                let shuffled = ProjectManager.current.medias.shuffled()
                for media in shuffled {
                    medias.append(media)
                }
                ProjectManager.current.medias = medias
            }
        } catch {
            print(error.localizedDescription)
        }
        mediasView.reloadData()
        updateOrderView()
    }
    
    @IBAction func orderDatePressed(_ sender: UIButton) {
        do {
            try sharedRealm.write {
                ProjectManager.current.orderType = OrderType.date.rawValue
                let medias = List<Media>()
                let sorted = ProjectManager.current.medias.sorted(by: { media1, media2 in
                    return media1.creationDate < media2.creationDate
                })
                for media in sorted {
                    medias.append(media)
                }
                ProjectManager.current.medias = medias
            }
        } catch {
            print(error.localizedDescription)
        }
        mediasView.reloadData()
        updateOrderView()
        self.loadProject()
    }
    
    @IBAction func orderClosePressed(_ sender: UIButton) {
        popupView.dismiss(animated: true)
        shareButton.isHidden = false
    }
    
    @IBAction func trimPlayPressed(_ sender: UIButton) {
        if trimPlayerView.isPlaying {
            trimPlayButton.isSelected = false
            trimPlayView.isHidden = false
            trimPlayerView.pause()
        } else {
            trimPlayButton.isSelected = true
            trimPlayView.isHidden = true
            trimPlayerView.play()
        }
    }
}

// MARK: - ArrangeViewDelegate
extension EditViewController: RPPreviewViewControllerDelegate  {
    func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
            dismiss(animated: true)
        }
}

extension EditViewController: MusicEditViewDelegate {
    func didChangeValue() {
        
        let item = ProjectManager.current.musics.last!
        
        self.audioPlayer?.volume = item.volume
        if item.isRepeat {
            self.audioPlayer?.numberOfLoops = -1
        } else {
            self.audioPlayer?.numberOfLoops = 1
        }
    }
}

// MARK: - ArrangeViewDelegate
extension EditViewController: ArrangeViewDelegate {
    func didChangeColor(_ index: Int) {
        self.seekToFirstPoint()
        do {  
            try sharedRealm.write {
                ProjectManager.current.colorIndex = index
            }
        } catch {
            print(error.localizedDescription)
        }
        
        changeBackgroundAndType(true)
        
        if index >= 0 {
            blurImageView.isHidden = true
            videoView.backgroundColor = UIColor(hexInt: APP_ARRAY_COLORS[index])
        } else {
            blurImageView.isHidden = false
        }
    }
    
    func changeBackgroundAndType(_ isColorChange: Bool) {
        for mediaView in mediaViews {
            if mediaView.tag == 10 {
                let imageView = mediaView.subviews.first as! GPUImageView
                if isColorChange {
                    if ProjectManager.current.colorIndex < 0 {
                        imageView.setBackgroundColorRed(0, green: 0, blue: 0, alpha: 1)
                    } else {
                        let color = UIColor(hexInt: APP_ARRAY_COLORS[ProjectManager.current.colorIndex])
                        var red: CGFloat = 0
                        var green: CGFloat = 0
                        var blue: CGFloat = 0
                        var alpha: CGFloat = 0
                        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                        imageView.setBackgroundColorRed(GLfloat(red), green: GLfloat(green), blue: GLfloat(blue), alpha: 1)
//                        imageView.backgroundColor = UIColor(hexInt: APP_ARRAY_COLORS[ProjectManager.current.colorIndex])
                    }
                } else {
                    if ProjectManager.current.contentType == ContentType.scaleFill.rawValue {
                        imageView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill
                    } else {
                        imageView.fillMode = kGPUImageFillModePreserveAspectRatio
                    }
                }
                imageView.setNeedsDisplay()
            } else {
                let imageView = mediaView.subviews.first as! UIImageView
                if isColorChange {
                    if ProjectManager.current.colorIndex < 0 {
                        imageView.backgroundColor = .black
                    } else {
                        imageView.backgroundColor = UIColor(hexInt: APP_ARRAY_COLORS[ProjectManager.current.colorIndex])
                    }
                } else {
                    if ProjectManager.current.contentType == ContentType.scaleFill.rawValue {
                        imageView.contentMode = .scaleAspectFill
                    } else {
                        imageView.contentMode = .scaleAspectFit
                    }
                    imageView.setNeedsDisplay()
                }
            }
        }
//        self.seekSlider.value = self.seekSlider.value + 0.5
//        self.seekSliderChanged(self.seekSlider)
//
//        self.seekSlider.value = self.seekSlider.value - 0.5
//        self.seekSliderChanged(self.seekSlider)
//        self.playButtonPressed()
//        self.playButtonPressed()
    }
    
    func didChangeContentType(_ type: ContentType) {
        
        self.seekToFirstPoint()
        do {
            try sharedRealm.write {
                ProjectManager.current.contentType = type.rawValue
            }
        } catch {
            print(error.localizedDescription)
        }
        
        changeBackgroundAndType(false)
        
        let project = ProjectManager.current
        let media = project.medias[selectedMediaIndex]
        let imageSize = thumbImageView.image!.size
        if type == .scaleFill {
            var imageScale = CGFloat(fminf(Float(imageSize.width / videoView.frame.width), Float(imageSize.height / videoView.frame.height)))
            let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
            imageScale = fmax(scaledImageSize.width / videoView.frame.width, scaledImageSize.height / videoView.frame.height)
            do {		
                try sharedRealm.write {
                    media.contentTransform = NSCoder.string(for: CGAffineTransform.identity.scaledBy(x: imageScale, y: imageScale))
                    thumbImageView.transform = NSCoder.cgAffineTransform(for: media.contentTransform)
//                    NSCoder.cgAffineTransform(for: media.transform).concatenating(NSCoder.cgAffineTransform(for: media.contentTransform))
                }
            } catch {
                
            }
        } else {
            var imageScale = CGFloat(fmaxf(Float(imageSize.width / videoView.frame.width), Float(imageSize.height / videoView.frame.height)))
            let scaledImageSize = CGSize(width: imageSize.width / imageScale, height: imageSize.height / imageScale)
            imageScale = fmax(scaledImageSize.width / videoView.frame.width, scaledImageSize.height / videoView.frame.height)
            do {
                try sharedRealm.write {
                    media.contentTransform = NSCoder.string(for: CGAffineTransform.identity.scaledBy(x: imageScale, y: imageScale))
                    thumbImageView.transform = NSCoder.cgAffineTransform(for: media.contentTransform)
//                    NSCoder.cgAffineTransform(for: media.transform).concatenating(NSCoder.cgAffineTransform(for: media.contentTransform))
                }
            } catch {
                
            }
        }
    }
    
    func didTapRatio() {
        self.seekToFirstPoint()
        arrangeView.isHidden = true
        tabView.isHidden = true
        let ratiosView = RatiosView.loadFromNib()
        ratiosView.delegate = self
        self.view.addSubview(ratiosView)
        let height = self.view.frame.height - controlsView.frame.maxY + controlsView.frame.height - playsView.frame.maxY
        ratiosView.frame = CGRect(x: 0, y: self.view.frame.height - height, width: self.view.frame.width, height: height)
    }
}

// MARK: - RatiosViewDelegate
extension EditViewController: RatiosViewDelegate {
    func didSelectRatio(_ ratio: RatioType?) {
        arrangeView.isHidden = false
        tabView.isHidden = false
        if let ratio = ratio {
            do {
                try sharedRealm.write {
                    ProjectManager.current.ratio = ratio.rawValue
                    arrangeView.project = ProjectManager.current
                }
                updateVideoView()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

// MARK: - EditViewDelegate
extension EditViewController: EditViewDelegate {
    
    func reloadMedias() {
        
        self.playButtonPressed1(self.currentProject!)
        self.loadProject()
        
        self.didSelectMedia(self.mediasView.selectedIndex)
        
        self.seekSlider.value = 0
        self.seekSliderChanged(self.seekSlider)
    }
    func didTapNew(_ view: EditView, _ index: Int) {
        if !PurchaseManager.sharedManager.isPurchased() && Int(ProjectManager.current.medias.count) >= 5 {
            PurchaseView.show().parentViewController = self
            return;
        }
        
        insertMediaIndex = index
//        let controller = UIImagePickerController()
//        controller.mediaTypes = [kUTTypeMovie as String, kUTTypeImage as String]
//        controller.sourceType = .photoLibrary
//        controller.delegate = self
//        present(controller, animated: true, completion: nil)
        
//        var config = PHPickerConfiguration()
//        config.selectionLimit = 0
//        config.filter = .any(of: [.videos, .images])
//        let pickerViewController = PHPickerViewController(configuration: config)
//        pickerViewController.delegate = self
//        targetInsertMediaCount = 10
//        self.present(pickerViewController, animated: true, completion: nil)
        
        let storyboard = UIStoryboard(name: "Edit", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "MediasViewController1") as! MediasViewController1
        vc.editViewCtrl = self
        vc.modalPresentationStyle = .fullScreen
        self.present(vc, animated: true)
    }
    
    func didSelectMedia(_ index: Int) {
        if selectedMediaIndex == index || self.playButton.isSelected {
            return
        }
        
        selectedMediaIndex = index
        effectView.media = ProjectManager.current.medias[selectedMediaIndex]
        
        updateVideoView()
        updateSeekSlider()
        
        self.seekSliderChanged(self.seekSlider)
    }
    
    func didTrashMedia(_ index: Int) {
        let project = ProjectManager.current
        do {
            try sharedRealm.write {
                project.medias[index].deleteFile()
                project.medias.remove(at: index)
            }
            if selectedMediaIndex >= index {
                selectedMediaIndex -= 1
                if selectedMediaIndex < 0 {
                    selectedMediaIndex = 0
                }
                if selectedMediaIndex >= project.medias.count {
                    selectedMediaIndex = project.medias.count - 1
                }
                mediasView.selectedIndex = selectedMediaIndex
//                updateVideoView()
            }
            mediasView.project = project
//            updateVideoView()
            updateSeekSlider()
            updateTimeLabel()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func didTapOrder(_ view: EditView) {
        showOrderMenu(true)
    }
    
    func didStartDrag(_ view: EditView) {
        if self.playButton.isSelected {
            playButtonPressed()
        }
        tabView.isHidden = true
    }
    
    func didEndDrag(_ view: EditView) {
        tabView.isHidden = false
        
        self.reloadMedias()
    }
}

// MARK: - TimeViewDelegate
extension EditViewController: TimeViewDelegate {
    func didChangeImageDuration(_ time: CGFloat) {
        
        self.seekToFirstPoint()
        do {
            try sharedRealm.write {
                ProjectManager.current.imageDuration = Float(time)
            }
        } catch {
            print(error.localizedDescription)
        }
        self.currentProject?.imageDuration = TimeInterval(time)
        self.currentProject?.settings.fixedPhotoDuration = TimeInterval(time)
        
        self.currentProject?.calculateDurations()
        seekSlider.minimumValue = 0
        updateSeekSlider()
        updateTimeLabel()
    }
}

var targetInsertMediaCount: Int = 0

// MARK: - UIImagePickerControllerDelegate
extension EditViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        
        if targetInsertMediaCount == 0 {
            return
        }
        targetInsertMediaCount = 0
        picker.dismiss(animated: true, completion: nil)
        
        for result in results {
//           UTType.movie.identifier
           if result.itemProvider.hasItemConformingToTypeIdentifier("public.movie") { //"com.apple.quicktime-movie"
               
               result.itemProvider.loadItem(forTypeIdentifier: "public.movie", options: nil) { [weak self] (videoURL1, error) in
//               result.itemProvider.loadFileRepresentation(forTypeIdentifier: "com.apple.quicktime-movie") { videoURL1, error in
                   
                   DispatchQueue.main.async {
                       
                       if let videoURL = videoURL1  as? URL {
//                           self.display(videoWithURL: videoURL1!)
                           
                           if true {
                               let project = ProjectManager.current
                               let filename = Utilities.generateRandomFileName(fileExtension: "mov")
                               let path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                               SVProgressHUD.show()
                               VideoService.saveVideo(AVURLAsset(url: videoURL), path: path) { success, error in
                                   SVProgressHUD.dismiss()
                                   if error == nil {
                                       do {
                                           try sharedRealm.write {
                                               let media = Media()
                                               media.filename = filename
                                               media.blurname = filename
                                               media.localIdentifier = "\(Date().timeIntervalSince1970)"
                                               media.projectId = project.id
                                               media.type = MediaType.video.rawValue
                                               media.effectType = EffectType.none.rawValue
                                               project.medias.insert(media, at: self!.insertMediaIndex)
                                               self?.mediasView.project = project
                                           }
                                       } catch {
                                           print(error.localizedDescription)
                                       }
                                       
                                       self?.updateSeekSlider()
                                       self?.updateTimeLabel()
                                   }
                                   
                                   targetInsertMediaCount = targetInsertMediaCount + 1
                                   if targetInsertMediaCount == results.count {
                                       self?.loadProject()
                                   }
                               }
                           }
                       }
                   }
               }
           } else {
               result.itemProvider.loadObject(ofClass: UIImage.self, completionHandler: { [self] (object, error) in
                   
                  if var image = object as? UIImage {
                      image = image.fixedOrientation()
                      
                      let project = ProjectManager.current
                      DispatchQueue.main.async {
                          // Use UIImage
                          
                          do {
                             let filename = Utilities.generateRandomFileName(fileExtension: "png")
                             let path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                              
//                              let size = CGSize(width: image.size.width / 1.4, height: image.size.height / 1.4 )
//                              try? image.resizedImage(to: size).pngData()!.write(to: URL(fileURLWithPath: path))
                             try? image.pngData()!.write(to: URL(fileURLWithPath: path))
                              
                              try sharedRealm.write {
                                 let media = Media()
                                 media.filename = filename
                                 media.blurname = filename
                                 media.localIdentifier = "\(Date().timeIntervalSince1970)"
//                                 result.assetIdentifier!
   //                              asset.localIdentifier
                                 media.projectId = project.id
                                 media.type = MediaType.image.rawValue
                                 media.effectType = EffectType.none.rawValue
                                 project.medias.insert(media, at: self.insertMediaIndex)
                                 self.mediasView.project = project
                             }
                          } catch {
                              print(error.localizedDescription)
                          }
                          self.updateSeekSlider()
                          self.updateTimeLabel()
                          
                          targetInsertMediaCount = targetInsertMediaCount + 1
                          if targetInsertMediaCount == results.count {
                              self.loadProject()
                          }
                     }
                  } else {
                      targetInsertMediaCount = targetInsertMediaCount + 1
                      if targetInsertMediaCount == results.count {
                          self.loadProject()
                      }
                  }
               })
           }
       }
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        if let asset = info[UIImagePickerController.InfoKey.phAsset] as? PHAsset {
            if var image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
                image = image.fixedOrientation()
                let project = ProjectManager.current
                let duration = project.duration(nil) + CGFloat(project.imageDuration)
                if duration > DEFAULT_EXPORT_DURATION, PurchaseManager.sharedManager.isPurchased() == false {
                    PurchaseView.show().parentViewController = self
                    return
                }
                
                do {
                    let filename = Utilities.generateRandomFileName(fileExtension: "png")
                    var path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                    try? image.pngData()!.write(to: URL(fileURLWithPath: path))
                    let blur = image.blurImage()
                    let blurname = Utilities.generateRandomFileName(fileExtension: "png")
                    path = Utilities.generateFilePath(filename: blurname, projectId: project.id)
                    try? blur.pngData()!.write(to: URL(fileURLWithPath: path))
                    try sharedRealm.write {
                        let media = Media()
                        media.filename = filename
                        media.blurname = blurname
                        media.localIdentifier = asset.localIdentifier
                        media.projectId = project.id
                        media.type = MediaType.image.rawValue
                        media.effectType = EffectType.none.rawValue
                        project.medias.insert(media, at: insertMediaIndex)
                        mediasView.project = project
                    }
                    updateSeekSlider()
                    updateTimeLabel()
                    
                    self.loadProject()
                } catch {
                    print(error.localizedDescription)
                }
            } else if let videoURL = info[UIImagePickerController.InfoKey.mediaURL] as? URL {
                                
                let project = ProjectManager.current
                let duration = project.duration(nil) + CGFloat(project.imageDuration)
                if duration > DEFAULT_EXPORT_DURATION, PurchaseManager.sharedManager.isPurchased() == false {
                    //PurchaseView.show().parentViewController = self
                    return
                }
                let filename = Utilities.generateRandomFileName(fileExtension: "mov")
                let path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                SVProgressHUD.show()
                VideoService.saveVideo(AVURLAsset(url: videoURL), path: path) { success, error in
                    let blurname = Utilities.generateRandomFileName(fileExtension: "mov")
                    let blurpath = Utilities.generateFilePath(filename: blurname, projectId: project.id)
                    let videoAsset = AVURLAsset(url: URL(fileURLWithPath: path))
                    VideoService.shared().blurVideo(videoAsset, path: blurpath) { success in
                        SVProgressHUD.dismiss()
                        do {
                            try sharedRealm.write {
                                let media = Media()
                                media.filename = filename
                                media.blurname = blurname
                                media.localIdentifier = asset.localIdentifier
                                media.projectId = project.id
                                media.type = MediaType.video.rawValue
                                media.effectType = EffectType.none.rawValue
                                project.medias.insert(media, at: self.insertMediaIndex)
                                self.mediasView.project = project
                            }
                            self.updateSeekSlider()
                            self.updateTimeLabel()
                            
                            self.loadProject()
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
        }
        //let mediaType = info[UIImagePickerController.InfoKey.mediaType]
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func addSeledtedAssets(_ assets: [MediaAsset]) {
        targetInsertMediaCount = 0
        let project = ProjectManager.current
        if selectedAssets.count == 0 {
            return
        }
        SVProgressHUD.setBackgroundColor(.clear)
        SVProgressHUD.show()
        
        for index in 0..<selectedAssets.count {
            let asset = selectedAssets[index]
            if asset.asset.mediaType == .image {
                let filename = Utilities.generateRandomFileName(fileExtension: "png")
                let path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                PHImageManager.default().requestImage(for: asset.asset, targetSize: CGSize(width: asset.asset.pixelWidth, height: asset.asset.pixelHeight), contentMode: .aspectFill, options: options) { image, option in
//                    DispatchQueue.main.async {
                        if let image = image {
                            try? image.pngData()!.write(to: URL(fileURLWithPath: path))
                            do {
                                 try sharedRealm.write {
                                     let media = Media()
                                     media.filename = filename
                                     media.blurname = filename
                                     media.localIdentifier = "\(Date().timeIntervalSince1970)"
                                     media.projectId = project.id
                                     media.type = MediaType.image.rawValue
                                     media.effectType = EffectType.none.rawValue
                                     project.medias.insert(media, at: self.insertMediaIndex)
                                     self.mediasView.project = project
                                     
                                     self.currentProject!.insert(media.renderImage(), insertNum: Int32(self.insertMediaIndex))
//                                     self.currentProject!.add(media.renderImage())
                                 }
                              } catch {
                                  print(error.localizedDescription)
                              }
                              self.updateSeekSlider()
                              self.updateTimeLabel()
                        }
                        targetInsertMediaCount = targetInsertMediaCount + 1
                        if targetInsertMediaCount == self.selectedAssets.count {
                            SVProgressHUD.dismiss()
                            self.playButtonPressed1(self.currentProject!)
                        }
                }
            } else if asset.asset.mediaType == .video {
                let filename = Utilities.generateRandomFileName(fileExtension: "mov")
                let path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .fastFormat //.highQualityFormat
                PHImageManager.default().requestAVAsset(forVideo: asset.asset, options: options) { video, audioMix, option in
                    if let video = video {
                        VideoService.saveVideo(video, path: path) { success, error in
                            if success {
                                do {
                                   try sharedRealm.write {
                                       let media = Media()
                                       media.filename = filename
                                       media.blurname = filename
                                       media.localIdentifier = "\(Date().timeIntervalSince1970)"
                                       media.projectId = project.id
                                       media.type = MediaType.video.rawValue
                                       media.effectType = EffectType.none.rawValue
                                       project.medias.insert(media, at: self.insertMediaIndex)
                                       self.mediasView.project = project
                                       
                                       let asset = video
                                       let videoDuration = asset.duration
                                       let generator = AVAssetImageGenerator(asset: asset)
                                       generator.appliesPreferredTrackTransform = true
                                       
//                                       let frame = VideoService().getFrame(asset)
                                       let frame = UIImage.init(named: "AppIcon")
                                       self.currentProject!.insertVideo(media.renderVideo(_frameImage: frame!), insertNum:Int32(self.insertMediaIndex), url: URL(fileURLWithPath: path), duration:videoDuration, generator: generator, lastImg: media.renderVideo(_frameImage: frame!))
                                   }
                               } catch {
                                   print(error.localizedDescription)
                               }
                                
                                self.updateSeekSlider()
                               self.updateTimeLabel()
                            }
                            
                            targetInsertMediaCount = targetInsertMediaCount + 1
                            if targetInsertMediaCount == self.selectedAssets.count {
                                SVProgressHUD.dismiss()
                                self.playButtonPressed1(self.currentProject!)
                           }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - ArtsViewDelegate
extension EditViewController: ArtsViewDelegate {
    func didSelectArt(_ category: String, _ filename: String, _ artImage: UIImage) {
        if let imageView = activeImageView, imageView.isActive {
            imageView.setImage(artImage)
        } else {
            addImageView(artImage, true)
        }

        let project = ProjectManager.current
        let media = project.medias[selectedMediaIndex]
        do {
            try sharedRealm.write {
                let image = Image()
                image.category = category
                image.filename = filename
                image.bounds = NSCoder.string(for: activeImageView!.bounds)
                image.transform = NSCoder.string(for: activeImageView!.transform)
                image.center = NSCoder.string(for: activeImageView!.center)
                image.zIndex = Int(activeImageView!.layer.zPosition)
                image.order = media.images.count + media.texts.count
                image.rotation = Float(activeImageView!.rotation)
                media.images.append(image)
                activeImageView?.uuid = image.id
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func didSelectClose(_ view: ArtsView) {
        assetButtonView.isHidden = false
        controlsView.isHidden = false
    }
    
    func addImageView(_ image: UIImage,_ isOnVideoView: Bool) {
        let imageView = TVImageView()
        
        let videoFrame = videoView.frame
        var frameSize = TVImageView.frameSize(with: image, maxSize: videoFrame.size)
        frameSize.width /= 2.0
        frameSize.height /= 2.0
        imageView.frame = CGRect(x: 0.5 * (videoFrame.size.width - frameSize.width), y: 0.5 * (videoFrame.size.height - frameSize.height), width: frameSize.width, height: frameSize.height)
        
        imageView.setImage(image)
        imageView.setOriginImage(image)
        imageView.isActive = true
        
        imageView.delegate = self
        activeImageView = imageView
        
        if isOnVideoView {
            
            let pan = UIPanGestureRecognizer(target: self, action: #selector(moveView(gesture:)))
            pan.minimumNumberOfTouches = 1
            pan.maximumNumberOfTouches = 2
            imageView.addGestureRecognizer(pan)
            
            videoView.addSubview(imageView)
            
            arrayImageViews.append(imageView)
        } else {
            imageView.tag = -1
            let viewIndex = self.mediaViews.count - 1 - selectedMediaIndex
            let selectedView = self.mediaViews[viewIndex]
            selectedView.addSubview(imageView)
        }
    }
    
    @objc func moveView(gesture: UIPanGestureRecognizer) {
        if !self.editButton.isHidden {
            return
        }
        if (gesture.view == activeTextView && activeTextView?.isActive == true) ||
            (gesture.view == activeImageView && activeImageView?.isActive == true)
        {
            let translatedPoint = gesture.location(in: self.view)
            
            if gesture.state == .began {
                previousPoint = translatedPoint
            }
            
            let dX = translatedPoint.x - previousPoint.x
            let dY = translatedPoint.y - previousPoint.y
            
            previousPoint = translatedPoint;
            
            var viewCenter = gesture.view!.center
            viewCenter.x += dX
            viewCenter.y += dY
            
            gesture.view!.center = viewCenter
            
            if gesture.state != .began, gesture.state != .changed {
                let project = ProjectManager.current
                let media = project.medias[selectedMediaIndex]
                if let textView = gesture.view as? TVTextView, let text = media.texts.first(where: { text in
                    return textView.uuid == text.id
                }) {
                    do {
                        try sharedRealm.write {
                            text.bounds = NSCoder.string(for: textView.bounds)
                            text.center = NSCoder.string(for: textView.center)
                            text.rotation = Float(textView.rotation)
                        }
                    } catch {
                        
                    }
                } else if let imageView = gesture.view as? TVImageView, let image = media.images.first(where: { image in
                    return imageView.uuid == image.id
                }) {
                    do {
                        try sharedRealm.write {
                            image.bounds = NSCoder.string(for: imageView.bounds)
                            image.center = NSCoder.string(for: imageView.center)
                            image.rotation = Float(imageView.rotation)
                        }
                    } catch {
                        
                    }
                }
            }
        }
    }
}

// MARK: - AssetViewDelegate
extension EditViewController: AssetViewDelegate {
    func didSelectArt(_ view: AssetView) {
        
    }
    
    func didSelectText(_ view: AssetView) {
        //assetButtonView.isHidden = false
        //controlsView.isHidden = false
        addTextView("", true, true)
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 360 : 558
        let frame = CGRect(x: 0, y: self.view.frame.height - height, width: self.view.frame.width, height: height)
        textsView.frame = frame
        textsView.textView = activeTextView!
        self.view.addSubview(textsView)
    }
    
    func didSelectGif(_ view: AssetView) {
        assetButtonView.isHidden = false
        controlsView.isHidden = false
    }
    
    func didSelectBack(_ view: AssetView) {
        assetButtonView.isHidden = false
        controlsView.isHidden = false
    }
}

// MARK: - TextsViewDelegate
extension EditViewController: TextsViewDelegate {
    func didSelectDone(_ view: TextsView) {
        assetButtonView.isHidden = false
        controlsView.isHidden = false
        timeLabel.isHidden = false
        textDoneButton.isHidden = true
        shareButton.isHidden = false
        view.isHidden = true
        
        let textView = view.textView!
        textView.isActive = false
        let media = ProjectManager.current.medias[selectedMediaIndex]
        if let uuid = textView.uuid, uuid != "", let text = media.texts.first(where: { text in
            return text.id == uuid
        }) {
            do {
                try sharedRealm.write {
                    text.text = view.text.text
                    text.fontIndex = textView.fontIndex
                    text.fontSize = Float(textView.fontSize)
                    text.colorIndex = textView.colorIndex
                    text.bounds = NSCoder.string(for: textView.bounds)
                    text.transform = NSCoder.string(for: textView.transform)
                    text.center = NSCoder.string(for: textView.center)
                    text.opacity = Float(textView.textOpacity)
                    text.hspacing = Float(textView.hSpacing)
                    text.vspacing = Float(textView.vSpacing)
                    text.rotation = Float(textView.rotation)
                }
            } catch {
                print(error.localizedDescription)
            }
        } else {
            do {
                try sharedRealm.write {
                    let text = Text()
                    text.text = view.textView.getText()
                    text.fontIndex = textView.fontIndex
                    text.fontSize = Float(textView.fontSize)
                    text.colorIndex = textView.colorIndex
                    text.bounds = NSCoder.string(for: textView.bounds)
                    text.transform = NSCoder.string(for: textView.transform)
                    text.center = NSCoder.string(for: textView.center)
                    text.opacity = Float(textView.textOpacity)
                    text.hspacing = Float(textView.hSpacing)
                    text.vspacing = Float(textView.vSpacing)
                    text.rotation = Float(textView.rotation)
                    media.texts.append(text)
                    textView.uuid = text.id
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    func didSelectKeyboard(_ view: TextsView) {
        
    }

    func didSelectFont(_ view: TextsView) {
        
    }

    func didSelectColor(_ view: TextsView) {
        
    }

    func didSelectFont(_ view: TextsView, _ fontName: String) {
        
    }

    func didSelectColor(_ view: TextsView, _ color: UIColor, _ index: Int) {
        
    }

    func didSelectOption(_ view: TextsView) {
        
    }

    func didSelectOption(_ view: TextsView, _ option: TextOption, _ value: CGFloat) {
        
    }
    
    func addTextView(_ text: String, _ showKeyboard: Bool, _ isOnVideoView: Bool) {
        for textView in arrayTextViews {
            textView.isHidden = false
        }

        if let textView = activeTextView, textView.isActive {
            return
        }
        
        activeImageView?.isActive = false
        activeTextView = nil

        let textView = TVTextView()
        let videoFrame = videoView.frame
        textView.textView.text = text
        textView.delegate = self
        textView.frame = TEXTVIEW_FRAME
        textView.center = CGPoint(x: videoFrame.midX, y: videoFrame.midY)
        if textView.frame.origin.y + textView.frame.size.height + textView.frame.origin.y > UIScreen.main.bounds.size.height - 216 {
            var center = textView.center
            center.y = UIScreen.main.bounds.size.height - 216 - videoFrame.origin.y - textView.frame.size.height
            textView.center = center
        }
        
        if isOnVideoView {
            let pan = UIPanGestureRecognizer(target: self, action: #selector(moveView(gesture:)))
            pan.minimumNumberOfTouches = 1
            pan.maximumNumberOfTouches = 2
            textView.addGestureRecognizer(pan)
            
            videoView.addSubview(textView)
            
            arrayTextViews.append(textView)
        } else {
            textView.tag = -1
            let viewIndex = self.mediaViews.count - 1 - selectedMediaIndex
            let selectedView = self.mediaViews[viewIndex]
            selectedView.addSubview(textView)
        }
        
        textView.fontIndex = 0
        textView.isActive = true
        textView.parentFrame = videoFrame
        textView.textColor = .white
        textView.colorIndex = 7
        activeTextView = textView

        let _ = self.textView(textView, shouldChangeText: text)
        if showKeyboard {
            self.perform(#selector(showKeyboard(_:)), with: textView, afterDelay: 0.1)
        }
    }
    
    @objc func showKeyboard(_ textView: TVTextView) {
        textView.showKeyboard()
    }
}

// MARK: - TVImageViewDelegate
extension EditViewController: TVImageViewDelegate {
    
    func isEditMode() -> Bool {
        return self.editButton.isHidden
    }
    
    func graphicsViewWillBecomeActive(_ imageView: TVImageView!) -> Bool {
        /*if artsView.isHidden == true || artsView.superview == nil {
            return false
        }*/
        
        for textView in arrayTextViews {
            textView.isActive = false
        }
        
        for iv in arrayImageViews {
            iv.isActive = false
        }
        
        activeImageView = imageView;
        return true
    }
    
    func graphicsViewRemovePressed(_ imageView: TVImageView!) {
        UIView.animate(withDuration: 0.2) {
            imageView.alpha = 0
        } completion: { finished in
            do {
                let media = ProjectManager.current.medias[self.selectedMediaIndex]
                try sharedRealm.write {
                    if let index = media.images.firstIndex(where: { media in
                        return media.id == imageView.uuid
                    }) {
                        media.images.remove(at: index)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            imageView.removeFromSuperview()
            if let index = self.arrayImageViews.firstIndex(of: imageView) {
                self.arrayImageViews.remove(at: index)
            }
            self.activeImageView = nil
        }
    }
    
    func graphicsView(_ imageView: TVImageView!, shouldChangeFrame newFrame: CGRect) -> Bool {
        
        return true
    }
    
    func setRotate(_ focusView: UIView){
        let project = ProjectManager.current
        let media = project.medias[selectedMediaIndex]
        if let textView = focusView as? TVTextView, let text = media.texts.first(where: { text in
            return textView.uuid == text.id
        }) {
            do {
                try sharedRealm.write {
//                    text.bounds = NSCoder.string(for: textView.bounds)
//                    text.center = NSCoder.string(for: textView.center)
                    text.rotation = Float(textView.rotation)
                }
            } catch {
                
            }
        } else if let imageView = focusView as? TVImageView, let image = media.images.first(where: { image in
            return imageView.uuid == image.id
        }) {
            do {
                try sharedRealm.write {
//                    image.bounds = NSCoder.string(for: imageView.bounds)
//                    image.center = NSCoder.string(for: imageView.center)
                    image.rotation = Float(imageView.rotation)
                }
            } catch {
                
            }
        }
    }
}

// MARK: - TVTextViewDelegate
extension EditViewController: TVTextViewDelegate {
    
    func isEditMode1() -> Bool {
        return self.editButton.isHidden
    }
    
    func textViewWillBecomeEdit(_ textView: TVTextView!) {
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 360 : 558
        let frame = CGRect(x: 0, y: self.view.frame.height - height, width: self.view.frame.width, height: height)
        textsView.frame = frame
        textsView.textView = textView
        let project = ProjectManager.current
        let media = project.medias[selectedMediaIndex]
        if let text = media.texts.first(where: { (text) -> Bool in
            return text.id == textView.uuid
        }) {
            textsView.text = text
        }
        textsView.isHidden = false
        self.view.addSubview(textsView)
        
        textDoneButton.isHidden = false
        shareButton.isHidden = true
    }
    
    func textViewWillBecomeActive(_ textView: TVTextView!) -> Bool {
        if textsView.isHidden || textsView.superview == nil {
            //return false
        }
        
        activeImageView?.isActive = false
        activeTextView = textView
        
        textView.superview?.bringSubviewToFront(textView)
        
        for tv in arrayTextViews {
            if tv != textView {
                tv.isActive = false
            }
        }
        
        for imageView in arrayImageViews {
            imageView.isActive = false
        }
        
        let media = ProjectManager.current.medias[selectedMediaIndex]
        if let text = media.texts.first(where: { text in
            return textView.uuid == text.id
        }) {
            textsView.textView = textView
            textsView.text = text
        }
        
        timeLabel.isHidden = true
        assetButtonView.isHidden = true
        
        return true
    }
    
    func textViewDidChange(_ textView: TVTextView!) {
        let project = ProjectManager.current
        let media = project.medias[selectedMediaIndex]
        if let text = media.texts.first(where: { (text) -> Bool in
            return text.id == textView.uuid
        }) {
            do {
                try sharedRealm.write {
                    text.fontSize = Float(textView.fontSize)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func textViewRemovePressed(_ textView: TVTextView!) {
        UIView.animate(withDuration: 0.2) {
            textView.alpha = 0.0
        } completion: { finished in
            do {
                let media = ProjectManager.current.medias[self.selectedMediaIndex]
                try sharedRealm.write {
                    if let index = media.texts.firstIndex(where: { media in
                        return media.id == textView.uuid
                    }) {
                        media.texts.remove(at: index)
                    }
                }
            } catch {
                print(error.localizedDescription)
            }
            textView.removeFromSuperview()
            if let index = self.arrayTextViews.firstIndex(of: textView) {
                self.arrayTextViews.remove(at: index)
            }
            self.activeTextView = nil
        }
    }
    
    func textView(_ textView: TVTextView!, shouldChangeFrame newFrame: CGRect) -> Bool {
        return true
    }
    
    func textView(_ textView: TVTextView!, shouldChangeText newText: String!) -> Bool {
        let transform = textView.transform
        textView.transform = .identity
        
        var shouldChangeText = true
        
        let edgeInsets = textView.textEdgesInsets()
        let containedFrame = self.videoView.frame
        
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
        
        return shouldChangeText
    }
}

extension EditViewController: EditBoardViewDelegate {
    func didSelectAssetView(_ view: EditBoardView) {
        
    }
    
    func didSelectTrimView(_ view: EditBoardView) {
        
        shareButton.isHidden = true
        let project = ProjectManager.current
        editView.addSubview(trimPlayerView)
        trimPlayerView.frame = videoView.frame
        let media = project.medias[selectedMediaIndex]
        let url = URL(fileURLWithPath: media.path())
        let asset = AVURLAsset(url: url)
        trimPlayerView.configPlayerView(url, startTime: .zero, endTime: asset.duration)
        editView.bringSubviewToFront(trimPlayView)
        trimPlayView.isHidden = false
        trimPlayerView.playerDidEndTimeHandler = { view in
            self.trimPlayView.isHidden = false
            self.editBoardView.showSeekTime(view.startTime)
        }
        trimPlayerView.playerDidPlayHandler = { view, time in
            self.editBoardView.showSeekTime(time)
        }
    }
    
    func didChangeTrimView(_ view: EditBoardView, startTime: CMTime) {
        trimPlayerView.startTime = startTime
        trimPlayerView.pause()
        trimPlayerView.seek(startTime)
    }
    
    func didChangeTrimView(_ view: EditBoardView, endTime: CMTime) {
        trimPlayerView.endTime = endTime
        trimPlayerView.pause()
        trimPlayerView.seek(endTime)
    }
    
    func didDoneTrimView(_ view: EditBoardView, _ url: URL?, _ blururl: URL?) {
        if let url = url, let blururl = blururl {
            let project = ProjectManager.current
            let media = project.medias[selectedMediaIndex]
            media.deleteFile()
            do {
                try sharedRealm.write {
                    media.filename = url.lastPathComponent
                    media.blurname = blururl.lastPathComponent
                    mediasView.reloadData()
                }
            } catch {
                print(error.localizedDescription)
            }
            updateSeekSlider()
        }
        
        didSelectDone(view)
        
        self.loadProject()
    }
    
    func didSelectTimeView(_ view: EditBoardView) {
        
    }
    
    func didSelectSizeView(_ view: EditBoardView) {
        
    }
    
    func didSelectVolumeView(_ view: EditBoardView) {
        
    }
    
    func didSelectSubview(_ view: EditBoardView) {
        editDoneButton.isHidden = false
    }
    
    func didSelectText(_ view: EditBoardView) {
        editDoneButton.isHidden = false
        didSelectText(nil)
    }
    
    func didSelectDone(_ view: EditBoardView) {
        trimPlayView.isHidden = true
        trimPlayerView.removeFromSuperview()
        backButtonPressed(backButton)
    }
}

// MARK: - CropViewDelegate
extension EditViewController: CropViewDelegate {
    func didSelectRotate() {
        let media = ProjectManager.current.medias[selectedMediaIndex]
        do {
            try sharedRealm.write {
                var degree = media.degree + 90.0
                if degree >= 360.0 {
                    degree -= 360.0
                }
                media.degree = degree
                let rotateTransform = CGAffineTransform.identity.rotated(by: .pi / 2.0)
                let transform = NSCoder.cgAffineTransform(for: media.transform).concatenating(rotateTransform)
                media.transform = NSCoder.string(for: transform)
                thumbImageView.transform = transform.concatenating(NSCoder.cgAffineTransform(for: media.contentTransform))

                blurImageView.transform = .identity
                blurImageView.frame = CGRect(x: 0, y: 0, width: videoView.frame.width, height: videoView.frame.height)
                if media.degree == 90 || media.degree == 270 {
                    blurImageView.frame = CGRect(x: 0, y: 0, width: videoView.frame.height, height: videoView.frame.width)
                }
                let angle = media.degree * .pi / 180.0
                let rotatedTransform = CGAffineTransform.identity.rotated(by: CGFloat(angle))
                blurImageView.transform = blurImageView.transform.concatenating(rotatedTransform)
                
                if media.isHorizontalFlip {
                    if media.degree == 0 || media.degree == 180 {
                        let flipTransform = CGAffineTransform.identity.scaledBy(x: -1.0, y: 1.0)
                        blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
                    } else if media.degree == 90 || media.degree == 270 {
                        let flipTransform = CGAffineTransform.identity.scaledBy(x: 1.0, y: -1.0)
                        blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
                    }
                }
                if media.isVerticalFlip {
                    if media.degree == 0 || media.degree == 180 {
                        let flipTransform = CGAffineTransform.identity.scaledBy(x: 1.0, y: -1.0)
                        blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
                    } else if media.degree == 90 || media.degree == 270 {
                        let flipTransform = CGAffineTransform.identity.scaledBy(x: -1.0, y: 1.0)
                        blurImageView.transform = blurImageView.transform.concatenating(flipTransform)
                    }
                }
                blurImageView.center = CGPoint(x: videoView.frame.width / 2.0, y: videoView.frame.height / 2.0)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func didSelectFlip() {
        let media = ProjectManager.current.medias[selectedMediaIndex]
        do {
            try sharedRealm.write {
                if media.degree == 0 || media.degree == 180 {
                    media.isHorizontalFlip = !media.isHorizontalFlip
                }
                if media.degree == 90 || media.degree == 270 {
                    media.isVerticalFlip = !media.isVerticalFlip
                }
                
                let flipTransform = CGAffineTransform.identity.scaledBy(x: -1.0, y: 1.0)
                let transform = NSCoder.cgAffineTransform(for: media.transform).concatenating(flipTransform)
                media.transform = NSCoder.string(for: transform)
                thumbImageView.transform = transform.concatenating(NSCoder.cgAffineTransform(for: media.contentTransform))

                let blurTransform = blurImageView.transform
                blurImageView.transform = blurTransform.concatenating(flipTransform)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func didSelectFill() {
        var contentType = ContentType(rawValue: ProjectManager.current.contentType)!
        if contentType == .scaleFit {
            contentType = .scaleFill
        } else {
            contentType = .scaleFit
        }
        didChangeContentType(contentType)
    }
    
    func didSelectClose() {
        backButtonPressed(backButton)
    }
    
    func getVolume() -> Float {
        var volume: Float = 1.0
        if ProjectManager.current.musics.count > 0 {
            let item = ProjectManager.current.musics.last!
            volume = volume - item.volume
        }
        if effectView.themeIndex > 0 {
            volume = 0.25
        }
        return volume
    }
    @objc func loadProject() {
        
        SVProgressHUD.setBackgroundColor(.clear)
        SVProgressHUD.show()
        
        ProjectManager.current.project { project in
        }
    }
    
    func delayLoadProject() {
        perform(#selector(loadProject), with: nil, afterDelay: 0.1)
    }
    
    @objc func pauseCurrentView() {
        if currentPlayViewIndex == -1 {
            return
        }
        let currentIndex = self.mediaVideos.count - 1 - currentPlayViewIndex
        
        if self.mediaViews[currentIndex].tag == 10 {
            self.mediaVideos[currentIndex].pause()
        } else {
            let view = self.mediaViews[currentIndex]
            let imageView = view.subviews.first as! UIImageView
            Utilities.pauseLayer(layer: imageView.layer)
        }
    }
    
    @objc func resumeCurrentView() {
        if currentPlayViewIndex == -1 {
            return
        }
        let currentIndex = self.mediaVideos.count - 1 - currentPlayViewIndex
        
        if self.mediaViews[currentIndex].tag == 10 {
            self.mediaVideos[currentIndex].volume = getVolume()
            self.mediaVideos[currentIndex].play()
        } else {
            let view = self.mediaViews[currentIndex]
            let imageView = view.subviews.first as! UIImageView
            Utilities.resumeLayer(layer: imageView.layer)
        }
    }
    
    @objc func showCurrentView(_ currentIndex0: Int) {
        
        if currentPlayViewIndex != currentIndex0 {
            let volume = getVolume()
//            selectedMediaIndex = currentIndex0
//            let media = ProjectManager.current.medias[currentIndex0]
//            updateAssets(media, false)
            
            let currentIndex = self.mediaViews.count - 1 - currentPlayViewIndex
            let prevIndex = self.mediaViews.count - 1 - currentIndex0
            
            currentPlayViewIndex = currentIndex0
            
            if prevIndex < self.mediaViews.count && prevIndex >= 0 {
                if currentIndex0 == 0 {
                    if self.mediaViews[prevIndex].tag == 10 {
                        self.mediaVideos[prevIndex].volume = volume
                        self.mediaVideos[prevIndex].seek(to: CMTime(seconds: 0, preferredTimescale: CMTimeScale(1)))
                        self.mediaVideos[prevIndex].play()
                    } else {
                        let view = self.mediaViews[prevIndex].subviews.first!
                        Utilities.viewZoomAnimation(view, TimeInterval(ProjectManager.current.imageDuration), true)
                        //self.currentProject!.settings.fixedPhotoDuration
                    }
                    return
                }
                if self.mediaViews[prevIndex].tag == 10 {
                    self.mediaVideos[prevIndex].volume = volume
                    self.mediaVideos[prevIndex].seek(to: CMTime(seconds: 0, preferredTimescale: CMTimeScale(1)))
                    self.mediaVideos[prevIndex].play()
                } else {
                    let view = self.mediaViews[prevIndex].subviews.first!
                    Utilities.viewZoomAnimation(view, TimeInterval(ProjectManager.current.imageDuration), Bool.random())
                    // self.currentProject!.settings.fixedPhotoDuration
                }
            }
            if currentIndex < self.mediaViews.count && currentIndex > 0 {
                let _tempView = self.mediaViews[currentIndex]
                Utilities.viewAnimation(Int.random(in: 0..<8), _tempView)
            }
        }
    }
    
    @objc func seekTimeSlider(_ frameNumber: Int) {
        if self.currentProject == nil {
            return
        }
        var currentIndex = 0
        var currentSeekTime = 0.0
        var index = 0, frameCount = 0
        while index < self.currentProject!.imageItems.count {
            let temp = frameCount
            let item = self.currentProject!.imageItems[index]
            if item.isVideo {
                frameCount = frameCount + Int(self.currentProject!.framesPerSecond * item.duration)
            } else {
                frameCount = frameCount + Int(self.currentProject!.framesPerSecond * CGFloat(ProjectManager.current.imageDuration))
                //self.currentProject!.settings.fixedPhotoDuration
            }
            
            if frameCount > frameNumber {
                currentIndex = index
                currentSeekTime = CGFloat(frameNumber - temp) / self.currentProject!.framesPerSecond
                self.innerSeekSlider(currentIndex, currentSeekTime)
                break
            }
            
            index = index + 1
        }
        
        self.updateTimeValue(Double(frameNumber / Int(self.currentProject!.framesPerSecond)))
    }
    
    func innerSeekSlider(_ currentPlayViewIndex: Int, _ seekTime: CGFloat) {
        let currentIndex = self.mediaViews.count - 1 - currentPlayViewIndex
        var index = self.mediaViews.count - 1
        while index > -1 {
            let itemMediaView = self.mediaViews[index]
            if index > currentIndex {
                itemMediaView.alpha = 0
            } else {
                itemMediaView.alpha = 1.0
            }
            let itemVideo = self.mediaVideos[index]
            if itemMediaView.tag == 10 {
                if index == currentIndex {
                    itemVideo.seek(to: CMTime(seconds: seekTime, preferredTimescale: CMTimeScale(1)))
                }
                else {
                    itemVideo.pause()
                    itemVideo.seek(to: CMTime(seconds: 0, preferredTimescale: CMTimeScale(1)))
                }
            }
            index = index - 1
        }
    }
    
    @objc func viewPlayViewHide(_ isHidden: Bool) {
        if !isHidden {
            self.viewPlayerView.alpha = 1
            self.viewPlayerRecoverView.alpha = 1
        }
    }
    
    @objc func updateTimeValue(_ value: Double) {
        self.seekSlider.value = Float(value)
        
        let duration = Int(ProjectManager.current.duration())
        
        if value - Double(Int(value)) > 0.95 {
            timeLabel.text =  Utilities.timeString(duration) + "/" + Utilities.timeString(duration)
        } else {
            timeLabel.text = Utilities.timeString(Int(value)) + "/" + Utilities.timeString(duration)
        }
    }
}
