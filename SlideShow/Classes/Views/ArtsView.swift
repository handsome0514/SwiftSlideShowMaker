//
//  ArtsView.swift
//  SlideShow
//
//  Created by Hua Wan on 9/29/21.
//

import UIKit

protocol ArtsViewDelegate {
    func didSelectArt(_ category: String, _ filename: String, _ artImage: UIImage)
    func didSelectClose(_ view: ArtsView)
}

class ArtsView: UIView {
    
    @IBOutlet weak var panView: UIView!
    @IBOutlet weak var categoriesCollectionView: UICollectionView!
    @IBOutlet weak var artsCollectionView: UICollectionView!
    
    fileprivate var resourceURL = Bundle.main.bundleURL.appendingPathComponent("Stickers")
    fileprivate var selectedCategoryIndex: Int = 0
    
    var categories: [String] = []
    var stickers: [String] = []
    
    var media: Media! {
        didSet {
            
        }
    }
    
    var delegate: ArtsViewDelegate? = nil
    
    class func loadFromNib() -> ArtsView {
        let bundles = Bundle.main.loadNibNamed("ArtsView", owner: self, options: nil)!.filter { bundle in
            return bundle is ArtsView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! ArtsView
        } else {
            return bundles.last as! ArtsView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        loadCategories()
        loadStickers(0)
        
        categoriesCollectionView.register(UINib(nibName: "ArtViewCell", bundle: nil), forCellWithReuseIdentifier: "ArtViewCell")
        artsCollectionView.register(UINib(nibName: "ArtViewCell", bundle: nil), forCellWithReuseIdentifier: "ArtViewCell")
    }
    
    fileprivate func loadCategories() {
        do {
            categories = try FileManager.default.contentsOfDirectory(atPath: resourceURL.path).sorted()
        } catch {
            categories = []
        }
        categoriesCollectionView.reloadData()
    }
    
    fileprivate func loadStickers(_ index: Int) {
        let url = resourceURL.appendingPathComponent(categories[index])
        stickers.removeAll()
        if let assets = try? FileManager.default.contentsOfDirectory(atPath: url.path) {
            stickers.append(contentsOf: assets.sorted())
        }
        artsCollectionView.reloadData()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

    @IBAction func backButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func handlePanGestureRecognizer(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self)
        var frame = self.frame
        frame.origin.y += translation.y
        frame.size.height -= translation.y
        if frame.origin.y < self.superview!.safeAreaInsets.top {
            frame.origin.y = self.superview!.safeAreaInsets.top
            frame.size.height = self.superview!.frame.height - frame.origin.y
        }
        let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 260 : 340
        if frame.size.height < height {
            frame.origin.y = self.superview!.frame.height - height
            frame.size.height = height
        }
        self.frame = frame
        sender.setTranslation(.zero, in: self)
    }
}

extension ArtsView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoriesCollectionView {
            return categories.count
        } else {
            return stickers.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoriesCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArtViewCell", for: indexPath) as! ArtViewCell
            cell.backgroundImageView.isHidden = false
            let url = resourceURL.appendingPathComponent(categories[indexPath.item])
            var assets: [String] = []
            do {
                assets = try FileManager.default.contentsOfDirectory(atPath: url.path)
            } catch {
                print(error.localizedDescription)
            }
            let image = UIImage(contentsOfFile: url.appendingPathComponent(assets[0]).path)
            cell.artImage = image
            cell.isSelection = indexPath.item == selectedCategoryIndex
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ArtViewCell", for: indexPath) as! ArtViewCell
            let url = resourceURL.appendingPathComponent(categories[selectedCategoryIndex]).appendingPathComponent(stickers[indexPath.item])
            cell.artImage = UIImage(contentsOfFile: url.path)
            cell.isSelection = media.images.contains(where: { image in
                return image.category == categories[selectedCategoryIndex] && image.filename == stickers[indexPath.item]
            })
            return cell
        }
    }
}

extension ArtsView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoriesCollectionView {
            selectedCategoryIndex = indexPath.item
            collectionView.reloadData()
            loadStickers(indexPath.item)
        } else {
            var image: UIImage!
            let url = resourceURL.appendingPathComponent(categories[selectedCategoryIndex]).appendingPathComponent(stickers[indexPath.item])
            image = UIImage(contentsOfFile: url.path)
            delegate?.didSelectArt(categories[selectedCategoryIndex], stickers[indexPath.item], image)
        }
    }
}

extension ArtsView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        if collectionView == categoriesCollectionView {
            return UIEdgeInsets(top: 10, left: 20, bottom: 10, right: 20)
        } else {
            return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoriesCollectionView {
            return CGSize(width: 64.0, height: collectionView.frame.height - 20)
        } else {
            let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 64 : 72
            return CGSize(width: (collectionView.frame.width - 54.0) / 6.0, height: height)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == categoriesCollectionView {
            return 0.0
        } else {
            return 10.0
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == categoriesCollectionView {
            return 0.0
        } else {
            return 10.0
        }
    }
}
