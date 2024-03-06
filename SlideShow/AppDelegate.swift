//
//  AppDelegate.swift
//  SlideShow
//
//  Created by Hua Wan on 4/8/22.
//

import UIKit
import SVProgressHUD
import Alamofire
import GiphyUISDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        window = UIWindow(frame: UIScreen.main.bounds)
        
        Giphy.configure(apiKey: "n775M3UKzXNioifxjRhQjbMa4r1YZrIu")
        
        SVProgressHUD.setDefaultMaskType(.custom)
        SVProgressHUD.setForegroundColor(MAIN_ACTIVE_COLOR_1)
//        IAPManagerProYearlyId, IAPManagerProMonthlyId, IAPManagerProQuarterlyId, IAPManagerProWeeklylyId, IAPManagerGetEverythingId, IAPManagerUnlockTransitionsId, IAPManagerUnlockMusicId, IAPManagerUnlimitedPhotosId, IAPManagerRemoveWatermarkId, IAPManagerRemoveAdsId
        
        PurchaseManager.sharedManager.retrievePrices(productIds: [IAPManagerProWeeklylyId]) { products in
            
            print(products)
            
            PurchaseManager.sharedManager.completeTransactions()
        }
        
        downloadPlaylist()
        
        downloadCategory()
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    func downloadPlaylist() {
        do {
            var request = try URLRequest(url: "http://157.230.235.143/api/playlist.php", method: .get, headers: nil)
            request.setValue("text/html", forHTTPHeaderField: "Accept")
            AF.request(request).responseJSON { response in
                switch response.result {
                case .success(let responseObject):
                    //print(responseObject)
                    do {
                        let data = try JSONSerialization.data(withJSONObject: responseObject, options: .fragmentsAllowed)
                        let string = String(data: data, encoding: .utf8)
                        UserDefaults.standard.set(string, forKey: "playlist_data")
                    } catch {
                        print(error.localizedDescription)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func downloadCategory() {
        do {
            var request = try URLRequest(url: "http://157.230.235.143/api/categories.php", method: .get, headers: nil)
            request.setValue("text/html", forHTTPHeaderField: "Accept")
            AF.request(request).responseJSON { response in
                switch response.result {
                case .success(let responseObject):
                    //print(responseObject)
                    do {
                        let data = try JSONSerialization.data(withJSONObject: responseObject, options: .fragmentsAllowed)
                        let string = String(data: data, encoding: .utf8)
                        UserDefaults.standard.set(string, forKey: "category_data")
                    } catch {
                        print(error.localizedDescription)
                    }
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}

