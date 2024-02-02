import UIKit
import UnityAds

enum PlacementID: String {
    case banner = "BANNER_PLACEMENT"
    case interstitial = "INTERSTITIAL_PLACEMENT"
    case rewarded = "REWARDED_PLACEMENT"
    // ...
}

class UnityAdsManager: NSObject, UnityAdsInitializationDelegate, UnityAdsLoadDelegate, UnityAdsShowDelegate, UADSBannerViewDelegate {
    
    static let shared = UnityAdsManager()
    
    var loadedAds: Set<PlacementID> = []
    
    private let gameId = "UNITY_GAME_ID"
    private var adsEnabled = true
    private var bannerSize = CGSize(width: 320, height: 50)
    private var postAdShowCallback: (() -> Void)?

    // MARK: Banners

    private var bannerAdView: UADSBannerView?
    
    // MARK: Initialization
    
    func initializeUnityAds(withGameID gameID: String, testMode: Bool = false) {
        UnityAds.initialize(gameID, testMode: testMode, initializationDelegate: self)
    }
    
    // MARK: - UnityAdsInitializationDelegate methods
    
    func initializationComplete() {
        // Handle successful initialization
        Logger.log("Unity Ads init complete")
    }
    
    func initializationFailed(_ error: UnityAdsInitializationError, withMessage message: String) {
        // Handle initialization failure
        Logger.log("\(error): \(message)", level: .error)
    }

    func setUnityAdsConsent(userConsent: Bool) {
        let metaData = UADSMetaData()
        metaData.set("privacy.consent", value: userConsent)
        metaData.commit()
    }
    
    // MARK: - Load Ads
    
    private func load(placementId: PlacementID, loadDelegate: UnityAdsLoadDelegate?) {
        guard !loadedAds.contains(placementId) else { return }
        UnityAds.load(placementId.rawValue, loadDelegate: loadDelegate)
    }
    
    func preloadAds() {
        load(placementId: .banner, loadDelegate: self)
        load(placementId: .interstitial, loadDelegate: self)
        load(placementId: .rewarded, loadDelegate: self)
        // ...
    }
    
    // MARK: - Ad Removal
    
    func removeBannerAds() {
        DispatchQueue.main.async { [weak self] in
            self?.bannerAdView?.removeFromSuperview()
            self?.bannerAdView = nil
            // ...
        }
    }
        
    func removeAdsGlobally() {
        adsEnabled = false
        removeBannerAds()
    }
    
    // MARK: - Banner Ads
    
   func showBannerAd(from viewController: UIViewController, placementId: PlacementID) {
       
       // should a run a reachability check before performing work
       
       guard adsEnabled else { return }
       
       DispatchQueue.main.async {
           let banner = UADSBannerView(placementId: placementId.rawValue, size: self.bannerSize)
           banner.load()
           banner.translatesAutoresizingMaskIntoConstraints = false
           banner.delegate = self
           viewController.view.addSubview(banner)
           
           NSLayoutConstraint.activate([
               banner.bottomAnchor.constraint(equalTo: viewController.view.safeAreaLayoutGuide.bottomAnchor),
               banner.centerXAnchor.constraint(equalTo: viewController.view.centerXAnchor)
           ])
           
           if placementId == .mainMenuBanner {
               self.bannerAdView = banner
           }
           // ...
       }
       
       Logger.log("showing banner ad")
   }
    
    // MARK: - Show Rewarded or Interstitial Ads
    
    func showAd(from viewController: UIViewController, placementId: PlacementID, completion: (() -> Void)? = nil) {
        
        // should a run a reachability check before performing work
        
        guard adsEnabled else { return }
        
        self.postAdShowCallback = completion

        DispatchQueue.main.async {
            UnityAds.show(viewController, placementId: placementId.rawValue, showDelegate: self)
        }
    }

    // MARK: - UnityAdsLoadDelegate
    
    func unityAdsAdLoaded(_ placementId: String) {
        // Handle successful ad load
        Logger.log("Successfully loaded ad: \(placementId)")
        if let ad = PlacementID(rawValue: placementId) {
            loadedAds.insert(ad)
        }
    }
    
    func unityAdsAdFailed(toLoad placementId: String, withError error: UnityAdsLoadError, withMessage message: String) {
        // Handle ad load failure
        Logger.log("\(error): \(message)", level: .error)
    }

    // MARK: - UnityAdsShowDelegate
    
    func unityAdsShowStart(_ placementId: String) {
        // Handle ad show start
        Logger.log("Started ad show: \(placementId)")
    }
    
    func unityAdsShowClick(_ placementId: String) {
        // Handle ad click event
        Logger.log("Clicked ad show: \(placementId)")
    }
    
    func unityAdsShowComplete(_ placementId: String, withFinish state: UnityAdsShowCompletionState) {
        // Handle ad show completion
        Logger.log("Completed ad show: \(placementId)")
        
        if state == .showCompletionStateCompleted {
            NotificationCenter.default.post(name: NSNotification.Name("adShowComplete"), object: placementId)
        }
        
        // Execute the post-ad callback if set
        postAdShowCallback?()
        postAdShowCallback = nil
        
        if let ad = PlacementID(rawValue: placementId) {
            loadedAds.remove(ad)
        }

        UnityAds.load(placementId, loadDelegate: self)
    }
    
    func unityAdsShowFailed(_ placementId: String, withError error: UnityAdsShowError, withMessage message: String) {
        // Handle ad show failure
        Logger.log("\(error): \(message)", level: .error)
        if let ad = PlacementID(rawValue: placementId) {
            loadedAds.remove(ad)
        }
        UnityAds.load(placementId, loadDelegate: self)
    }
    
    // MARK: - UADSBannerViewDelegate
    
    func bannerViewDidLoad(_ bannerView: UADSBannerView!) {
        Logger.log("Banner did load: \(bannerView.placementId)")
    }
    
    func bannerViewDidShow(_ bannerView: UADSBannerView!) {
        Logger.log("Banner did show: \(bannerView.placementId)")
    }
    
    func bannerViewDidClick(_ bannerView: UADSBannerView!) {
        Logger.log("Clicked banner ad: \(bannerView.placementId)")
    }
    
    func bannerViewDidError(_ bannerView: UADSBannerView!, error: UADSBannerError!) {
        Logger.log("Error: \(error.debugDescription)", level: .error)
    }
}
