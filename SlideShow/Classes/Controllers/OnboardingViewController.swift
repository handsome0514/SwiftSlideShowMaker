//
//  OnboardingViewController.swift
//  SlideShow
//
//  Created by Hua Wan on 4/11/22.
//

import UIKit
import Photos

class OnboardingViewController: UIViewController {

    @IBOutlet weak var onboardingScrollView: UIScrollView!
    @IBOutlet weak var nextButton: UIButton!
    
    var currentIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    fileprivate func requestLibraryAuthorization(_ completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus()
        if status == .authorized {
            completion(true)
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { (status) in
                self.requestLibraryAuthorization(completion)
            }
        } else {
            completion(false)
        }
    }
    
    fileprivate func checkCurrentIndex() {
        let index = Int(onboardingScrollView.contentOffset.x / onboardingScrollView.frame.size.width)
        if currentIndex == 1, index > currentIndex {
            requestLibraryAuthorization { granted in
                print(granted)
            }
        }
        currentIndex = index
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
    @IBAction func didTapNext(_ sender: UIButton) {
        if currentIndex >= 5 {
            UserDefaults.standard.set(true, forKey: "SlideshowOnboarding")
            dismiss(animated: true)
            return
        }
        
        if currentIndex == 1 {
            requestLibraryAuthorization { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.currentIndex += 1
                        self.onboardingScrollView.setContentOffset(CGPoint(x: CGFloat(self.currentIndex) * self.onboardingScrollView.frame.size.width, y: 0), animated: true)
                    }
                }
            }
        } else {
            currentIndex += 1
            onboardingScrollView.setContentOffset(CGPoint(x: CGFloat(currentIndex) * onboardingScrollView.frame.size.width, y: 0), animated: true)
        }
    }
}

extension OnboardingViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        checkCurrentIndex()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            checkCurrentIndex()
        }
    }
}
