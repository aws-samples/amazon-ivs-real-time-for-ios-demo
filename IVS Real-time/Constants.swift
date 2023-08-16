//
//  Constants.swift
//  IVS Real-time
//
//  Created by Uldis Zingis on 28/03/2023.
//

import SwiftUI

struct Constants {
    static let sdk_version = "1.8.1"
    static let API_URL = "cloudfront.net"

    // App fonts
    static let fRobotoMonoBold = Font.custom("RobotoMono-Bold", size: 16)
    static let fRobotoMonoBold18 = Font.custom("RobotoMono-Bold", size: 18)
    static let fRobotoMonoMedium18 = Font.custom("RobotoMono-Medium", size: 18)
    static let fInterMedium14 = Font.custom("Inter-Medium", size: 14)
    static let fInterBlack36 = Font.custom("Inter-Black", size: 36)
    static let fInterBlack42 = Font.custom("Inter-Black", size: 42)
    static let fInterBold14 = Font.custom("Inter-Bold", size: 14)
    static let fInterBold15 = Font.custom("Inter-Bold", size: 15)
    static let fInterBold18 = Font.custom("Inter-Bold", size: 18)
    static let fInterBold22 = Font.custom("Inter-Bold", size: 22)
    static let fInterRegular14 = Font.custom("Inter-Regular", size: 14)
    static let fInterRegular15 = Font.custom("Inter-Regular", size: 15)
    static let fInterRegular17 = Font.custom("Inter-Regular", size: 17)
    static let fInterExtraBold18 = Font.custom("Inter-ExtraBold", size: 18)
    static let fInterExtraBold22 = Font.custom("Inter-ExtraBold", size: 22)
    static let fInterSemiBold14 = Font.custom("Inter-SemiBold", size: 14)
    static let fInterSemiBold16 = Font.custom("Inter-SemiBold", size: 16)

    // Keys
    static let kCustomerCode = "k_customer_code"
    static let kApiKey = "k_api_key"
    static let kMaxBitrate = "k_max_bitrate"
    static let kIsSimulcastOn = "k_is_simulcast_on"
}
