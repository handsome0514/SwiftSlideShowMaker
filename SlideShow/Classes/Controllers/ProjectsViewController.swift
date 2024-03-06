//
//  ProjectsViewController.swift
//  SlideShow
//
//  Created by Hua Wan on 9/15/21.
//

import UIKit
import Realm
import SVProgressHUD
import AppTrackingTransparency

class ProjectsViewController: UIViewController {
    
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var projectsCollectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!
    @IBOutlet var sheetMenuView: UIView!
    @IBOutlet var sheetSupportView: UIView!
    
    @IBOutlet weak var menuExportView: UIView!
    @IBOutlet weak var menuRenameView: UIView!
    @IBOutlet weak var menuDuplicateView: UIView!
    @IBOutlet weak var menuCloseButton: UIButton!
    
    @IBOutlet weak var widthMenuConstraint: NSLayoutConstraint!
    @IBOutlet weak var widthSupportConstraint: NSLayoutConstraint!
    
    fileprivate var isFirstAppear: Bool = true
    fileprivate var popupView: FFPopup!
    fileprivate var isNewProject: Bool = false
    
    var projects: [Project] = []
    var key: String = ""
    var selectedProject: Project? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        menuExportView.addRoundedShadows(0.2, .lightGray)
        menuRenameView.addRoundedShadows(0.2, .lightGray)
        menuDuplicateView.addRoundedShadows(0.2, .lightGray)
        
        sheetMenuView.layer.cornerRadius = 30
        sheetMenuView.layer.masksToBounds = true
        sheetSupportView.layer.cornerRadius = 30
        sheetSupportView.layer.masksToBounds = true
        
        widthMenuConstraint.constant = UIScreen.main.bounds.width - 108
        widthSupportConstraint.constant = UIScreen.main.bounds.width - 108
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        gesture.delegate = self
        gesture.cancelsTouchesInView = false
        self.view.addGestureRecognizer(gesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleClosePurchaseView(_:)), name: NSNotification.Name(rawValue: "ProductClosedFailed"), object: nil)
        
        loadProjects()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if isFirstAppear {
            isFirstAppear = false
            
            /*if #available(iOS 14, *) {
                ATTrackingManager.requestTrackingAuthorization { status in
                    print(status)
                }
            } else {
                // Fallback on earlier versions
            }*/
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        //sheetMenuView.roundCorners(corners: [.topLeft, .topRight], radius: 30)
    }
    
    fileprivate func loadProjects() {
        self.projects.removeAll()
        var projects = sharedRealm.objects(Project.self)
        if key != "" {
            projects = projects.filter(NSPredicate(format: "name CONTAINS[cd] %@", key))
        }
        projects = projects.sorted(byKeyPath: "name", ascending: true)
        self.projects.append(contentsOf: projects)
        
        if projects.count == 0 {
            emptyView.isHidden = false
            projectsCollectionView.isHidden = true
        } else {
            emptyView.isHidden = true
            projectsCollectionView.isHidden = false
        }
        
        projectsCollectionView.reloadData()
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "RenameViewController" {
            let controller = segue.destination as! RenameViewController
            controller.name = sender as! String
            controller.didChangeName = { name in
                if let project = self.selectedProject {
                    if let index = self.projects.firstIndex(of: project), let cell = self.projectsCollectionView.cellForItem(at: IndexPath(item: index, section: 0)) as? ProjectViewCell {
                        cell.updateName()
                    }
                    
                    do {
                        try sharedRealm.write {
                            project.name = name
                        }
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            }
        }
    }

    // MARK: - IBAction
    @IBAction func purchasePressed(_ sender: UIButton) {
        PurchaseView.show().parentViewController = self
        isNewProject = false
    }
    
    @IBAction func infoPressed(_ sender: UIButton) {
        sheetSupportView.removeFromSuperview()
        let contentView = sheetSupportView!
        contentView.frame = CGRect(x: 24, y: 0, width: view.frame.width - 48, height: contentView.frame.height)
        popupView = FFPopup(contentView: contentView, showType: .slideInFromBottom, dismissType: .slideOutToBottom, maskType: .dimmed, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
        let layout = FFPopupLayout(horizontal: .center, vertical: .bottom, offset: 10 + view.safeAreaInsets.bottom)
        popupView.show(layout: layout)
    }
    
    @IBAction func createProjectPressed(_ sender: UIButton) {
//        if PurchaseManager.sharedManager.isPurchased() == false {
//            PurchaseView.show().parentViewController = self
//            isNewProject = true
//            return
//        }
        ProjectManager.current = Project()
        performSegue(withIdentifier: "MediasViewController", sender: nil)
    }
    
    @IBAction func exportButtonPressed(_ sender: UIButton) {
        popupView.dismiss(animated: true)
        guard let project = selectedProject else {
            return
        }
        
        if project.medias.count == 0 {
            return
        }
        
        ProjectManager.shared.share(project: project, from: self, sourceView: sender)
    }
    
    @IBAction func renameButtonPressed(_ sender: UIButton) {
        popupView.dismiss(animated: true)
        if let project = selectedProject {
            performSegue(withIdentifier: "RenameViewController", sender: project.name)
        }
    }
    
    @IBAction func duplicateButtonPressed(_ sender: UIButton) {
        popupView.dismiss(animated: true)
        if let project = selectedProject {
            let duplicate = project.copy() as! Project
            do {
                try sharedRealm.write {
                    sharedRealm.add(duplicate)
                }
            } catch {
                print(error.localizedDescription)
            }
            
            projects.append(duplicate)
            projectsCollectionView.reloadData()
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: UIButton) {
        popupView.dismiss(animated: true)
        if let project = selectedProject {
            if let index = projects.firstIndex(of: project) {
                projects.remove(at: index)
                
                project.deleteFile()
                do {
                    try sharedRealm.write {
                        sharedRealm.delete(project)
                    }
                } catch {
                    print(error.localizedDescription)
                }
                
                selectedProject = nil
                projectsCollectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                
                if projects.count == 0 {
                    emptyView.isHidden = false
                    projectsCollectionView.isHidden = true
                } else {
                    emptyView.isHidden = true
                    projectsCollectionView.isHidden = false
                }
            }
        }
    }
    
    @IBAction func closeButtonPressed(_ sender: UIButton) {
        popupView.dismiss(animated: true)
    }
    
    @IBAction func feedbackButtonPressed(_ sender: UIButton) {
        popupView.dismiss(animated: true)
    }
    
    @IBAction func supportButtonPressed(_ sender: UIButton) {
        popupView.dismiss(animated: true)
    }
    
    @IBAction func subscriptionButtonPressed(_ sender: UIButton) {
        popupView.dismiss(animated: true)
    }
    
    @IBAction func handleTapGesture(_ sender: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }
    
    @IBAction func handleClosePurchaseView(_ sender: Notification) {
        if isNewProject == true {
            performSegue(withIdentifier: "MediasViewController", sender: nil)
        }
    }
}

extension ProjectsViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return projects.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProjectViewCell", for: indexPath) as! ProjectViewCell
        cell.project = projects[indexPath.item]
        cell.delegate = self
        return cell
    }
}

extension ProjectsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        ProjectManager.current = projects[indexPath.item]
//        ProjectManager.shared.isEditing = true
//        performSegue(withIdentifier: "MediasViewController", sender: nil)
        let storyboard = UIStoryboard(name: "Edit", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "EditViewController") as! EditViewController
        navigationController?.pushViewController(controller, animated: true)
    }
}

extension ProjectsViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height * 0.6)
        } else {
            return CGSize(width: collectionView.frame.width, height: collectionView.frame.height * 0.8)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return .zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

extension ProjectsViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        self.key = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        loadProjects()
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

extension ProjectsViewController: ProjectViewCellDelegate {
    func didTapOption(_ cell: ProjectViewCell) {
        selectedProject = cell.project
        sheetMenuView.removeFromSuperview()
        let contentView = sheetMenuView!
        contentView.frame = CGRect(x: 24, y: 0, width: view.frame.width - 48, height: contentView.frame.height)
        popupView = FFPopup(contentView: contentView, showType: .slideInFromBottom, dismissType: .slideOutToBottom, maskType: .dimmed, dismissOnBackgroundTouch: true, dismissOnContentTouch: false)
        let layout = FFPopupLayout(horizontal: .center, vertical: .bottom, offset: 10 + view.safeAreaInsets.bottom)
        popupView.show(layout: layout)
    }
}

extension ProjectsViewController: UIGestureRecognizerDelegate {
    
}
