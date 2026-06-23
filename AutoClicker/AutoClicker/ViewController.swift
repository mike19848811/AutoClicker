import UIKit
import Accessibility

class ViewController: UIViewController {
    
    private let statusLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private var isRunning = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkAccessibilityPermission()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        title = "自动点击器"
        
        // Setup status label
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "状态: 未运行"
        statusLabel.font = .systemFont(ofSize: 18, weight: .medium)
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)
        
        // Setup start button
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("开始自动点击", for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 10
        startButton.addTarget(self, action: #selector(startClicked), for: .touchUpInside)
        view.addSubview(startButton)
        
        // Setup stop button
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.setTitle("停止点击", for: .normal)
        stopButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        stopButton.backgroundColor = .systemRed
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 10
        stopButton.addTarget(self, action: #selector(stopClicked), for: .touchUpInside)
        stopButton.isEnabled = false
        view.addSubview(stopButton)
        
        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            startButton.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 40),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            startButton.heightAnchor.constraint(equalToConstant: 60),
            
            stopButton.topAnchor.constraint(equalTo: startButton.bottomAnchor, constant: 20),
            stopButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            stopButton.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    private func checkAccessibilityPermission() {
        let isEnabled = AXIsProcessTrusted()
        updateStatus(isEnabled: isEnabled)
    }
    
    private func updateStatus(isEnabled: Bool) {
        if !isEnabled {
            statusLabel.text = "状态: 需要辅助功能权限"
            statusLabel.textColor = .systemRed
        } else {
            statusLabel.text = isRunning ? "状态: 正在运行" : "状态: 已停止"
            statusLabel.textColor = isRunning ? .systemGreen : .systemOrange
        }
    }
    
    @objc private func startClicked() {
        guard AXIsProcessTrusted() else {
            promptForAccessibilityPermission()
            return
        }
        isRunning = true
        updateUI()
        startAutoClick()
    }
    
    @objc private func stopClicked() {
        isRunning = false
        updateUI()
    }
    
    private func updateUI() {
        startButton.isEnabled = !isRunning
        stopButton.isEnabled = isRunning
        updateStatus(isEnabled: AXIsProcessTrusted())
    }
    
    private func promptForAccessibilityPermission() {
        let alert = UIAlertController(
            title: "需要辅助功能权限",
            message: "请在设置 -> 隐私与安全性 -> 辅助功能中开启本应用的权限",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "确定", style: .default))
        present(alert, animated: true)
    }
    
    private func startAutoClick() {
        DispatchQueue.global(qos: .background).async { [weak self] in
            while self?.isRunning == true {
                self?.performRandomClick()
                Thread.sleep(forTimeInterval: 1.0) // 点击间隔，可以调整
            }
        }
    }
    
    private func performRandomClick() {
        // 获取屏幕尺寸
        let screenBounds = UIScreen.main.bounds
        let randomX = CGFloat.random(in: 50...(screenBounds.width - 50))
        let randomY = CGFloat.random(in: 100...(screenBounds.height - 100))
        let point = CGPoint(x: randomX, y: randomY)
        
        // 使用Accessibility执行点击
        let element = AXUIElementCopyElementAtPosition(
            AXUIElementCreateSystemWide(),
            Float(point.x),
            Float(point.y)
        )
        
        if let element = element.takeRetainedValue() {
            AXUIElementPerformAction(element, kAXPressAction as CFString)
        }
    }
}
