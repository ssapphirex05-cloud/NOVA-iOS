import UIKit
import WebKit
import UniformTypeIdentifiers

final class NovaViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler, WKDownloadDelegate {
    private let novaURL = URL(string: "https://246830.9yy8ob5y94yx.mjtest.ru/nova_messenger_v1/")!
    private var webView: WKWebView!
    private var progress: UIProgressView!
    private var observation: NSKeyValueObservation?

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 6/255, green: 17/255, blue: 28/255, alpha: 1)
        configureWebView()
        configureProgress()
        NotificationCenter.default.addObserver(self, selector: #selector(handlePushOpen(_:)), name: .novaPushOpened, object: nil)
        loadNova()
    }

    deinit {
        observation?.invalidate()
        NotificationCenter.default.removeObserver(self)
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: "novaBridge")
    }

    private func configureWebView() {
        let content = WKUserContentController()
        content.add(self, name: "novaBridge")
        content.addUserScript(WKUserScript(source: Self.bridgeScript,
                                           injectionTime: .atDocumentEnd,
                                           forMainFrameOnly: true))

        let config = WKWebViewConfiguration()
        config.websiteDataStore = .default()
        config.userContentController = content
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = view.backgroundColor
        webView.isOpaque = false
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.customUserAgent = "NOVA-iOS/" + (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.1")

        view.addSubview(webView)
        let safe = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: safe.topAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: safe.bottomAnchor)
        ])
    }

    private func configureProgress() {
        progress = UIProgressView(progressViewStyle: .bar)
        progress.translatesAutoresizingMaskIntoConstraints = false
        progress.tintColor = UIColor(red: 0.15, green: 0.70, blue: 1.0, alpha: 1)
        view.addSubview(progress)
        NSLayoutConstraint.activate([
            progress.topAnchor.constraint(equalTo: webView.topAnchor),
            progress.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        observation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] web, _ in
            guard let self else { return }
            self.progress.progress = Float(web.estimatedProgress)
            self.progress.isHidden = web.estimatedProgress >= 1
        }
    }

    private func loadNova(_ url: URL? = nil) {
        webView.load(URLRequest(url: url ?? novaURL,
                                cachePolicy: .useProtocolCachePolicy,
                                timeoutInterval: 20))
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progress.isHidden = true
    }

    func webView(_ webView: WKWebView,
                 decidePolicyFor navigationAction: WKNavigationAction,
                 decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else { decisionHandler(.cancel); return }
        if url.host == novaURL.host || url.scheme == "about" || url.scheme == "blob" {
            decisionHandler(.allow)
        } else if ["http", "https", "mailto", "tel"].contains(url.scheme?.lowercased() ?? "") {
            UIApplication.shared.open(url)
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }

    @available(iOS 15.0, *)
    func webView(_ webView: WKWebView,
                 requestMediaCapturePermissionFor origin: WKSecurityOrigin,
                 initiatedByFrame frame: WKFrameInfo,
                 type: WKMediaCaptureType,
                 decisionHandler: @escaping (WKPermissionDecision) -> Void) {
        if origin.host == novaURL.host { decisionHandler(.grant) }
        else { decisionHandler(.deny) }
    }

    func webView(_ webView: WKWebView,
                 navigationResponse: WKNavigationResponse,
                 didBecome download: WKDownload) {
        download.delegate = self
    }

    func webView(_ webView: WKWebView,
                 navigationAction: WKNavigationAction,
                 didBecome download: WKDownload) {
        download.delegate = self
    }

    func download(_ download: WKDownload,
                  decideDestinationUsing response: URLResponse,
                  suggestedFilename: String,
                  completionHandler: @escaping (URL?) -> Void) {
        let safeName = suggestedFilename.replacingOccurrences(of: "/", with: "-")
        let target = FileManager.default.temporaryDirectory.appendingPathComponent(safeName)
        try? FileManager.default.removeItem(at: target)
        completionHandler(target)
    }

    func downloadDidFinish(_ download: WKDownload) {
        // The temporary file can be exported through the system share sheet in a later UI iteration.
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "novaBridge",
              let body = message.body as? [String: Any],
              let type = body["type"] as? String,
              type == "session" else { return }
        let token = body["token"] as? String ?? ""
        let enabled = body["notifications"] as? Bool ?? false
        NovaPushManager.shared.updateSession(authToken: token, enabled: enabled)
    }

    @objc private func handlePushOpen(_ note: Notification) {
        let info = note.userInfo ?? [:]
        let kind = info["kind"] as? String ?? ""
        let rawCID = info["conversationId"] as? String ?? "0"
        let cid = Int(rawCID) ?? 0

        var components = URLComponents(url: novaURL, resolvingAgainstBaseURL: false)
        if kind == "contact-request" {
            components?.queryItems = [URLQueryItem(name: "novaOpen", value: "contacts")]
        } else if cid > 0 {
            components?.queryItems = [
                URLQueryItem(name: "novaOpen", value: "chat"),
                URLQueryItem(name: "cid", value: String(cid))
            ]
        } else { return }
        if let target = components?.url { loadNova(target) }
    }

    private static let bridgeScript = #"""
    (function(){
      document.documentElement.classList.add('nova-ios-app');
      document.documentElement.style.setProperty('--nova-native-app','1');
      if(window.__novaIOSBridgeWatch)return;
      window.__novaIOSBridgeWatch=1;
      let lastToken=''; let lastEnabled=null;
      function sync(){
        try{
          const token=localStorage.getItem('nova_token')||'';
          const enabled=(localStorage.getItem('nova_notifications')==='1');
          if(token!==lastToken||enabled!==lastEnabled){
            window.webkit.messageHandlers.novaBridge.postMessage({type:'session',token:token,notifications:enabled});
            lastToken=token; lastEnabled=enabled;
          }
        }catch(e){}
      }
      sync(); setInterval(sync,1200);
    })();
    """#
}
