//
//  MusicBottomView.swift
//  SlideShow
//
//  Created by Hua Wan on 4/20/22.
//

import UIKit

class MusicBottomView: UIView {
    
    @IBOutlet weak var audiosTableView: UITableView!
    @IBOutlet var headerView: UIView!
    
    public var delegateViewCtrl: EditViewController?
    
    var didSelectMusic: (() -> Void)? = nil
    var didSelectRecord: (() -> Void)? = nil
    var didPauseVideoPlay: (() -> Void)? = nil
    
    class func loadFromNib() -> MusicBottomView {
        let bundles = Bundle.main.loadNibNamed("MusicBottomView", owner: self, options: nil)!.filter { bundle in
            return bundle is MusicBottomView
        }
        if UIDevice.current.userInterfaceIdiom == .phone {
            return bundles.first as! MusicBottomView
        } else {
            return bundles.last as! MusicBottomView
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        headerView.removeFromSuperview()
        
        audiosTableView.register(UINib(nibName: "AudioViewCell", bundle: nil), forCellReuseIdentifier: "AudioViewCell")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        audiosTableView.reloadData()
    }
    
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    func reloadData() {
        audiosTableView.reloadData()
    }

    // MARK: - IBAction
    @IBAction func didTapMusic(_ sender: UIButton) {
        didSelectMusic?()
    }
    
    @IBAction func didTapRecord(_ sender: UIButton) {
        didSelectRecord?()
    }
}

extension MusicBottomView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ProjectManager.current.musics.count > 0 ? 1 : 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AudioViewCell", for: indexPath) as! AudioViewCell
        let project = ProjectManager.current
        let indexRow = project.musics.count - 1
        let music = project.musics[indexRow]
        cell.handleMusicEdit = { [self] music in
            
            didPauseVideoPlay?()
            
            let contentView = MusicEditView.loadFromNib()
            contentView.delegate = self.delegateViewCtrl
            let music = project.musics[indexRow]
            contentView.music = music
            contentView.frame = CGRect(x: 24, y: 0, width: self.frame.width - 48, height: contentView.frame.height)
            let popup = FFPopup(contentView: contentView, showType: .slideInFromBottom, dismissType: .slideOutToBottom, maskType: .dimmed, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
            let layout = FFPopupLayout(horizontal: .center, vertical: .bottom, offset: 10 + self.superview!.superview!.safeAreaInsets.bottom)
            popup.show(layout: layout)
            contentView.deleteButtonHandler = {
                do {
                    try sharedRealm.write {
                        music.deleteFile()
                        project.musics.remove(at: indexRow)
                        popup.dismiss(animated: true)
                        self.reloadData()
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        cell.handleMusicDelete = { music in
            
            self.didPauseVideoPlay?()
            do {
                try sharedRealm.write {
                    music.deleteFile()
                    project.musics.remove(at: indexRow)
                    self.reloadData()
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        cell.music = music
        return cell
    }
}

extension MusicBottomView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 88
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 {
            return 124
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 124))
            view.backgroundColor = .clear
            view.addSubview(headerView)
            headerView.frame = CGRect(x: (view.frame.width - headerView.frame.width) / 2.0, y: 0, width: headerView.frame.width, height: 124)
            headerView.backgroundColor = .clear
            return view
        } else {
            return nil
        }
    }
}

extension MusicBottomView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        /*let sectionHeaderHeight: CGFloat = 124
        if scrollView.contentOffset.y <= sectionHeaderHeight, scrollView.contentOffset.y >= 0 {
            scrollView.contentInset = UIEdgeInsets(top: -scrollView.contentOffset.y, left: 0, bottom: 0, right: 0)
        } else if scrollView.contentOffset.y >= sectionHeaderHeight {
            scrollView.contentInset = UIEdgeInsets(top: -sectionHeaderHeight, left: 0, bottom: 0, right: 0)
        }*/
    }
}
