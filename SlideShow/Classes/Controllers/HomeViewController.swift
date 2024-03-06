//
//  HomeViewController.swift
//  SlideShow
//
//  Created by Hua Wan on 9/15/21.
//

import UIKit
import LinearProgressBar

class HomeViewController: UIViewController {
    
    @IBOutlet weak var progressBar: LinearProgressBar!
    
    fileprivate var progressTimer: Timer? = nil
    fileprivate var progressValue: CGFloat = 0
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        progressBar.progressValue = progressValue
        progressBar.capType = CGLineCap.round.rawValue
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        startProgressTimer()
    }
    
    fileprivate func startProgressTimer() {
        stopProgressTimer()
        progressTimer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(handleProgressTimer(_:)), userInfo: nil, repeats: true)
    }
    
    fileprivate func stopProgressTimer() {
        if let timer = progressTimer {
            timer.invalidate()
            progressTimer = nil
        }
    }
    
    @objc fileprivate func handleProgressTimer(_ timer: Timer) {
        progressValue += 1
        progressBar.progressValue = progressValue
        if progressValue >= 12 {
            stopProgressTimer()
            performSegue(withIdentifier: "ProjectsViewController", sender: nil)
            if UserDefaults.standard.bool(forKey: "SlideshowOnboarding") == false {
                performSegue(withIdentifier: "OnboardingViewController", sender: nil)
            }
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

}
