//
//  AppDelegate.swift
//  Nursing
//
//  Created by Andrey Chernyshev on 16.01.2021.
//

import UIKit
import RxCocoa
import Firebase
import RushSDK

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    lazy var sdkProvider = SDKProvider()
    
    private lazy var generateStepInSplash = PublishRelay<Bool>()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        
        NumberLaunches().launch()
        
        let vc = SplashViewController.make(generateStep: generateStepInSplash.asSignal())
        window?.rootViewController = vc
        window?.makeKeyAndVisible()
        
        FirebaseApp.configure()
        TestFinishObserver.shared.startObserve()
        
        addDelegates()
        
        runProvider(on: vc.view)
        
        sdkProvider.application(application, didFinishLaunchingWithOptions: launchOptions)
        SDKStorage.shared.pushNotificationsManager.application(didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        sdkProvider.application(app, open: url, options: options)
        
        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        sdkProvider.application(application, continue: userActivity, restorationHandler: restorationHandler)
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        sdkProvider.applicationDidBecomeActive(application)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        SDKStorage.shared.pushNotificationsManager.application(didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        SDKStorage.shared.pushNotificationsManager.application(didFailToRegisterForRemoteNotificationsWithError: error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        SDKStorage.shared.pushNotificationsManager.application(didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
    }
}

// MARK: SDKPurchaseMediatorDelegate
extension AppDelegate: SDKPurchaseMediatorDelegate {
    func purchaseMediatorDidValidateReceipt(response: ReceiptValidateResponse?) {
        guard let response = response else {
            return
        }
        
        let session = Session(response: response)
        
        SessionManager().store(session: session)
    }
}

// MARK: SDKUserManagerMediatorDelegate
extension AppDelegate: SDKUserManagerMediatorDelegate {
    func userManagerMediatorDidReceivedFeatureApp(userToken: String) {
        SessionManager().set(userToken: userToken)
    }
}

// MARK: Private
private extension AppDelegate {
    func runProvider(on view: UIView) {
        let session = SessionManager().getSession()
        
        let userId: String?
        if let cachedUserId = session?.userId {
            userId = String(cachedUserId)
        } else {
            userId = nil
        }
        
        let settings = SDKSettings(backendBaseUrl: GlobalDefinitions.sdkDomainUrl,
                                   backendApiKey: GlobalDefinitions.sdkApiKey,
                                   amplitudeApiKey: GlobalDefinitions.amplitudeApiKey,
                                   appsFlyerApiKey: GlobalDefinitions.appsFlyerApiKey,
                                   facebookActive: true,
                                   branchActive: true,
                                   firebaseActive: true,
                                   applicationTag: GlobalDefinitions.applicationTag,
                                   userToken: session?.userToken,
                                   userId: userId,
                                   view: view,
                                   shouldAddStorePayment: true,
                                   featureAppBackendUrl: GlobalDefinitions.domainUrl,
                                   featureAppBackendApiKey: GlobalDefinitions.apiKey,
                                   appleAppID: GlobalDefinitions.appleAppID)
        
        sdkProvider.initialize(settings: settings) { [weak self] success in
            self?.generateStepInSplash.accept(success)
        }
    }
    
    func addDelegates() {
        SDKStorage.shared.purchaseMediator.add(delegate: self)
        SDKStorage.shared.userManagerMediator.add(delegate: self)
    }
}