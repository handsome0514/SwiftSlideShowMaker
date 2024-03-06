//
//  EffectView.swift
//  SlideShow
//
//  Created by Hua Wan on 9/21/21.
//

import UIKit

class EffectView: UIView {
    
    public var themeIndex: Int = 0
    
    var didSelectTheme: (() -> Void)? = nil

    @IBOutlet weak var mediasCollectionView: UICollectionView!
    
    var media: Media! {
        didSet {
            if media.type == MediaType.image.rawValue {
                thumbImage = UIImage(contentsOfFile: media.path())
            } else {
                thumbImage = Utilities.generateThumbImage(videoURL: URL(fileURLWithPath: media.path()), maxSize: CGSize(width: 300, height: 400))
            }
            mediasCollectionView.reloadData()
        }
    }
    
    fileprivate var thumbImage: UIImage!
    
    class func loadFromNib() -> EffectView {
        let bundles = Bundle.main.loadNibNamed("EffectView", owner: self, options: nil)!.filter { bundle in
            return bundle is EffectView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! EffectView
        } else {
            return bundles.last as! EffectView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        mediasCollectionView.register(UINib(nibName: "EffectViewCell", bundle: nil), forCellWithReuseIdentifier: "EffectViewCell")
    }
    
    fileprivate func updateEffectType(effectType: EffectType) {
        do {
            try sharedRealm.write {
                let project = ProjectManager.current
                for media in project.medias {
                    //if media.effectType == EffectType.none.rawValue {
                        media.effectType = effectType.rawValue
                    //}
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func updateThemeIndex(index: Int) {
        do {
            try sharedRealm.write {
                let project = ProjectManager.current
                project.themeIndex = index
                
                if project.musics.count > 0 {
                    project.musics.first?.deleteFile()
                    project.musics.remove(at: 0)
                }                
                
                self.themeIndex = index
            }
        } catch {
            print(error.localizedDescription)
        }
        
        didSelectTheme?()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

extension EffectView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ThemeManager.sharedInstance().themes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let theme = ThemeManager.sharedInstance().themes[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EffectViewCell", for: indexPath) as! EffectViewCell
        if media != nil, indexPath.item == ProjectManager.current.themeIndex {
            cell.isSelection = true
        }
        else {
            cell.isSelection = false
        }
        
        cell.name = (theme["name"] as! String)
        cell.thumbImage = UIImage(named: theme["thumbnail"] as! String)
        return cell
    }
}

extension EffectView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let project = ProjectManager.current
        if let cell = collectionView.cellForItem(at: IndexPath(item: project.themeIndex, section: 0)) as? EffectViewCell {
            cell.isSelection = false
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? EffectViewCell {
            cell.isSelection = true
        }
        
        //let effectType = EffectType(rawValue: indexPath.item)!
        //print(effectType)
        //updateEffectType(effectType: effectType)
        updateThemeIndex(index: indexPath.item)
    }
}

extension EffectView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = collectionView.frame.height - (UIDevice.current.userInterfaceIdiom == .phone ? 0.0 : 24.0)
        let width = (height - (UIDevice.current.userInterfaceIdiom == .phone ? 20.0 : 36.0)) * 0.7
        return CGSize(width: width, height: height)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return  UIDevice.current.userInterfaceIdiom == .phone ? 16.0 : 24.0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return  UIDevice.current.userInterfaceIdiom == .phone ? 16.0 : 24.0
    }
}
