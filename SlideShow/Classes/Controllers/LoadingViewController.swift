//
//  LoadingViewController.swift
//  SlideShow
//
//  Created by Hua Wan on 9/21/21.
//

import UIKit
import Photos
import SVProgressHUD

class LoadingViewController: UIViewController {
    
    fileprivate var isFirstAppear = true
    
    var selectedAssets: [MediaAsset] = []
    
    @IBOutlet weak var loadingPercentLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirstAppear {
            isFirstAppear = false
            
            SVProgressHUD.setBackgroundColor(.clear)
//            SVProgressHUD.show()
            SVProgressHUD.show(withStatus: "0%")
            
            if ProjectManager.shared.isEditing {
                updateProject()
            } else {
                createProject()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        SVProgressHUD.setBackgroundColor(.white)
        SVProgressHUD.dismiss()
    }
    
    fileprivate func showEditViewController() {
        let storyboard = UIStoryboard(name: UIDevice.current.userInterfaceIdiom == .phone ? "Edit" : "Edit", bundle: nil) //Edit_iPad
        let controller = storyboard.instantiateInitialViewController()!
        navigationController?.pushViewController(controller, animated: true)
    }
    
    fileprivate func createProject() {
        let project = ProjectManager.current
        var count = 0
        for index in 0..<selectedAssets.count {
            let asset = selectedAssets[index]
            if asset.asset.mediaType == .image {
                let filename = Utilities.generateRandomFileName(fileExtension: "png")
                let path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                let options = PHImageRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .highQualityFormat
                let media = Media()
                project.medias.append(media)
                PHImageManager.default().requestImage(for: asset.asset, targetSize: CGSize(width: asset.asset.pixelWidth, height: asset.asset.pixelHeight), contentMode: .aspectFill, options: options) { image, option in
                    if let image = image {
//                        let size = CGSize(width: image.size.width / 1.4, height: image.size.height / 1.4 )
//                        try? image.resizedImage(to: size).pngData()!.write(to: URL(fileURLWithPath: path))
                        try? image.pngData()!.write(to: URL(fileURLWithPath: path))
                        media.filename = filename
//                        let blur = image.blurImage()
//                        let blurname = Utilities.generateRandomFileName(fileExtension: "png")
//                        path = Utilities.generateFilePath(filename: blurname, projectId: project.id)
//                        try? blur.pngData()!.write(to: URL(fileURLWithPath: path))
                        media.blurname = filename
                        media.localIdentifier = asset.asset.localIdentifier
                        media.projectId = project.id
                        media.type = MediaType.image.rawValue
                        media.effectType = EffectType.none.rawValue
                        media.order = index
                        if let creationDate = asset.asset.creationDate {
                            media.creationDate = creationDate
                        } else {
                            media.creationDate = Date()
                        }
                        count += 1
                        self.completeProject(count)
                    }
                }
            } else if asset.asset.mediaType == .video {
                let filename = Utilities.generateRandomFileName(fileExtension: "mov")
                let path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                let options = PHVideoRequestOptions()
                options.isNetworkAccessAllowed = true
                options.deliveryMode = .fastFormat //.mediumQualityFormat //.highQualityFormat
                let media = Media()
                project.medias.append(media)
                PHImageManager.default().requestAVAsset(forVideo: asset.asset, options: options) { video, audioMix, option in
                    if let video = video {
                        VideoService.saveVideo(video, path: path) { success, error in
                            if success {
                                media.filename = filename
                                media.blurname = filename
                                media.localIdentifier = asset.asset.localIdentifier
                                media.projectId = project.id
                                media.type = MediaType.video.rawValue
                                media.effectType = EffectType.none.rawValue
                                media.order = index
                                if let creationDate = asset.asset.creationDate {
                                    media.creationDate = creationDate
                                } else {
                                    media.creationDate = Date()
                                }
                                count += 1
                                self.completeProject(count)
                            } else {
                                self.showAlertView("Error", "There was a problem to export video. Please try again.")
                            }
                        }
                    } else {
                        self.showAlertView("Error", "There was a problem to export video. Please try again.")
                    }
                }
            }
        }
    }
    
    fileprivate func updateProject() {
        let project = ProjectManager.current
        if selectedAssets.count == 0 {
            self.showEditViewController()
            return
        }
        var count = 0
        for index in 0..<selectedAssets.count {
            let asset = selectedAssets[index]
            if let mediaIndex = project.medias.firstIndex(where: { media in
                return asset.id == media.id
            }) {
                do {
                    try sharedRealm.write {
                        project.medias.move(from: mediaIndex, to: index)
                    }
                    count += 1
                    self.completeProject(count)
                } catch {
                    
                }
            } else {
                if asset.asset.mediaType == .image {
                    let filename = Utilities.generateRandomFileName(fileExtension: "png")
                    var path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                    let options = PHImageRequestOptions()
                    options.isNetworkAccessAllowed = true
                    options.deliveryMode = .highQualityFormat
                    let media = Media()
                    if ProjectManager.shared.isEditing {
                        do {
                            try sharedRealm.write {
                                project.medias.insert(media, at: count)
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    } else {
                        project.medias.insert(media, at: count)
                    }
                    PHImageManager.default().requestImage(for: asset.asset, targetSize: CGSize(width: asset.asset.pixelWidth, height: asset.asset.pixelHeight), contentMode: .aspectFill, options: options) { image, option in
                        DispatchQueue.main.async {
                            if let image = image {
                                try? image.pngData()!.write(to: URL(fileURLWithPath: path))
//                                let blur = image.blurImage()
//                                let blurname = Utilities.generateRandomFileName(fileExtension: "png")
//                                path = Utilities.generateFilePath(filename: blurname, projectId: project.id)
//                                try? blur.pngData()!.write(to: URL(fileURLWithPath: path))
                                if ProjectManager.shared.isEditing {
                                    do {
                                        try sharedRealm.write {
                                            media.filename = filename
                                            media.blurname = filename
                                            media.localIdentifier = asset.asset.localIdentifier
                                            media.projectId = project.id
                                            media.type = MediaType.image.rawValue
                                            media.effectType = EffectType.none.rawValue
                                            media.order = index
                                            if let creationDate = asset.asset.creationDate {
                                                media.creationDate = creationDate
                                            } else {
                                                media.creationDate = Date()
                                            }
                                        }
                                    } catch {
                                        print(error.localizedDescription)
                                    }
                                } else {
                                    media.filename = filename
                                    media.blurname = filename
                                    media.localIdentifier = asset.asset.localIdentifier
                                    media.projectId = project.id
                                    media.type = MediaType.image.rawValue
                                    media.effectType = EffectType.none.rawValue
                                    media.order = index
                                }
                                count += 1
                                self.completeProject(count)
                            }
                        }
                    }
                } else if asset.asset.mediaType == .video {
                    let filename = Utilities.generateRandomFileName(fileExtension: "mov")
                    let path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                    let options = PHVideoRequestOptions()
                    options.isNetworkAccessAllowed = true
                    options.deliveryMode = .highQualityFormat
                    let media = Media()
                    if ProjectManager.shared.isEditing {
                        do {
                            try sharedRealm.write {
                                project.medias.insert(media, at: count)
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    } else {
                        project.medias.insert(media, at: count)
                    }
                    PHImageManager.default().requestAVAsset(forVideo: asset.asset, options: options) { video, audioMix, option in
                        if let video = video {
                            VideoService.saveVideo(video, path: path) { success, error in
                                if success {
                                    media.filename = filename
                                    media.blurname = filename
                                    media.localIdentifier = asset.asset.localIdentifier
                                    media.projectId = project.id
                                    media.type = MediaType.video.rawValue
                                    media.effectType = EffectType.none.rawValue
                                    media.order = index
                                    count += 1
                                    self.completeProject(count)
                                    
//                                    let blurname = Utilities.generateRandomFileName(fileExtension: "mov")
//                                    let blurpath = Utilities.generateFilePath(filename: blurname, projectId: project.id)
//                                    VideoService.shared().blurVideo(AVURLAsset(url: URL(fileURLWithPath: path)), path: blurpath) { success in
//                                        if ProjectManager.shared.isEditing {
//                                            do {
//                                                try sharedRealm.write {
//                                                    media.filename = filename
//                                                    media.blurname = blurname
//                                                    media.localIdentifier = asset.asset.localIdentifier
//                                                    media.projectId = project.id
//                                                    media.type = MediaType.video.rawValue
//                                                    media.effectType = EffectType.none.rawValue
//                                                    media.order = index
//                                                    if let creationDate = asset.asset.creationDate {
//                                                        media.creationDate = creationDate
//                                                    } else {
//                                                        media.creationDate = Date()
//                                                    }
//                                                }
//                                            } catch {
//                                                print(error.localizedDescription)
//                                            }
//                                        } else {
//                                            media.filename = filename
//                                            media.blurname = blurname
//                                            media.localIdentifier = asset.asset.localIdentifier
//                                            media.projectId = project.id
//                                            media.type = MediaType.video.rawValue
//                                            media.effectType = EffectType.none.rawValue
//                                            media.order = index
//                                        }
//                                        count += 1
//                                        self.completeProject(count)
//                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    fileprivate func completeProject(_ count: Int) {
        
        var percent = 100 / selectedAssets.count
        percent = percent * count
//        SVProgressHUD.showProgress(Float(percent))
        SVProgressHUD.show(withStatus: "\(percent)%")
        
        if count == selectedAssets.count {
            SVProgressHUD.show(withStatus: "100%")
            let project = ProjectManager.current
            if ProjectManager.shared.isEditing {
                while project.medias.count > count {
                    do {
                        try sharedRealm.write {
                            project.medias.last?.deleteFile()
                            project.medias.removeLast()
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
            if ProjectManager.shared.isEditing {
                do {
                    try sharedRealm.write {
                        ProjectManager.current.modifiedDate = Date()
//                        perform(#selector(delayShowEditViewController), with: nil, afterDelay: 0.5)
                        self.showEditViewController()
                    }
                } catch {
                    print(error.localizedDescription)
                }
            } else {
                ProjectManager.current.createdDate = Date()
                ProjectManager.current.modifiedDate = Date()
                do {
                    try sharedRealm.write {
                        sharedRealm.add(project)
//                        perform(#selector(delayShowEditViewController), with: nil, afterDelay: 0.5)
                        self.showEditViewController()
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
    }
    
    @objc func delayShowEditViewController() {
        self.showEditViewController()
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
