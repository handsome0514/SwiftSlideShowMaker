//
//  Constants.swift
//  SlideShow
//
//  Created by Hua Wan on 9/16/21.
//

import Foundation
import SwiftColor
import RealmSwift
import UIKit
import AVFoundation

let MAIN_ACTIVE_COLOR_1 = UIColor("#00F8F5")
let MAIN_ACTIVE_COLOR_2 = UIColor("#9077C3")
let MAIN_ACTIVE_COLOR_3 = UIColor("#D1C6E6")
let MAIN_ACTIVE_COLOR_4 = UIColor("#D7CEE9")
let MAIN_ACTIVE_COLOR_5 = UIColor("#7758B5").alpha(0.2)
let MAIN_ACTIVE_COLOR_6 = UIColor("#EEEAF6")

let APP_ARRAY_COLORS = [0xada52a, 0xfff68c, 0xf7c65e, 0xca722b, 0xff2c5b, 0xdb3d28, 0xb11a1a, 0xffffff, 0x000000, 0x888888, 0x4e369e, 0x4286f6, 0x77e7e8, 0x46ffd1, 0xb6fecb, 0xb7db71, 0x948f14, 0x4a2a3c]

let DEFAULT_IMAGE_DURATION: CGFloat = 4.0
let DEFAULT_EXPORT_DURATION: CGFloat = 15.0

let MAX_VIDEO_WIDTH: CGFloat = 1280
let MAX_VIDEO_HEIGHT: CGFloat = 1280

let ANIMATION_DURATION: CGFloat = 0.5

let schemaVersion: UInt64 = 7
public var sharedRealm: Realm = {
    let config = Realm.Configuration(schemaVersion: schemaVersion, migrationBlock: { (migration, oldSchemaVersion) in
        print(migration)
        print(oldSchemaVersion)
    }, deleteRealmIfMigrationNeeded: false)
    
    try? Realm.performMigration(for: config)
    var realm: Realm
    do {
        realm = try Realm(configuration: config)
    } catch {
        realm = try! Realm()
    }
    return realm
}()

var editViewCtrl: EditViewController?

let RATIO_ORIGINAL: Float = 1.333333334
let RATIO_PORTRAIT: Float = 0.5625
let RATIO_LANDSCAPE: Float = 1.777777778
let RATIO_SQUARE: Float = 1.0
