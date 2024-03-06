//
//  PurchaseManager.swift
//  AddWatermark
//
//  Created by Brad Nolan on 3/13/18.
//  Copyright © 2018 TotoVentures. All rights reserved.
//

import UIKit
import StoreKit
import SwiftyStoreKit
import SVProgressHUD

let IAPManagerGetEverythingId = "com.grassapper.slideshowmagic.geteverything"
let IAPManagerUnlockTransitionsId = "com.grassapper.slideshowmagic.unlocktransitions"
let IAPManagerUnlockMusicId = "com.grassapper.slideshowmagic.stockmusic"
let IAPManagerUnlimitedPhotosId = "com.grassapper.slideshowmagic.unlockUnlimitedPhotos"
let IAPManagerRemoveWatermarkId = "com.grassapper.slideshowmagic.removewatermark"
let IAPManagerRemoveAdsId = "com.grassapper.slideshowmagic.removeads"

let IAPManagerProMonthlyId = "com.grassapper.slideshowmagic.pro.1monthly"
let IAPManagerProWeeklylyId = "com.grassapper.slideshowmagic.pro.1weekly"
let IAPManagerProQuarterlyId = "com.grassapper.slideshowmagic.pro.3monthly"
let IAPManagerProYearlyId = "com.grassapper.slideshowmagic.pro.yearly"

@objc public class PurchaseManager: NSObject {
    
    @objc var priceLocal: Locale?
    @objc var prices: [String: String] = [:]
    @objc public var products: Set<SKProduct> = []
    @objc static public let sharedManager = PurchaseManager()
    
    let EXPIRE_DATE = "EXPIRE_DATE"
    let IS_PURCHASED = "IS_PURCHASED"
    let PRODUCT_ID = "PRODUCT_ID"
    
    @objc public func isPurchased(completion: @escaping (_ purchased: Bool) -> Void) {
        if UserDefaults.standard.object(forKey: IS_PURCHASED) != nil {
            if let expireDate = UserDefaults.standard.object(forKey: EXPIRE_DATE) as? Date, expireDate >= Date() {
                completion(UserDefaults.standard.bool(forKey: IS_PURCHASED))
            } else {
                let productId = UserDefaults.standard.string(forKey: PRODUCT_ID)
                verifySubscriptions([productId!], completion: completion)
            }
        } else {
            completion(false)
        }
    }
    
    // MARK: - Check isPurchased | return Bool
    @objc public func isPurchased() -> Bool {
        if UserDefaults.standard.bool(forKey: IAPManagerGetEverythingId) {
            return true
        }
        if UserDefaults.standard.bool(forKey: IS_PURCHASED) {
            if let expireDate = UserDefaults.standard.object(forKey: EXPIRE_DATE) as? Date, expireDate >= Date() {
                return true
            } else {
                return false
            }
        } else {
            return false
        }
    }
    
    @objc public func isPurchased(productId: String) -> Bool {
        //return true
        if isPurchased() {
            return true
        }
        if UserDefaults.standard.bool(forKey: IAPManagerGetEverythingId) {
            return true
        }
        if UserDefaults.standard.object(forKey: productId) != nil {
            return UserDefaults.standard.bool(forKey: productId)
        } else {
            return false
        }
    }
    
    @objc public func product(by ID: String) -> SKProduct? {
        for product in self.products {
            if product.productIdentifier == ID {
                return product
            }
        }
        
        return nil
    }
    
    @objc public func verifyPurchase(_ productId: String, completion: () -> Void) {
        
    }
    
    @objc public func setPurchased(productId: String, purchased: Bool, expireDate: Date) {
        UserDefaults.standard.set(purchased, forKey: IS_PURCHASED)
        UserDefaults.standard.set(expireDate, forKey: EXPIRE_DATE)
        UserDefaults.standard.set(productId, forKey: PRODUCT_ID)
    }

    @objc public func completeTransactions() {
        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
                    self.updateSubscriptionStatus()
                case .failed, .purchasing, .deferred:
                    break // do nothing
                @unknown default:
                    break
                }
            }
        }
    }
    
    @objc public func updateSubscriptionStatus() {
        if UserDefaults.standard.bool(forKey: IS_PURCHASED) == false {
            return
        }
        self.verifyReceipt { result in
            switch result {
            case .success(let receipt):
                let receipts = receipt["latest_receipt_info"]
                if let dict = receipts?.lastObject as? [String: Any], let prodictId = dict["product_id"] as? String {
                    let productIds = Set([prodictId].map { $0 })
                    let purchaseResult = SwiftyStoreKit.verifySubscriptions(productIds: productIds, inReceipt: receipt)
                    switch purchaseResult {
                    case .purchased(let expiryDate, _):
                        self.setPurchased(productId: productIds[productIds.startIndex], purchased: true, expireDate: expiryDate)
                    case .expired(let expiryDate, _):
                        self.setPurchased(productId: productIds[productIds.startIndex], purchased: false, expireDate: expiryDate)
                        break
                    case .notPurchased:
                        break
                    }
                }
                break
            case .error:
                print("error on verification")
                break
            }
        }
    }
    
    @objc public func purchase(productId: String) {
        SwiftyStoreKit.purchaseProduct(productId, atomically: true) { result in
            SVProgressHUD.dismiss()
            if case .success(let purchase) = result {
                print(purchase.productId)
                if purchase.productId == IAPManagerProMonthlyId || purchase.productId == IAPManagerProWeeklylyId || purchase.productId == IAPManagerProQuarterlyId || purchase.productId == IAPManagerProYearlyId {
                    self.setPurchased(productId: purchase.productId, purchased: true, expireDate: Date().addingTimeInterval(10 * 60))
                }
                NotificationCenter.default.post(name: NSNotification.Name("ProductPurchased"), object: nil, userInfo: nil)
                let downloads = purchase.transaction.downloads
                if !downloads.isEmpty {
                    SwiftyStoreKit.start(downloads)
                }
                // Deliver content from server, then:
                if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
                
                self.verifySubscriptions([productId], completion: {result in
                    
                })
            } else {
                NotificationCenter.default.post(name: NSNotification.Name("ProductPurchaseFailed"), object: nil, userInfo: nil)
            }
            if let alert = self.alertForPurchaseResult(result) {
                self.showAlert(alert)
            }
        }
    }
    
    @objc public func restore() {
        SwiftyStoreKit.restorePurchases(atomically: true) { results in
            SVProgressHUD.dismiss()
            var products: Set<String> = []
            for purchase in results.restoredPurchases {
                if purchase.productId == IAPManagerProMonthlyId || purchase.productId == IAPManagerProWeeklylyId || purchase.productId == IAPManagerProQuarterlyId || purchase.productId == IAPManagerProYearlyId {
                    self.setPurchased(productId: purchase.productId, purchased: true, expireDate: Date().addingTimeInterval(10 * 60))
                } else {
                    UserDefaults.standard.set(true, forKey: purchase.productId)
                }
                products.insert(purchase.productId)
                let downloads = purchase.transaction.downloads
                if !downloads.isEmpty {
                    SwiftyStoreKit.start(downloads)
                } else if purchase.needsFinishTransaction {
                    SwiftyStoreKit.finishTransaction(purchase.transaction)
                }
            }
            if products.count > 0 {
                NotificationCenter.default.post(name: NSNotification.Name("ProductPurchased"), object: nil, userInfo: nil)
                self.verifySubscriptions(products, completion: { (completed) in
                    
                })
            } else {
                self.showAlert(self.alertForRestorePurchases(results))
                NotificationCenter.default.post(name: NSNotification.Name("ProductPurchaseFailed"), object: nil, userInfo: nil)
            }
        }
    }
    
    func verifyReceipt(completion: @escaping (VerifyReceiptResult) -> Void) {
        
        let appleValidator = AppleReceiptValidator(service: .production, sharedSecret: "695e2697a30941d4bca2605ed57525f3")
        SwiftyStoreKit.verifyReceipt(using: appleValidator, completion: completion)
    }
    
    func verifySubscriptions(_ purchases: Set<String>, completion: @escaping (Bool) -> Void) {
        if UserDefaults.standard.bool(forKey: IS_PURCHASED) == false {
            return
        }
        verifyReceipt { result in
            switch result {
            case .success(let receipt):
                let productIds = Set(purchases.map { $0 })
                let purchaseResult = SwiftyStoreKit.verifySubscriptions(productIds: productIds, inReceipt: receipt)
                switch purchaseResult {
                case .purchased(let expiryDate, _):
                    self.setPurchased(productId: productIds[productIds.startIndex], purchased: true, expireDate: expiryDate)
                    completion(true)
                case .expired(let expiryDate, _):
                    self.setPurchased(productId: productIds[productIds.startIndex], purchased: false, expireDate: expiryDate)
                    completion(false)
                    break
                case .notPurchased:
                    completion(false)
                    break
                }
                //self.showAlert(self.alertForVerifySubscriptions(purchaseResult, productIds: productIds))
                break
            case .error:
                completion(false)
                //self.showAlert(self.alertForVerifyReceipt(result))
                break
            }
        }
    }
    
    @objc public func retrievePrices(productIds: Set<String>, completion: @escaping ([String : String]) -> Void) {
        var products: [String : String] = [:]
        SwiftyStoreKit.retrieveProductsInfo(productIds) {[weak self] (results) in
            for result in results.retrievedProducts {
                print("Locale: \(result.priceLocale)")
                self?.priceLocal = result.priceLocale
                products[result.productIdentifier] = result.localizedPrice!
            }
            PurchaseManager.sharedManager.products = results.retrievedProducts
            print("Error: \(String(describing: results.error))")
            PurchaseManager.sharedManager.prices = products
            completion(products)
        }
    }
    
    func alertForPurchaseResult(_ result: PurchaseResult) -> UIAlertController? {
        switch result {
        case .success(let purchase):
            print("Purchase Success: \(purchase.productId)")
            return alertWithTitle("Purchase Success, Thanks", message: "")
        case .error(let error):
            print("Purchase Failed: \(error)")
            switch error.code {
            case .unknown: return alertWithTitle("Purchase failed", message: "There is a problem connecting to the App Store, please try again")
            case .clientInvalid: // client is not allowed to issue the request, etc.
                return alertWithTitle("Purchase failed", message: "Not allowed to make the payment")
            case .paymentCancelled: // user cancelled the request, etc.
                return nil
            case .paymentInvalid: // purchase identifier was invalid, etc.
                return alertWithTitle("Purchase failed", message: "The purchase identifier was invalid")
            case .paymentNotAllowed: // this device is not allowed to make the payment
                return alertWithTitle("Purchase failed", message: "The device is not allowed to make the payment")
            case .storeProductNotAvailable: // Product is not available in the current storefront
                return alertWithTitle("Purchase failed", message: "The product is not available in the current storefront")
            case .cloudServicePermissionDenied: // user has not allowed access to cloud service information
                return alertWithTitle("Purchase failed", message: "Access to cloud service information is not allowed")
            case .cloudServiceNetworkConnectionFailed: // the device could not connect to the nework
                return alertWithTitle("Purchase failed", message: "Could not connect to the network")
            case .cloudServiceRevoked: // user has revoked permission to use this cloud service
                return alertWithTitle("Purchase failed", message: "Cloud service was revoked")
            default:
                return alertWithTitle("Purchase failed", message: "Unknown error was occurred")
            }
        }
    }
    
    func alertForRestorePurchases(_ results: RestoreResults) -> UIAlertController {
        
        if results.restoreFailedPurchases.count > 0 {
            print("Restore Failed: \(results.restoreFailedPurchases)")
            return alertWithTitle("Restore failed", message: "Unknown error. Please contact support")
        } else if results.restoredPurchases.count > 0 {
            print("Restore Success: \(results.restoredPurchases)")
            return alertWithTitle("Purchases Restored", message: "All purchases have been restored")
        } else {
            print("Nothing to Restore")
            return alertWithTitle("Nothing to restore", message: "No previous purchases were found")
        }
    }
    
    func alertForVerifySubscriptions(_ result: VerifySubscriptionResult, productIds: Set<String>) -> UIAlertController {
        
        switch result {
        case .purchased(let expiryDate, let items):
            print("\(productIds) is valid until \(expiryDate)\n\(items)\n")
            return alertWithTitle("Product is purchased", message: "Product is valid until \(expiryDate)")
        case .expired(let expiryDate, let items):
            print("\(productIds) is expired since \(expiryDate)\n\(items)\n")
            return alertWithTitle("Product expired", message: "Product is expired since \(expiryDate)")
        case .notPurchased:
            print("\(productIds) has never been purchased")
            return alertWithTitle("Not purchased", message: "This product has never been purchased")
        }
    }
    
    func alertForVerifyPurchase(_ result: VerifyPurchaseResult, productId: String) -> UIAlertController {
        
        switch result {
        case .purchased:
            print("\(productId) is purchased")
            return alertWithTitle("Product is purchased", message: "Product will not expire")
        case .notPurchased:
            print("\(productId) has never been purchased")
            return alertWithTitle("Not purchased", message: "This product has never been purchased")
        }
    }
    
    func alertForVerifyReceipt(_ result: VerifyReceiptResult) -> UIAlertController {
        
        switch result {
        case .success(let receipt):
            print("Verify receipt Success: \(receipt)")
            return alertWithTitle("Receipt verified", message: "Receipt verified remotely")
        case .error(let error):
            print("Verify receipt Failed: \(error)")
            switch error {
            case .noReceiptData:
                return alertWithTitle("Receipt verification", message: "No receipt data. Try again.")
            case .networkError:
                return alertWithTitle("Receipt verification", message: "Network error while verifying receipt: There is a problem connecting to the App Store, please try again")
            default:
                return alertWithTitle("Receipt verification", message: "Receipt verification failed: There is a problem connecting to the App Store, please try again")
            }
        }
    }
    
    func showAlert(_ alert: UIAlertController) {
        if let viewController = topViewController {
            DispatchQueue.main.async {
                viewController.present(alert, animated: true, completion: nil)
            }
        }
    }
    var topViewController: UIViewController? {
        return UIApplication.topViewController()
    }
    
    func alertWithTitle(_ title: String, message: String) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: {_ in
            NotificationCenter.default.post(name: NSNotification.Name("alertDidClose"), object: nil, userInfo: nil)
        }))
        return alert
    }
}
extension UIApplication {
    class func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let navigationController = controller as? UINavigationController {
            return topViewController(controller: navigationController.visibleViewController)
        }
        if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        }
        if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
