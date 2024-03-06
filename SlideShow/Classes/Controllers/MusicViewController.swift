//
//  MusicViewController.swift
//  SlideShow
//
//  Created by Hua Wan on 5/13/22.
//

import UIKit
import MediaPlayer

class MusicViewController: UIViewController {

    @IBOutlet weak var categoriesCollectionView: UICollectionView!
    @IBOutlet weak var musicCollectionView: UICollectionView!
    @IBOutlet weak var popularButton: GradientButton!
    
    fileprivate var categories: [String] = ["Moods", "iTunes", "Importend music"]
    fileprivate var musics: [[String: Any]] = []
    fileprivate var selectedCategoryIndex: Int = 0
    
    var musicPickerHandler: ((_ name: String, _ url: URL) -> Void)? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        loadMusics()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        popularButton.colors = [UIColor("#29EFF6").cgColor, UIColor("27AAE1").cgColor]
        popularButton.startPoint = CGPoint(x: 0.0, y: 0.5)
        popularButton.endPoint = CGPoint(x: 1.0, y: 0.5)
    }
    
    fileprivate func loadMusics() {
        let category = UserDefaults.standard.string(forKey: "category_data")
        if let data = category?.data(using: .utf8) {
            do {
                musics = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [[String: Any]]
            } catch {
                print(error.localizedDescription)
            }
            
            musics = musics.filter({ music in
                return (music["Type"] as! String) == "Music"
            })
            
            musicCollectionView.reloadData()
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "SongsViewController" {
            let controller = segue.destination as! SongsViewController
            controller.songItem = sender as! [String: Any]
            controller.didSelectSong = { url, name in
                self.musicPickerHandler?(name, url)
                self.dismiss(animated: true, completion: nil)
            }
        }
    }

    // MARK: - IBAction
    @IBAction func didTapClose(_ sender: UIButton?) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func didTapPopular(_ sender: UIButton?) {
        
    }
}

// MARK: - UICollectionViewDataSource
extension MusicViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == categoriesCollectionView {
            return categories.count
        } else {
            return musics.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == categoriesCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "AlbumViewCell", for: indexPath) as! AlbumViewCell
            cell.albumNameLabel.text = categories[indexPath.item]
            cell.isSelection = indexPath.item == selectedCategoryIndex
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MediaViewCell", for: indexPath) as! MediaViewCell
            let item = musics[indexPath.item]
            cell.item = item
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension MusicViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == categoriesCollectionView {
            //selectedCategoryIndex = indexPath.item
            //categoriesCollectionView.reloadData()
            if indexPath.item == 1 {
                let mediaPicker = MPMediaPickerController(mediaTypes: .music)
                mediaPicker.delegate = self
                mediaPicker.allowsPickingMultipleItems = false
                mediaPicker.showsCloudItems = true
                present(mediaPicker, animated: true, completion: nil)
            }
        } else {
            performSegue(withIdentifier: "SongsViewController", sender: musics[indexPath.item])
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension MusicViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == categoriesCollectionView {
            let height: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 36.0 : 72
            let title = categories[indexPath.item]
            let font = UIDevice.current.userInterfaceIdiom == .phone ? UIFont.medium(size: 14) : UIFont.medium(size: 24)
            let size = title.size(.infinity, height, [NSAttributedString.Key.font: font!])
            return CGSize(width: size.width + 8.0, height: height)
        } else {
            let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 16.0 : 24.0
            var width = (collectionView.frame.width - offset * 3.0 - 2.0) / 2.0
            if UIDevice.current.userInterfaceIdiom == .pad {
                width = (collectionView.frame.width - offset * 3.0 - 2.0) / 2.0
            }
            return CGSize(width: width, height: width * 1.4)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let offset: CGFloat = UIDevice.current.userInterfaceIdiom == .phone ? 16.0 : 24.0
        if collectionView == categoriesCollectionView {
            return UIEdgeInsets(top: 0, left: offset, bottom: 0, right: offset)
        } else {
            return UIEdgeInsets(top: 0, left: offset, bottom: 0, right: offset)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == categoriesCollectionView {
            return UIDevice.current.userInterfaceIdiom == .phone ? 8 : 24
        } else {
            return UIDevice.current.userInterfaceIdiom == .phone ? 16.0 : 24
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        if collectionView == categoriesCollectionView {
            return UIDevice.current.userInterfaceIdiom == .phone ? 8 : 24
        } else {
            return UIDevice.current.userInterfaceIdiom == .phone ? 16.0 : 24
        }
    }
}

// MARK: - MediaViewCellDelegate
extension MusicViewController: MediaViewCellDelegate {
    func didTapRemove(_ cell: MediaViewCell) {
        
    }
}

extension MusicViewController: MPMediaPickerControllerDelegate {
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        mediaPicker.dismiss(animated: true, completion: nil)
        guard let mediaItem = mediaItemCollection.items.first, let assetURL = mediaItem.value(forProperty: MPMediaItemPropertyAssetURL) as? URL else {
            let controller = UIAlertController(title: nil, message: "This song is not downloaded to your device.", preferredStyle: .alert)
            controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(controller, animated: true, completion: nil)
            return
        }
        
        //removeAudioPlayer()
        if let artist = mediaItem.artist, artist != "" {
            musicPickerHandler?("\(mediaItem.title!) - \(artist)", assetURL)
        } else {
            musicPickerHandler?(mediaItem.title!, assetURL)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
}
