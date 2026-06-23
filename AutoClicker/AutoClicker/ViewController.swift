import UIKit

class ViewController: UIViewController {

    private let statusLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private var isRunning = false
    private var clickTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "自动点击器"

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.text = "状态: 已停止"
        statusLabel.font = .systemFont(ofSize: 18, weight: .medium)
        statusLabel.textColor = .systemOrange
        statusLabel.textAlignment = .center
        view.addSubview(statusLabel)

        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("开始自动点击", for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        startButton.backgroundColor = .systemBlue
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 10
        startButton.addTarget(self, action: #selector(startClicked), for: .touchUpInside)
        view.addSubview(startButton)

        stopButton.translatesAutoresizingMaskIntoConstraints = false
        stopButton.setTitle("停止点击", for: .normal)
        stopButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        stopButton.backgroundColor = .systemRed
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 10
        stopButton.addTarget(self, action: #selector(stopClicked), for: .touchUpInside)
        stopButton.isEnabled = false
        view.addSubview(stopButton)

        let tipLabel = UILabel()
        tipLabel.translatesAutoresizingMaskIntoConstraints = false
        tipLabel.text = "使用说明:\n安装后请先点击开始按钮\nAPP将模拟随机位置的触摸点击事件"
        tipLabel.font = .systemFont(ofSize: 14)
        tipLabel.textColor = .secondaryLabel
        tipLabel.textAlignment = .center
        tipLabel.numberOfLines = 0
        view.addSubview(tipLabel)

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

            tipLabel.topAnchor.constraint(equalTo: stopButton.bottomAnchor, constant: 40),
            tipLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            tipLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
        ])
    }

    @objc private func startClicked() {
        isRunning = true
        startButton.isEnabled = false
        stopButton.isEnabled = true
        statusLabel.text = "状态: 正在运行"
        statusLabel.textColor = .systemGreen

        clickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.performAutoClick()
        }
    }

    @objc private func stopClicked() {
        isRunning = false
        startButton.isEnabled = true
        stopButton.isEnabled = false
        statusLabel.text = "状态: 已停止"
        statusLabel.textColor = .systemOrange
        clickTimer?.invalidate()
        clickTimer = nil
    }

    private func performAutoClick() {
        let w = UIScreen.main.bounds.width
        let h = UIScreen.main.bounds.height
        let x = CGFloat.random(in: 50...(w - 50))
        let y = CGFloat.random(in: 100...(h - 100))

        HIDTouchInjector.tap(at: CGPoint(x: x, y: y))
    }
}

// MARK: - HID Touch Injection via IOKit private framework

struct HIDTouchInjector {

    static func tap(at point: CGPoint) {
        guard let iokitHandle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW) else {
            return
        }
        defer { dlclose(iokitHandle) }

        // IOHIDEventCreateDigitizerFingerEvent signature
        typealias CreateFingerEventFn = @convention(c) (
            _ allocator: CFAllocator?,
            _ timeStamp: UInt64,
            _ index: UInt32,
            _ identifier: UInt32,
            _ eventMask: UInt32,
            _ x: Double,
            _ y: Double,
            _ z: Double,
            _ tipPressure: Double,
            _ twist: Double,
            _ range: Bool,
            _ touch: Bool,
            _ options: UInt32
        ) -> UnsafeMutableRawPointer?

        typealias PostEventFn = @convention(c) (
            _ event: UnsafeMutableRawPointer,
            _ options: UInt32
        ) -> Void

        guard let createSym = dlsym(iokitHandle, "IOHIDEventCreateDigitizerFingerEvent"),
              let postSym = dlsym(iokitHandle, "IOHIDEventPost") else {
            return
        }

        let createFingerEvent = unsafeBitCast(createSym, to: CreateFingerEventFn.self)
        let postEvent = unsafeBitCast(postSym, to: PostEventFn.self)

        // kIOHIDDigitizerEventRange = 1<<0, kIOHIDDigitizerEventTouch = 1<<1
        let eventMask: UInt32 = (1 << 0) | (1 << 1)

        // Touch down
        let down = createFingerEvent(nil, mach_absolute_time(), 0, 2, eventMask, Double(point.x), Double(point.y), 0, 1.0, 0, false, true, 0)
        if let down = down {
            postEvent(down, 0)
        }

        // Small delay via usleep
        usleep(50000)

        // Touch up
        let up = createFingerEvent(nil, mach_absolute_time(), 0, 2, eventMask, Double(point.x), Double(point.y), 0, 0.0, 0, false, false, 0)
        if let up = up {
            postEvent(up, 0)
        }
    }
}
