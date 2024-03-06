//
//  SongsViewController.swift
//  SlideShow
//
//  Created by Hua Wan on 5/19/22.
//

import UIKit
import AVFoundation
import Alamofire
import SVProgressHUD

class SongsViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var songsTableView: UITableView!
    
    fileprivate var playlist: [[String: Any]] = []
    fileprivate var playingIndex: Int = -1
    fileprivate var isPlaying: Bool = false
    fileprivate var audioPlayer: AVPlayer? = nil
    fileprivate var audioPlayerItem: AVPlayerItem? = nil
    fileprivate var selectedIndex: Int = -1
    
    var songItem: [String: Any] = [:]
    var didSelectSong: ((URL, String) -> Void)? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        loadPlaylist()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        removeAudioPlayer()
    }
    
    fileprivate func loadPlaylist() {
        let category = UserDefaults.standard.string(forKey: "playlist_data")
        if let data = category?.data(using: .utf8) {
            do {
                playlist = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) as! [[String: Any]]
            } catch {
                print(error.localizedDescription)
            }
            
            let name = songItem["Name"] as! String
            playlist = playlist.filter({ item in
                return (item["Category"] as! String) == name
            }).first!["Songs"] as! [[String: Any]]
            
            songsTableView.reloadData()
        }
    }
    
    fileprivate func prepareAudioPlayer() {
        removeAudioPlayer()
        
        if playingIndex == -1 {
            return
        }
        
        let item = playlist[playingIndex]
        if let path = item["File"] as? String, let url = URL(string: path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) {
            audioPlayerItem = AVPlayerItem(url: url)
            audioPlayer = AVPlayer(playerItem: audioPlayerItem)
            NotificationCenter.default.addObserver(self, selector: #selector(handleDidEndMusicPlayer(_:)), name: .AVPlayerItemDidPlayToEndTime, object: nil)
        }
    }
    
    fileprivate func removeAudioPlayer() {
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)
        audioPlayer = nil
        audioPlayerItem = nil
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func handleDidEndMusicPlayer(_ notification: Notification) {
        if let userInfo = notification.object, let playerItem = userInfo as? AVPlayerItem, playerItem == audioPlayerItem {
            audioPlayer?.seek(to: .zero)
            audioPlayer?.play()
        }
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
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func didTapAdd(_ sender: UIButton) {
        if selectedIndex == -1 {
            return
        }
        
        let item = playlist[selectedIndex]
        if let path = item["File"] as? String, let url = URL(string: path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!) {
            SVProgressHUD.show()
            AF.download(url).downloadProgress(closure: { progress in
                SVProgressHUD.showProgress(Float(progress.completedUnitCount) / Float(progress.totalUnitCount))
            }).responseURL { response in
                SVProgressHUD.dismiss()
                switch response.result {
                case .success(let downloadURL):
                    let project = ProjectManager.current
                    let filename = Utilities.generateRandomFileName(fileExtension: "mp3")
                    let path = Utilities.generateFilePath(filename: filename, projectId: project.id)
                    let url = URL(fileURLWithPath: path)
                    try? FileManager.default.copyItem(at: downloadURL, to: url)
                    //add code via me
                    
                    self.navigationController?.popViewController(animated: false)
                    self.didSelectSong?(url, (item["Name"] as! String).replacingOccurrences(of: ".mp3", with: ""))
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}

extension SongsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playlist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SongViewCell", for: indexPath) as! SongViewCell
        cell.item = playlist[indexPath.row]
        cell.isPlaying = indexPath.row == playingIndex && isPlaying == true
        cell.isSelection = indexPath.row == selectedIndex
        cell.didTapPlay = { cell in
            if self.playingIndex == indexPath.row {
                if self.isPlaying {
                    self.isPlaying = false
                    self.audioPlayer?.pause()
                    cell.isPlaying = false
                } else {
                    self.isPlaying = true
                    self.audioPlayer?.play()
                    cell.isPlaying = true
                }
            } else {
                if self.playingIndex != -1, let cell = tableView.cellForRow(at: IndexPath(row: self.playingIndex, section: 0)) as? SongViewCell {
                    cell.isPlaying = false
                }
                self.playingIndex = indexPath.row
                self.prepareAudioPlayer()
                self.isPlaying = true
                self.audioPlayer?.play()
                cell.isPlaying = true
            }
        }
        if indexPath.row == selectedIndex {
            cell.isSelection = true
        } else {
            cell.isSelection = false
        }
        return cell
    }
}

extension SongsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if selectedIndex != -1, let cell = tableView.cellForRow(at: IndexPath(row: selectedIndex, section: 0)) as? SongViewCell {
//            cell.isSelection = false
//        }
        if let cell = tableView.cellForRow(at: indexPath) as? SongViewCell {
            cell.didTapPlay!(cell)
        }
//        if selectedIndex == indexPath.row {
//            selectedIndex = -1
//            return
//        }
        
        if let cell = tableView.cellForRow(at: indexPath) as? SongViewCell {
            cell.isSelection = true
        }
        
        selectedIndex = indexPath.row
        
        songsTableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}
