import Foundation
import CoreBluetooth
import Combine
import os.log

class BluetoothManager: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var availableKeyboards: [ZMKKeyboard] = []
    @Published var selectedKeyboard: ZMKKeyboard?
    @Published var isScanning: Bool = false
    @Published var bluetoothState: CBManagerState = .unknown
    @Published var connectionState: ConnectionState = .disconnected

    // MARK: - Private Properties

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var discoveredPeripherals: [UUID: CBPeripheral] = [:]
    private var batteryCharacteristics: [CBCharacteristic] = []
    private var pendingCharacteristicReads: Int = 0

    private var scanTimer: Timer?
    private var pollingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    private let logger = Logger(subsystem: AppInfo.bundleIdentifier, category: "Bluetooth")


    // MARK: - Reconnection

    private var reconnectAttempt: Int = 0
    private var reconnectTimer: Timer?
    private var isReconnecting: Bool = false

    // MARK: - Initialization

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)

        // Listen for system wake to trigger reconnection
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSystemWake),
            name: .systemDidWake,
            object: nil
        )

        // Watch for polling interval changes
        PreferencesManager.shared.$settings
            .map(\.pollingInterval)
            .removeDuplicates()
            .dropFirst() // Skip initial value
            .sink { [weak self] newInterval in
                guard let self = self, self.connectionState.isConnected else { return }
                self.logger.info("Polling interval changed to \(newInterval)s, restarting timer")
                self.startPolling(interval: newInterval)
            }
            .store(in: &cancellables)

        // Load saved keyboard on init
        loadSavedKeyboard()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopPolling()
        stopScanning()
    }

    // MARK: - Public Methods

    func startScanning() {
        let btState = centralManager.state
        guard btState == .poweredOn else {
            logger.warning("Cannot scan: Bluetooth not powered on (state: \(btState.rawValue))")
            connectionState = .failed("Bluetooth not available")
            return
        }

        guard !isScanning else { return }

        logger.info("Retrieving connected devices with Battery Service...")
        isScanning = true
        connectionState = .searching
        availableKeyboards.removeAll()
        discoveredPeripherals.removeAll()

        // Get already-connected devices with Battery Service (like Mighty Mitts does)
        // This finds devices already paired/connected to macOS - no scanning needed
        let connectedPeripherals = centralManager.retrieveConnectedPeripherals(withServices: [BLEConstants.batteryServiceUUID])
        logger.info("Found \(connectedPeripherals.count) connected device(s) with Battery Service")

        for peripheral in connectedPeripherals {
            if let name = peripheral.name, !name.isEmpty {
                logger.info("Found: \(name)")
                discoveredPeripherals[peripheral.identifier] = peripheral

                let keyboard = ZMKKeyboard(
                    name: name,
                    peripheralIdentifier: peripheral.identifier
                )
                availableKeyboards.append(keyboard)
            } else {
                logger.debug("Skipping unnamed device: \(peripheral.identifier)")
            }
        }

        // Done immediately - no actual scanning needed
        isScanning = false
        connectionState = .disconnected
    }

    func stopScanning() {
        guard isScanning else { return }

        logger.info("Stopping BLE scan")
        centralManager.stopScan()
        isScanning = false
        scanTimer?.invalidate()
        scanTimer = nil

        if connectionState == .searching {
            connectionState = .disconnected
        }
    }

    func connect(to keyboard: ZMKKeyboard) {
        guard let peripheral = discoveredPeripherals[keyboard.peripheralIdentifier] else {
            logger.error("Cannot connect: peripheral not found for \(keyboard.name)")
            return
        }

        stopScanning()
        logger.info("Connecting to \(keyboard.name)")
        connectionState = .connecting
        selectedKeyboard = keyboard
        centralManager.connect(peripheral, options: nil)
    }

    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }

        logger.info("Disconnecting from \(peripheral.name ?? "Unknown")")
        centralManager.cancelPeripheralConnection(peripheral)
        stopPolling()
        stopReconnecting()
    }

    func reconnect() {
        guard let keyboard = selectedKeyboard else {
            logger.warning("No keyboard selected for reconnection")
            return
        }

        // Try to reconnect using known peripheral identifier
        let knownPeripherals = centralManager.retrievePeripherals(withIdentifiers: [keyboard.peripheralIdentifier])

        if let peripheral = knownPeripherals.first {
            logger.info("Found known peripheral, attempting reconnection")
            discoveredPeripherals[keyboard.peripheralIdentifier] = peripheral
            connectionState = .connecting
            centralManager.connect(peripheral, options: nil)
        } else {
            logger.info("Peripheral not found, scanning...")
            startScanning()
        }
    }

    func refreshBatteryLevels() {
        guard let peripheral = connectedPeripheral else {
            logger.warning("Cannot refresh: no connected peripheral")
            return
        }

        for characteristic in batteryCharacteristics {
            peripheral.readValue(for: characteristic)
        }
    }

    func selectKeyboard(_ keyboard: ZMKKeyboard) {
        selectedKeyboard = keyboard
        saveSelectedKeyboard()
        connect(to: keyboard)
    }

    // MARK: - Polling

    func startPolling(interval: TimeInterval) {
        stopPolling()

        pollingTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refreshBatteryLevels()
        }

        logger.info("Started polling every \(interval) seconds")
    }

    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }

    // MARK: - Auto-Reconnect

    func startAutoReconnect() {
        let settings = PreferencesManager.shared.settings

        guard settings.autoReconnect else {
            logger.info("Auto-reconnect disabled")
            return
        }

        guard reconnectAttempt < settings.maxReconnectAttempts else {
            logger.error("Max reconnection attempts (\(settings.maxReconnectAttempts)) reached")
            connectionState = .failed("Max attempts reached")
            stopReconnecting()
            return
        }

        isReconnecting = true
        reconnectAttempt += 1

        let delay = calculateBackoffDelay()
        let currentAttempt = reconnectAttempt
        connectionState = .reconnecting(attempt: reconnectAttempt, maxAttempts: settings.maxReconnectAttempts)

        logger.info("Scheduling reconnect attempt \(currentAttempt) in \(delay)s")

        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            self?.reconnect()
        }
    }

    func stopReconnecting() {
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        reconnectAttempt = 0
        isReconnecting = false
    }

    private func calculateBackoffDelay() -> TimeInterval {
        let exponentialDelay = AppConstants.reconnectBaseDelay * pow(2.0, Double(reconnectAttempt - 1))
        return min(exponentialDelay, AppConstants.reconnectMaxDelay)
    }

    // MARK: - Persistence

    private func loadSavedKeyboard() {
        if let keyboard = PreferencesManager.shared.loadLastSelectedKeyboard() {
            selectedKeyboard = keyboard
            logger.info("Loaded saved keyboard: \(keyboard.name)")
        }
    }

    private func saveSelectedKeyboard() {
        guard let keyboard = selectedKeyboard else { return }
        PreferencesManager.shared.saveKeyboard(keyboard)
    }

    // MARK: - System Events

    @objc private func handleSystemWake() {
        logger.info("System woke from sleep")

        if selectedKeyboard != nil && !connectionState.isConnected {
            // Give Bluetooth a moment to initialize after wake
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                self?.startAutoReconnect()
            }
        }
    }

}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state

        switch central.state {
        case .poweredOn:
            logger.info("Bluetooth powered on")
            // Auto-connect to saved keyboard if available
            if selectedKeyboard != nil && !connectionState.isConnected {
                reconnect()
            }
        case .poweredOff:
            logger.warning("Bluetooth powered off")
            connectionState = .disconnected
        case .unauthorized:
            logger.error("Bluetooth unauthorized")
            connectionState = .failed("Bluetooth access denied")
        case .unsupported:
            logger.error("Bluetooth unsupported")
            connectionState = .failed("Bluetooth not supported")
        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Only show devices with names (filter out unnamed BLE devices)
        guard let name = peripheral.name, !name.isEmpty else {
            return
        }

        logger.info("Discovered: \(name) (RSSI: \(RSSI), ID: \(peripheral.identifier.uuidString.prefix(8)))")

        discoveredPeripherals[peripheral.identifier] = peripheral

        // Check if this is our saved keyboard
        if let saved = selectedKeyboard, peripheral.identifier == saved.peripheralIdentifier {
            logger.info("Found saved keyboard, connecting...")
            stopScanning()
            connectionState = .connecting
            centralManager.connect(peripheral, options: nil)
            return
        }

        // Add to available keyboards if not already present
        if !availableKeyboards.contains(where: { $0.peripheralIdentifier == peripheral.identifier }) {
            let keyboard = ZMKKeyboard(
                name: name,
                peripheralIdentifier: peripheral.identifier
            )
            DispatchQueue.main.async {
                self.availableKeyboards.append(keyboard)
                self.logger.info("Added keyboard to list: \(name)")
            }
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Connected to \(peripheral.name ?? "Unknown")")

        connectedPeripheral = peripheral
        peripheral.delegate = self
        connectionState = .connected
        stopReconnecting()

        // Update selected keyboard state - must reassign entire struct since it's a value type
        if var keyboard = selectedKeyboard {
            keyboard.isConnected = true
            keyboard.lastSeen = Date()
            selectedKeyboard = keyboard
        }
        saveSelectedKeyboard()

        // Discover ALL services first - ZMK may have multiple Battery Services (one per half)
        peripheral.discoverServices(nil)

        // Start polling
        let interval = PreferencesManager.shared.settings.pollingInterval
        startPolling(interval: interval)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let errorMsg = error?.localizedDescription ?? "Unknown error"
        logger.error("Failed to connect: \(errorMsg)")

        connectionState = .disconnected
        startAutoReconnect()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.warning("Disconnected from \(peripheral.name ?? "Unknown"): \(error?.localizedDescription ?? "User initiated")")

        connectedPeripheral = nil
        batteryCharacteristics.removeAll()
        connectionState = .disconnected
        stopPolling()

        // Update keyboard state - must reassign entire struct since it's a value type
        if var keyboard = selectedKeyboard {
            keyboard.isConnected = false
            selectedKeyboard = keyboard
        }
        saveSelectedKeyboard()

        // Auto-reconnect if unexpected disconnect
        if error != nil {
            startAutoReconnect()
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            logger.error("Service discovery error: \(error.localizedDescription)")
            return
        }

        guard let services = peripheral.services else { return }

        // Clear previous characteristics when rediscovering
        batteryCharacteristics.removeAll()

        // Log all services found
        logger.info("Found \(services.count) service(s)")
        var batteryServiceCount = 0
        for service in services {
            logger.info("  Service: \(service.uuid.uuidString)")
            if service.uuid == BLEConstants.batteryServiceUUID {
                batteryServiceCount += 1
                logger.info("  -> This is a Battery Service (#\(batteryServiceCount))")
                peripheral.discoverCharacteristics(nil, for: service)  // Discover ALL characteristics
            }
        }
        logger.info("Total Battery Services found: \(batteryServiceCount)")
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            logger.error("Characteristic discovery error: \(error.localizedDescription)")
            return
        }

        guard let characteristics = service.characteristics else { return }

        logger.info("Service \(service.uuid.uuidString) has \(characteristics.count) characteristic(s):")
        for char in characteristics {
            logger.info("  - \(char.uuid.uuidString)")
        }

        // Find battery level characteristics in this service and APPEND to our array
        let batteryChars = characteristics.filter { $0.uuid == BLEConstants.batteryLevelCharacteristicUUID }
        batteryCharacteristics.append(contentsOf: batteryChars)

        let totalCount = batteryCharacteristics.count
        logger.info("Total battery characteristics so far: \(totalCount)")

        // Read the newly discovered characteristics
        for characteristic in batteryChars {
            peripheral.readValue(for: characteristic)
        }

        // Log if we have both halves now
        if totalCount >= 2 {
            logger.info("Split keyboard ready - have \(totalCount) battery readings")
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.error("Read error: \(error.localizedDescription)")
            return
        }

        guard characteristic.uuid == BLEConstants.batteryLevelCharacteristicUUID,
              let data = characteristic.value,
              !data.isEmpty else {
            return
        }

        let percentage = min(max(Int(data[0]), 0), 100)
        let batteryLevel = BatteryLevel(percentage: percentage, timestamp: Date())

        // Identify which half by finding this characteristic in our stored array
        // Index 0 = left, Index 1 = right
        guard let index = batteryCharacteristics.firstIndex(where: { $0 === characteristic }) else {
            logger.warning("Received reading from unknown characteristic")
            return
        }

        let half: KeyboardHalf = index == 0 ? .left : .right
        logger.info("\(half.rawValue) battery: \(percentage)%")

        // Update the appropriate half - must reassign entire struct since it's a value type
        if var keyboard = selectedKeyboard {
            switch half {
            case .left:
                keyboard.leftBattery = batteryLevel
            case .right:
                keyboard.rightBattery = batteryLevel
            }
            selectedKeyboard = keyboard  // Reassign to trigger @Published update
        }

        // Check for low battery notifications
        checkBatteryThresholds(percentage: percentage, half: half)
    }

    private func checkBatteryThresholds(percentage: Int, half: KeyboardHalf) {
        let settings = PreferencesManager.shared.settings

        guard settings.enableNotifications else { return }
        guard let keyboard = selectedKeyboard else { return }

        if percentage <= settings.criticalBatteryThreshold {
            NotificationManager.shared.sendCriticalBatteryAlert(
                keyboard: keyboard,
                half: half,
                percentage: percentage
            )
        } else if percentage <= settings.lowBatteryThreshold {
            NotificationManager.shared.sendLowBatteryAlert(
                keyboard: keyboard,
                half: half,
                percentage: percentage
            )
        }
    }
}
